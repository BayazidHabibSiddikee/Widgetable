import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgetboard/core/services/websocket_service.dart';
import 'package:widgetboard/core/widgets/premium_gate.dart';

/// Add home-screen widget + compose notes that friends see on their AppWidget.
/// Some premium note templates are gated behind a paywall.
class AddWidgetPage extends StatefulWidget {
  const AddWidgetPage({super.key});

  @override
  State<AddWidgetPage> createState() => _AddWidgetPageState();
}

class _LastSentNote extends StatelessWidget {
  const _LastSentNote({required this.onPick});
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<String?>(
      future: () async {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString('last_note');
      }(),
      builder: (_, snap) {
        final note = snap.data;
        if (note == null || note.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent note', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            InkWell(
              onTap: () => onPick(note),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(note, style: TextStyle(color: cs.onSurfaceVariant)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AddWidgetPageState extends State<AddWidgetPage> {
  final TextEditingController _note = TextEditingController();
  final TextEditingController _recipient = TextEditingController();
  String _selectedTemplate = 'miss u 💛';

  static const _templates = [
    'miss u 💛',
    'thinking of you 💭',
    'good morning ☀️',
    'have a great day 🌟',
    'miss our talks 😢',
    'you\'ve got this 💪',
  ];

  static const _premiumTemplates = [
    'I\'m yours today 💍',
    'call me maybe 📞',
    'send nudes? 😜',
    'u up? midnight thoughts 🌙',
    '❤️ u more than wifi',
  ];

  Future<void> _sendNote() async {
    final body = _note.text.trim().isNotEmpty ? _note.text.trim() : _selectedTemplate;
    if (_recipient.text.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_note', body);
    await prefs.setString(
      'last_note_ts',
      DateFormat.yMMMd().add_jm().format(DateTime.now()),
    );

    final ws = context.read<WebSocketService>();
    ws.sendWidgetNote(_recipient.text.trim(), body);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Note sent to ${_recipient.text.trim()}\'s widget ✓'),
      ),
    );
    setState(() {
      _note.clear();
      _selectedTemplate = 'miss u 💛';
    });
  }

  void _showInstructions() {
    const instructions = '''
WidgetBoard — Add to Home Screen

1. Long-press an empty area on your Android home screen.
2. Tap "Widgets" at the bottom.
3. Scroll down to "WidgetBoard" and select the widget.
4. Place it anywhere — notes from friends will appear instantly.
5. Tap the widget to open this app and see full conversations.

Tips:
• Notes update automatically — no need to reopen the app.
• Send "miss u 💛", birthdays, or quick hellos.
• Tap a friend's tile in Chats to send a note directly.
''';

    FlutterClipboard.copy(instructions);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Instructions copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Add Home Widget'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showInstructions,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Recipient username',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _recipient,
                decoration: InputDecoration(
                  hintText: 'Enter friend\'s username',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Quick templates',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _templates
                    .map((t) => ChoiceChip(
                          label: Text(
                            t,
                            style: TextStyle(
                              color: _selectedTemplate == t ? Colors.white : null,
                            ),
                          ),
                          selected: _selectedTemplate == t,
                          onSelected: (_) => setState(() => _selectedTemplate = t),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              // Premium-only templates
              PremiumGate(
                feature: 'premium templates',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Premium templates',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _premiumTemplates
                          .map((t) => ChoiceChip(
                                label: Text(
                                  t,
                                  style: TextStyle(
                                    color: _selectedTemplate == t ? Colors.white : Colors.deepPurple,
                                  ),
                                ),
                                selected: _selectedTemplate == t,
                                onSelected: (_) => setState(() => _selectedTemplate = t),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _LastSentNote(onPick: (note) => setState(() => _note.text = note)),
              const SizedBox(height: 16),
              const Text(
                'Custom note (optional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _note,
                maxLength: 120,
                decoration: const InputDecoration(
                  hintText: 'Override template with your own message…',
                  border: OutlineInputBorder(),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _sendNote,
                icon: const Icon(Icons.widgets_outlined),
                label: const Text('Send to Widget'),
              ),
            ],
          ),
        ),
      );
}
