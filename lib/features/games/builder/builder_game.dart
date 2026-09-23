import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetboard/core/services/score_service.dart';
import 'package:widgetboard/core/services/websocket_service.dart';

/// Collaborative building game on an 8×12 grid. Place 2×2 colored blocks
/// to maximize stable height. Scores increase with each supported placement.
class BuilderGame extends StatefulWidget {
  const BuilderGame({super.key});
  @override
  State<BuilderGame> createState() => _BuilderGameState();
}

class _BuilderGameState extends State<BuilderGame> {
  static const room = 'builder-room';
  static const _cols = 8;
  static const _rows = 12;
  final List<Color?> _grid = List.filled(_cols * _rows, null);
  int _score = 0;

  void _place(int col) {
    for (var r = _rows - 1; r >= 0; r--) {
      final idx = col + r * _cols;
      if (_grid[idx] == null && col + 1 < _cols && _grid[idx + 1] == null) {
        final color = Colors.primaries[_score % Colors.primaries.length];
        setState(() {
          _grid[idx] = color;
          _grid[idx + 1] = color;
          _score++;
        });
        context.read<ScoreService>().submitScore('Builder', 'player', _score);
        context.read<WebSocketService>().gameAction(room, {'action': 'place', 'col': col, 'color': color.value});
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Builder'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: Text('Score: $_score', style: Theme.of(context).textTheme.titleMedium)),
            )
          ],
        ),
        body: Column(children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: _cols / _rows,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _cols),
                itemCount: _grid.length,
                itemBuilder: (_, i) => Container(
                  decoration: BoxDecoration(
                    color: _grid[i],
                    border: Border.all(color: Colors.black12, width: 0.5),
                  ),
                ),
              ),
            ),
          ),
          Wrap(
            spacing: 4,
            children: List.generate(
              _cols,
              (i) => FilledButton(onPressed: () => _place(i), child: Text('C$i')),
            ),
          ),
          const SizedBox(height: 16),
        ]),
      );
}
