import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetboard/core/services/score_service.dart';
import 'package:widgetboard/core/services/websocket_service.dart';

/// Truth-or-Dare spinner for multiple players. Streak counter + timer.
class TruthDare extends StatefulWidget {
  const TruthDare({super.key});
  @override
  State<TruthDare> createState() => _TruthDareState();
}

class _TruthDareState extends State<TruthDare>
    with SingleTickerProviderStateMixin {
  static const room = 'truth-room';
  late final AnimationController _ctrl;
  late final Animation<double> _spin;
  bool _spinning = false;
  static final _truths = [
    'What\'s the most embarrassing text in your phone?',
    'Have you ever pretended to like a gift?',
    'What’s something you’re afraid of?',
    'Tell us about your weirdest talent.',
  ];
  static final _dares = [
    'Do an accent for the next 30 seconds.',
    'Send a "miss u" note to someone.',
    'Dance for 15 seconds on camera.',
    'Let the group DM your last 5 photos.',
  ];
  String _prompt = '';
  bool _isTruth = true;
  int _streak = 0;

  void _spinWheel() {
    if (_spinning) return;
    final isTruth = DateTime.now().second.isEven;
    final list = isTruth ? _truths : _dares;
    setState(() => _spinning = true);
    context.read<WebSocketService>().gameAction(room, {'action': 'spin'});
    _ctrl.forward(from: 0).whenComplete(() {
      setState(() {
        _spinning = false;
        _prompt = list[DateTime.now().millisecondsSinceEpoch % list.length];
        _isTruth = isTruth;
        _streak++;
      });
      context.read<ScoreService>().submitScore('Truth or Dare', 'player', _streak);
    });
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _spin = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Truth or Dare'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: Text('Streak: $_streak', style: Theme.of(context).textTheme.titleMedium)),
            )
          ],
        ),
        body: Center(
          child: Card(
            elevation: 6,
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (_prompt.isNotEmpty) ...[
                  Text(_isTruth ? 'TRUTH' : 'DARE',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _isTruth ? Colors.blue : Colors.red)),
                  const SizedBox(height: 12),
                  Text(_prompt, style: const TextStyle(fontSize: 20)),
                ] else if (_spinning) ...[
                  Transform.rotate(angle: _spin.value * 6.28, child: const FlutterLogo(size: 56)),
                  const SizedBox(height: 12),
                  const Text('Spinning…'),
                ] else ...[
                  const Text('Hold & spin!', style: TextStyle(fontSize: 22)),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _spinning ? null : _spinWheel,
                  icon: const Icon(Icons.emoji_events),
                  label: const Text('SPIN'),
                ),
              ]),
            ),
          ),
        ),
      );
}
