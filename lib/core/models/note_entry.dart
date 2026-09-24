import 'dart:convert';

/// A single note written by one person to another's widget.
class NoteEntry {
  NoteEntry({
    required this.sender,
    required this.body,
    required this.timestamp,
  });

  final String sender;
  final String body;
  final DateTime timestamp;

  /// Format as a compact line for the Android widget.
  /// e.g. "alice — miss u 💛  ·  2:30 PM"
  String formatForWidget() {
    final time = _formatTime(timestamp);
    final truncated = body.length > 30 ? '${body.substring(0, 30)}…' : body;
    return '$sender — $truncated  ·  $time';
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $ampm';
  }

  Map<String, dynamic> toJson() => {
        'sender': sender,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
      };

  factory NoteEntry.fromJson(Map<String, dynamic> json) => NoteEntry(
        sender: json['sender'] as String,
        body: json['body'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  static List<NoteEntry> fromJsonList(String jsonString) {
    try {
      final list = jsonDecode(jsonString) as List<dynamic>;
      return list.map((e) => NoteEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static String toJsonList(List<NoteEntry> notes) =>
      jsonEncode(notes.map((n) => n.toJson()).toList());
}
