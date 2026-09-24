import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:widgetboard/core/models/note_entry.dart';
import 'package:widgetboard/core/services/websocket_service.dart';
import 'package:widgetboard/core/widgets/premium_gate.dart';
import 'package:clipboard/clipboard.dart';

/// Add home-screen widget notes. Notes are stored per-user in SharedPreferences
/// under the key `widget_notes:<username>` so that when you open the app on your
/// phone you see the notes friends sent TO you, and when you send one it updates
/// YOUR widget which your friend will also see (via the shared server broadcast).
///
/// The widget renders up to 5 recent notes from different friends.
class AddWidgetPage extends StatefulWidget {
  const AddWidgetPage({super.key});

  @override
  State<AddWidgetPage> createState() => _AddWidgetPageState();
}


/// Shows the recent notes that have been sent TO the current user.
class _MyNotesPreview extends StatelessWidget {
  const _MyNotesPreview();

  Future<List<NoteEntry>> _loadMyNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('widget_notes_json') ?? '[]';
    return NoteEntry.fromJsonList(raw);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent notes from friends', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        FutureBuilder<List<NoteEntry>>(
          future: _loadMyNotes(),
          builder: (_, snap) {
            if (!snap.hasData || snap.data!.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No notes yet — ask a friend to send you a "miss u"!',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              );
            }
            final notes = snap.data!;
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: notes.length > 5 ? 5 : notes.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final n = notes[notes.length - 1 - i];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundColor: _avatarColor(n.sender),
                      child: Text(
                        n.sender[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                    title: Text(
                      n.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    subtitle: Text(
                      '${n.sender}  ·  ${_formatTime(n.timestamp)}',
                      style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Color _avatarColor(String name) {
    final colors = [Colors.deepPurple, Colors.blue, Colors.teal, Colors.orange, Colors.pink];
    int hash = 0;
    for (var c in name.codeUnits) hash = (hash * 31 + c) & 0x7fffffff;
    return colors[hash % colors.length];
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $ampm';
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
    'u r my sunshine 🌻',
    'can\'t stop smiling thinking of u 😊',
    'hope ur day is as lovely as u are 🌸',
    'sending u a virtual hug 🤗',
    'counting down till i see u again ⏳',
    'u make my world brighter ✨',
    'missing ur laugh 😄',
    'just wanted to say hi 👋',
    'u are always in my thoughts 🧠💛',
    'send me a smile pls 🥺',
    'today would be better if u were here',
    'grateful for u every single day 🙏',
    'u feel like home 🏡',
    'keep shining, the world needs u ⭐',
  ];

  static const _premiumTemplates = [
    'I\'m yours today 💍',
    'call me maybe 📞',
    'u up? midnight thoughts 🌙',
    '❤️ u more than wifi',
    'last text u sent = my fav memory 📱',
    'u have no idea how much i miss u',
    'wish u were here right now 🌍',
    'dream of me tonight 😴💫',
    'just got off the phone w/ my bestie n we talked about u',
    'u r the reason i believe in long distance 💕',
    'if u could read my mind rn u\'d blush 🙈',
    'this song came on and all i could think was u 🎵',
    'i keep re-reading our last conversation 📖',
    'u are my favourite notification 🔔',
    'sending u good vibes across the miles 🌈',
  ];

  Future<void> _sendNote() async {
    final body = _note.text.trim().isNotEmpty ? _note.text.trim() : _selectedTemplate;
    if (_recipient.text.trim().isEmpty) return;
    final recipient = _recipient.text.trim();

    final prefs = await SharedPreferences.getInstance();

    // Append to my own sent-log (for history on THIS device)
    final myNotesRaw = prefs.getStringList('widget_notes_sent') ?? [];
    final myNotes = myNotesRaw
        .map((s) => NoteEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    myNotes.add(NoteEntry(
      sender: context.read<WebSocketService>().username,
      body: body,
      timestamp: DateTime.now(),
    ));
    if (myNotes.length > 20) myNotes.removeAt(0);
    await prefs.setStringList(
      'widget_notes_sent',
      myNotes.map((n) => jsonEncode(n.toJson())).toList(),
    );

    // Also write latest single note for the native widget fallback
    await prefs.setString('last_note', body);
    await prefs.setString(
      'last_note_ts',
      DateFormat.yMMMd().add_jm().format(DateTime.now()),
    );

    final ws = context.read<WebSocketService>();
    ws.sendWidgetNote(recipient, body);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Note sent to $recipient\'s widget ✓')),
    );
    setState(() {
      _note.clear();
      _selectedTemplate = 'miss u 💛';
    });
  }

  void _showInstructions() {
    const instructions = '''
WidgetBoard — Share a Widget with Friends

1. Long-press an empty area on your Android home screen.
2. Tap "Widgets" at the bottom.
3. Scroll down to "WidgetBoard" and select the widget.
4. Place it anywhere — notes from ALL your friends will appear.

How sharing works:
• Each friend sends you notes via this app.
• You see their notes stacked on your home screen widget.
• They see their own notes on THEIR widget too.
• Notes are synced in real-time over the server.

Tips:
• Send "miss u 💛" or any quick message.
• Tap the widget to open the app.
• Your recent received notes are shown below.
''';

    FlutterClipboard.copy(instructions);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Instructions copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Share Widget'),
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
                decoration: const InputDecoration(
                  hintText: 'Enter friend\'s username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const _MyNotesPreview(),
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
                          label: Text(t),
                          selected: _selectedTemplate == t,
                          onSelected: (_) => setState(() => _selectedTemplate = t),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
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
                                label: Text(t),
                                selected: _selectedTemplate == t,
                                onSelected: (_) =>
                                    setState(() => _selectedTemplate = t),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
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
                  hintText: 'Override template with your own message...',
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
