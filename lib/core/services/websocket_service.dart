import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

/// WebSocket / Socket.IO signaling service for WidgetBoard.
///
/// Emits (client → server):
///   - `register`            { username }
///   - `search_users`        { query }
///   - `add_friend`          { to_username }
///   - `create_room`         { game, friend }   → emits `room_created` { room }
///   - `join_room`           { room, username }
///   - `leave_room`          { room }
///   - `message`             { room, text, media_url }
///   - `game_action`         { room, ...payload }
///   - `widget_write`        { to_userId, body }
///
/// Listens (server → client):
///   - `search_results`     List<dynamic>  (matched users)
///   - `friend_request`     { from }
///   - `room_created`       { room, game, friend }
///   - `room_joined`        { room }
///   - `user_joined`        { username }
///   - `incoming_message`   { room, text, media_url, sender }
///   - `widget_write`       { from, body }
class WebSocketService with ChangeNotifier {
  late final socket_io.Socket _socket;
  String _username = 'guest';

  String get username => _username;
  bool get isConnected => _socket.connected;
  String? currentRoom;

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

  Future<void> connect(String? serverUrl) async {
    _socket = socket_io.io(
      serverUrl ?? 'http://localhost:3000',
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    _socket.connect();
    _socket.on('connect', (_) => notifyListeners());
    _socket.on('disconnect', (_) => notifyListeners());
    _registerSocketHandlers();
  }

  void _registerSocketHandlers() {
    _socket.on('search_results', _handleSearchResults);
    _socket.on('friend_request', _forward);
    _socket.on('room_created', _handleRoomCreated);
    _socket.on('room_joined', _forward);
    _socket.on('user_joined', _forward);
    _socket.on('incoming_message', _forward);
    _socket.on('widget_write', _forward);
    _socket.on('friends_list', (data) {
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

  void setUsername(String name) {
    _username = name;
    _socket.emit('register', {'username': name});
  }

  void searchUsers(String query) => _socket.emit('search_users', {'query': query});

  void addFriend(String friendUsername) =>
      _socket.emit('add_friend', {'to_username': friendUsername});

  /// Ask server to create (or find) a room for a given game + 2 players.
  Future<void> createOrJoinRoom(String gameId, String friendUsername) async {
    _socket.emit('create_room', {'game': gameId, 'friend': friendUsername});
  }

  void joinRoom(String roomId, String username) {
    currentRoom = roomId;
    _socket.emit('join_room', {'room': roomId, 'username': username});
  }

  void leaveRoom(String roomId) {
    _socket.emit('leave_room', {'room': roomId});
    currentRoom = null;
  }

  void sendMessage(String roomId, String text, {String? mediaUrl}) {
    _socket.emit('message', jsonEncode({
      'room': roomId,
      'text': text,
      'media_url': mediaUrl,
    }));
  }

  void sendWidgetNote(String toUserId, String message) =>
      _socket.emit('widget_write', {'to': toUserId, 'body': message});

  void gameAction(String roomId, Map<String, dynamic> payload) =>
      _socket.emit('game_action', {'room': roomId, ...payload});

  void acceptFriend(String friendUsername) =>
      _socket.emit('accept_friend', {'from': friendUsername});

  @override
  void dispose() {
    _events.close();
    _searchResults.close();
    _rooms.close();
    _socket.dispose();
    super.dispose();
  }
}
