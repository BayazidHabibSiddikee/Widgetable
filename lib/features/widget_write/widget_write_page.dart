import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetboard/core/services/websocket_service.dart';

/// Lets users write short notes that the recipient sees on their home-screen
/// widget. Taps open the full list inside the app.
class WidgetWritePage extends StatefulWidget {
  const WidgetWritePage({super.key});
  @override
  State<WidgetWritePage> createState() => _WidgetWritePageState();
}

class _WidgetWritePageState extends State<WidgetWritePage> {
  final _note = TextEditingController();

  void _sendNote() {
    if (_note.text.trim().isEmpty) return;
    // In the real app you'd pick a friend from a contact list.
    const toUserId = 'friend-1';
    context.read<WebSocketService>().sendWidgetNote(toUserId, _note.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note sent to your friend\'s widget.')),
    );
    _note.clear();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Write to Widget')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(
              controller: _note,
              minLines: 3,
              maxLines: 6,
              maxLength: 140,
              decoration: InputDecoration(
                hintText: 'Say "miss u", a quick hello, or anything…',
                counterText: '${_note.text.length}/140',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _sendNote,
              icon: const Icon(Icons.widgets_outlined),
              label: const Text('Send to Widget'),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const _SampleNoteList(),
          ]),
        ),
      );
}

class _SampleNoteList extends StatelessWidget {
  const _SampleNoteList();
  static const _samples = [
    'miss u 💛',
    'Good morning!',
    'Don\'t forget lunch 🍱',
    'Have a great day!',
  ];

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _samples.map((s) => OutlinedButton(
            onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(s))),
            child: Text(s))).toList());
}
