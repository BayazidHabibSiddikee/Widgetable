import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'package:widgetboard/core/models/note_entry.dart';

/// WebSocket / Socket.IO signaling service for WidgetBoard.
///
/// Supports both **online** (server-connected) and **offline** modes:
/// - In offline mode, all outgoing events (messages, notes, game actions) are
///   buffered to SharedPreferences and replayed once the server reconnects.
/// - The widget reads directly from SharedPreferences, so it always works offline.
class WebSocketService with ChangeNotifier {
  socket_io.Socket? _socket;
  String _username = 'guest';
  bool _isOnline = false;

  String get username => _username;
  bool get isConnected => _isOnline;
  String? currentRoom;

  /// Whether the user is running in pure-offline mode (no server configured).
  bool isOfflineMode = false;

  /// Stream of inbound real-time events.
  final _events = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onEvent => _events.stream;

  /// Inbound search results (username list).
  final _searchResults = StreamController<List<String>>.broadcast();
  Stream<List<String>> get onSearchResults => _searchResults.stream;

  /// Friends list (server pushes this when available).
  final _friends = <String>[];
  List<String> get friends => List<String>.unmodifiable(_friends);

  /// Active rooms for the user.
  final _rooms = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onRoom => _rooms.stream;

  Future<void> connect(String serverUrl) async {
    if (_socket != null) {
      try {
        _socket!.dispose();
      } catch (_) {}
    }
    _socket = socket_io.io(
      serverUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    _isOnline = false;
    _socket!.connect();
    _socket!.on('connect', (_) {
      _isOnline = true;
      _flushPending();
      notifyListeners();
    });
    _socket!.on('disconnect', (_) {
      _isOnline = false;
      notifyListeners();
    });
    _registerSocketHandlers();
  }

  void _registerSocketHandlers() {
    _socket!.on('search_results', _handleSearchResults);
    _socket!.on('friend_request', _forward);
    _socket!.on('room_created', _handleRoomCreated);
    _socket!.on('room_joined', _forward);
    _socket!.on('user_joined', _forward);
    _socket!.on('incoming_message', _forward);
    _socket!.on('widget_write', _onWidgetWrite);
    _socket!.on('friends_list', (data) {
      if (data is List) {
        _friends.clear();
        _friends.addAll(data.cast<String>());
        notifyListeners();
      }
    });
  }

  void _forward(dynamic data) => _events.add(data as Map<String, dynamic>);

  void _handleSearchResults(dynamic data) {
    if (data is List) {
      _searchResults.add(data.cast<String>());
    }
  }

  void _handleRoomCreated(dynamic data) {
    final m = data as Map<String, dynamic>;
    _rooms.add(m);
    _events.add(m);
  }

  Future<void> _onWidgetWrite(dynamic data) async {
    final map = data as Map<String, dynamic>;
    final sender = map['from'] as String? ?? 'friend';
    final body = map['body'] as String? ?? '';
    if (body.isEmpty) return;
    await _appendReceivedNote(sender, body);
  }

  /// Append an incoming note to SharedPreferences (works both online and offline).
  Future<void> _appendReceivedNote(String sender, String body) async {
    final entry = NoteEntry(
      sender: sender,
      body: body,
      timestamp: DateTime.now(),
    );
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('widget_notes_json') ?? '[]';
    final existing = NoteEntry.fromJsonList(raw);
    existing.insert(0, entry);
    if (existing.length > 10) existing.removeLast();
    await prefs.setString('widget_notes_json', NoteEntry.toJsonList(existing));
    await prefs.setString('last_note_ts', _formatTs(entry.timestamp));
    notifyListeners();
  }

  /// Flush queued offline messages/notes to the server once connected.
  Future<void> _flushPending() async {
    final prefs = await SharedPreferences.getInstance();
    // Flush pending messages
    final rawMsgs = prefs.getStringList('pending_messages') ?? [];
    for (final raw in rawMsgs) {
      try {
        final msg = jsonDecode(raw) as Map<String, dynamic>;
        sendMessage(msg['room'] as String, msg['text'] as String,
            mediaUrl: msg['media_url'] as String?);
      } catch (_) {}
    }
    if (rawMsgs.isNotEmpty) {
      await prefs.remove('pending_messages');
    }
    // Flush pending widget notes
    final rawNotes = prefs.getStringList('pending_notes') ?? [];
    for (final raw in rawNotes) {
      try {
        final note = jsonDecode(raw) as Map<String, dynamic>;
        sendWidgetNote(note['to'] as String, note['body'] as String);
      } catch (_) {}
    }
    if (rawNotes.isNotEmpty) {
      await prefs.remove('pending_notes');
    }
  }

  static String _formatTs(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $ampm';
  }

  void setUsername(String name) {
    _username = name;
    if (!isOfflineMode && _socket != null && _socket!.connected) {
      _socket!.emit('register', {'username': name});
    }
  }

  void searchUsers(String query) => _socket!.emit('search_users', {'query': query});

  void addFriend(String friendUsername) =>
      _socket!.emit('add_friend', {'to_username': friendUsername});

  Future<void> createOrJoinRoom(String gameId, String friendUsername) async {
    _socket!.emit('create_room', {'game': gameId, 'friend': friendUsername});
  }

  void joinRoom(String roomId, String username) {
    currentRoom = roomId;
    _socket!.emit('join_room', {'room': roomId, 'username': username});
  }

  void leaveRoom(String roomId) {
    _socket!.emit('leave_room', {'room': roomId});
    currentRoom = null;
  }

  /// Sends a chat message — queues locally if offline.
  Future<void> sendMessage(String roomId, String text, {String? mediaUrl}) async {
    final payload = <String, dynamic>{
      'room': roomId,
      'text': text,
      'media_url': mediaUrl,
    };
    if (!_isOnline || isOfflineMode) {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList('pending_messages') ?? [];
      pending.add(jsonEncode(payload));
      if (pending.length > 50) pending.removeAt(0);
      await prefs.setStringList('pending_messages', pending);
      return;
    }
    _socket!.emit('message', jsonEncode(payload));
  }

  /// Sends a widget note — always stores locally AND tries server.
  Future<void> sendWidgetNote(String toUserId, String message) async {
    // Always persist to local shared prefs so widget works immediately
    final entry = NoteEntry(
      sender: _username,
      body: message,
      timestamp: DateTime.now(),
    );
    final prefs = await SharedPreferences.getInstance();
    final sentLog = prefs.getStringList('widget_notes_sent') ?? [];
    sentLog.add(jsonEncode(entry.toJson()));
    if (sentLog.length > 20) sentLog.removeAt(0);
    await prefs.setStringList('widget_notes_sent', sentLog);
    await prefs.setString('last_note', message);
    await prefs.setString('last_note_ts', _formatTs(entry.timestamp));

    if (_isOnline && !isOfflineMode) {
      _socket!.emit('widget_write', {'to': toUserId, 'body': message});
    } else {
      // Queue for later
      final pending = prefs.getStringList('pending_notes') ?? [];
      pending.add(jsonEncode({'to': toUserId, 'body': message}));
      if (pending.length > 20) pending.removeAt(0);
      await prefs.setStringList('pending_notes', pending);
    }
  }

  void gameAction(String roomId, Map<String, dynamic> payload) =>
      _socket!.emit('game_action', {'room': roomId, ...payload});

  void acceptFriend(String friendUsername) =>
      _socket!.emit('accept_friend', {'from': friendUsername});

  @override
  void dispose() {
    _events.close();
    _searchResults.close();
    _rooms.close();
    _socket?.dispose();
    super.dispose();
  }
}
