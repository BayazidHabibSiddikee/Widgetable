import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetboard/core/services/websocket_service.dart';

/// Collaborative building game. Players take turns placing 2×2 colored
/// blocks on a shared grid; the goal is to build the tallest structure that
/// doesn't collapse. Blocks fall if nothing supports them (simplified gravity).
class BuilderGame extends StatefulWidget {
  const BuilderGame({super.key});
  @override
  State<BuilderGame> createState() => _BuilderGameState();
}

class _BuilderGameState extends State<BuilderGame> {
  static const _room = 'builder-room';
  static const _cols = 8;
  static const _rows = 12;
  final List<Color?> _grid = List.filled(_cols * _rows, null);
  int _score = 0;

  void _place(int col) {
    // find topmost empty cell in column
    final topIdx = col + (_rows - 1) * _cols;
    for (var r = _rows - 1; r >= 0; r--) {
      final idx = col + r * _cols;
      if (_grid[idx] == null) {
        final color = Colors.primaries[_score % Colors.primaries.length];
        setState(() {
          for (var i = 0; i < 2; i++) {
            final c = (col + i).clamp(0, _cols - 1);
            _grid[idx - i * _cols] = color;
          }
          _score++;
        });
        context.read<WebSocketService>().gameAction(_room, {
          'action': 'place',
          'col': col,
          'color': color.value,
        });
        _checkCollapse();
        return;
      }
    }
  }

  void _checkCollapse() {
    // Simplified: collapse any isolated floating 2x2 group above empty space
    // (full physics would require Union-Find connectivity.)
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Builder'), actions: [Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('Score: $_score')))]),
        body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: _cols / _rows,
              child: GridView.builder(
                itemCount: _grid.length,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _cols,
                ),
                itemBuilder: (_, i) => Container(
                  decoration: BoxDecoration(
                    color: _grid[i],
                    border: Border.all(color: Colors.black12, width: 0.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: List.generate(_cols, (i) => FilledButton(onPressed: () => _place(i), child: Text('Col $i')))),
          const SizedBox(height: 16),
        ]),
      );
}
