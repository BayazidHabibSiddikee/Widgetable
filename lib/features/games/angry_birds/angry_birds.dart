import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetboard/core/services/score_service.dart';
import 'package:widgetboard/core/services/websocket_service.dart';

/// 2-player Angry-Birds lite: builder constructs a brick wall; attacker taps
/// to destroy bricks. Destroying more bricks = higher score.
class AngryBirds extends StatefulWidget {
  const AngryBirds({super.key});
  @override
  State<AngryBirds> createState() => _AngryBirdsState();
}

class _AngryBirdsState extends State<AngryBirds> {
  static const room = 'angry-room';
  static const int _cols = 6;
  static const int _rows = 8;
  final List<bool> _bricks = List.filled(_cols * _rows, true);
  int _hits = 0;

  void _destroyAt(int idx) {
    if (!_bricks[idx]) return;
    setState(() {
      _bricks[idx] = false;
      _hits++;
    });
    context.read<ScoreService>().submitScore('Angry Birds', 'attacker', _hits);
    context.read<WebSocketService>().gameAction(room, {'action': 'destroy', 'idx': idx});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WebSocketService>().joinRoom(room, 'builder');
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Angry Birds (2P)'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: Text('Hits: $_hits', style: Theme.of(context).textTheme.titleMedium)),
            )
          ],
        ),
        body: Column(children: [
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.sports_football), label: const Text('Tap bricks to destroy')),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _bricks.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _cols),
              itemBuilder: (_, i) => _bricks[i]
                  ? GestureDetector(
                      onTap: () => _destroyAt(i),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.brown.shade700,
                          border: Border.all(color: Colors.black26),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Destroy bricks — each destroyed brick earns you a point.'),
          const SizedBox(height: 16),
        ]),
      );
}
