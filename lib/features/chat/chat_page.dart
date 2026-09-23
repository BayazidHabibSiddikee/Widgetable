import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:widgetboard/core/services/websocket_service.dart';

/// Dummy model so the list compiles; plug into your backend later.
class ChatMessage {
  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.mediaUrl,
    this.type = ChatType.text,
  });
  final String id;
  final String sender;
  final String text;
  final String? mediaUrl;
  final ChatType type;
}

enum ChatType { text, image, gif }

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});
  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final _text = TextEditingController();
  final _messages = <ChatMessage>[];

  void _send(String roomId) {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    final ws = context.read<WebSocketService>();
    ws.sendMessage(roomId, text);
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().toString(),
        sender: 'me',
        text: text,
      ));
    });
    _text.clear();
  }

  Future<void> _pickMedia(String roomId) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final ws = context.read<WebSocketService>();
    ws.sendMessage(roomId, '', mediaUrl: file.path);
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().toString(),
        sender: 'me',
        text: '',
        mediaUrl: file.path,
        type: ChatType.image,
      ));
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const roomId = 'demo-room';
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        centerTitle: false,
      ),
      body: Column(children: [
        Expanded(
          child: _messages.isEmpty
              ? const Center(child: Text('No messages yet — say hi!'))
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final m = _messages[_messages.length - 1 - i];
                    final isMine = m.sender == 'me';
                    return Align(
                      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: m.type == ChatType.image
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: m.mediaUrl ?? '',
                                width: 160,
                                placeholder: (_, __) =>
                                    const SizedBox(16, 16, child: CircularProgressIndicator()),
                                errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isMine ? cs.primary : cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(m.text,
                                  style: TextStyle(color: isMine ? cs.onPrimary : cs.onSurfaceVariant)),
                            ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.image_outlined),
              onPressed: () => _pickMedia(roomId),
            ),
            Expanded(
              child: TextField(
                controller: _text,
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _send(roomId),
              ),
            ),
            IconButton(
              icon: Icon(_text.text.trim().isEmpty ? Icons.gif_box_outlined : Icons.send),
              onPressed: () => _text.text.trim().isEmpty
                  ? null
                  : _send(roomId),
            ),
          ]),
        ),
      ]),
    );
  }
}
