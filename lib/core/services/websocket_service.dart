import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

/// Minimal WebSocket / Socket.IO signaling service.
///
/// In a real deployment point this at your signaling server URL.
/// It emits events such as `join_room`, `leave_room`, `message`,
/// `game_action`, and `widget_write` so users can interact in real time.
class WebSocketService with ChangeNotifier {
  late final socket_io.Socket _socket;

  bool get isConnected => _socket.connected;
  String? currentRoom;

  Future<void> connect() async {
    // Replace with your live server URL.
    _socket = socket_io.io(
      'http://localhost:3000',
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    _socket.connect();
    _socket.on('connect', (_) => notifyListeners());
    _socket.on('disconnect', (_) => notifyListeners());
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

  void sendWidgetNote(String toUserId, String message) {
    _socket.emit('widget_write', {
      'to': toUserId,
      'body': message,
    });
  }

  void gameAction(String roomId, Map<String, dynamic> payload) {
    _socket.emit('game_action', {
      'room': roomId,
      ...payload,
    });
  }

  @override
  void dispose() {
    _socket.dispose();
    super.dispose();
  }
}
