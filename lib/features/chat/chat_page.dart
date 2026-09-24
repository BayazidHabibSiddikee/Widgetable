import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:widgetboard/core/services/websocket_service.dart';
import 'package:widgetboard/features/chat/voice_message.dart';

/// Chat message model — supports text, images, and audio files.
class ChatMessage {
  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.mediaUrl,
    this.audioPath,
    this.type = ChatType.text,
  });
  final String id;
  final String sender;
  final String text;
  final String? mediaUrl;
  final String? audioPath;
  final ChatType type;
}

enum ChatType { text, image, audio }

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});
  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final _text = TextEditingController();
  final List<ChatMessage> _messages = [];
  static const roomId = 'demo-room';
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    final ws = context.read<WebSocketService>();
    ws.onEvent.listen((event) {
      if (!mounted) return;
      final text = event['text'] as String? ?? '';
      final mediaUrl = event['media_url'] as String?;
      final sender = event['sender'] as String? ?? 'friend';
      setState(() {
        _messages.add(ChatMessage(
          id: DateTime.now().toIso8601String(),
          sender: sender,
          text: text,
          mediaUrl: mediaUrl,
          type: mediaUrl != null && mediaUrl.isNotEmpty ? ChatType.image : ChatType.text,
        ));
      });
    });
    ws.addListener(_onWsChange);
  }

  void _onWsChange() {
    if (context.mounted && _connected != context.read<WebSocketService>().isConnected) {
      setState(() => _connected = context.read<WebSocketService>().isConnected);
    }
  }

  void _send(String roomId) {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    context.read<WebSocketService>().sendMessage(roomId, text);
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
    context.read<WebSocketService>().removeListener(_onWsChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chats'),
            const SizedBox(width: 8),
            Icon(
              Icons.circle,
              size: 10,
              color: _connected ? Colors.green : Colors.red,
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.message_outlined, size: 56, color: cs.surfaceContainerHighest),
                      const SizedBox(height: 8),
                      Text('No messages yet', style: TextStyle(color: cs.onSurfaceVariant)),
                      Text('Say hi to start the conversation!', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                )
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
                              borderRadius: BorderRadius.circular(14),
                              child: CachedNetworkImage(
                                imageUrl: m.mediaUrl ?? '',
                                width: 160,
                                placeholder: (_, __) =>
                                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator()),
                                errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                              ),
                            )
                          : m.type == ChatType.audio
                              ? _AudioBubble(path: m.audioPath ?? '', isMine: isMine)
                              : Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8) +
                                      (isMine ? const EdgeInsets.only(top: 4) : EdgeInsets.zero),
                                  decoration: BoxDecoration(
                                    color: isMine ? cs.primary : cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(isMine ? 16 : 4),
                                      bottomRight: Radius.circular(isMine ? 4 : 16),
                                    ),
                                  ),
                                  child: Text(
                                    m.text,
                                    style: TextStyle(color: isMine ? cs.onPrimary : cs.onSurfaceVariant),
                                  ),
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
                  isDense: true,
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                  filled: true,
                ),
                onSubmitted: (_) => _send(roomId),
              ),
            ),
            VoiceMessageButton(
              onSend: (path) {
                setState(() {
                  _messages.add(ChatMessage(
                    id: DateTime.now().toString(),
                    sender: 'me',
                    text: '',
                    audioPath: path,
                    type: ChatType.audio,
                  ));
                });
                context.read<WebSocketService>().sendMessage(roomId, '', mediaUrl: path);
              },
            ),
            const SizedBox(width: 4),
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

class _AudioBubble extends StatelessWidget {
  const _AudioBubble({required this.path, required this.isMine});
  final String path;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isMine ? cs.primary : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMine ? 16 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 16),
        ),
      ),
      child: Row(children: [
        Icon(isMine ? Icons.volume_up : Icons.volume_down, size: 16),
        const SizedBox(width: 6),
        Text(
          path.split('/').last,
          style: TextStyle(color: isMine ? cs.onPrimary : cs.onSurfaceVariant, fontSize: 12),
        ),
      ]),
    );
  }
}
