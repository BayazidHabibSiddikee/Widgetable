import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetboard/core/services/websocket_service.dart';

/// 2-player "Angry Birds lite". One player builds a structure wall; the other
/// flings birds to destroy it. Taps over the wall send `destroy` actions which
/// propagate via WebSocket, removing bricks on the builder's side.
class AngryBirds extends StatefulWidget {
  const AngryBirds({super.key});
  @override
  State<AngryBirds> createState() => _AngryBirdsState();
}

class _AngryBirdsState extends State<AngryBirds> {
  static const _room = 'angry-room';
  static const int _wallCols = 6;
  static const int _wallRows = 8;
  final List<bool> _bricks = List.filled(_wallCols * _wallRows, true);

  void _destroyAt(int idx) {
    setState(() => _bricks[idx] = false);
    context.read<WebSocketService>().gameAction(_room, {
      'action': 'destroy',
      'idx': idx,
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameStream((_) {
      context.read<WebSocketService>().joinRoom(_room, 'builder');
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Angry Birds (2P)')),
        body: Column(children: [
          const SizedBox(height: 16),
          TextButton.icon(onPressed: () {
            // Simulate a bird hit — the "attacker" would send this via WS.
          }, icon: const Icon(Icons.sports_football), label: const Text('Throw bird (tap wall below)')),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _bricks.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _wallCols),
              itemBuilder: (_, i) => _bricks[i]
                  ? GestureDetector(
                      onTap: () => _destroyAt(i),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.brown.shade700,
                            border: Border.all(color: Colors.black26)),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Destroy bricks by tapping. Each brick destroyed lowers the wall.'),
        ]),
      );
}
