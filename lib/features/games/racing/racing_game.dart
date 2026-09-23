import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetboard/core/services/score_service.dart';
import 'package:widgetboard/core/services/websocket_service.dart';

/// Side-scrolling racer: steer with drag / arrow FABs to dodge obstacles.
class RacingGame extends StatefulWidget {
  const RacingGame({super.key});
  @override
  State<RacingGame> createState() => _RacingGameState();
}

class _RacingGameState extends State<RacingGame> with SingleTickerProviderStateMixin {
  static const room = 'racing-room';
  double _playerX = 0; // -1 (left) to 1 (right)
  final List<Offset> _obstacles = [];
  late Timer _timer;
  double _top = 0;
  bool _over = false;
  int _score = 0;
  late final Animation<double> _bg;
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController.unbounded(vsync: this)
      ..repeat(reverse: true, period: const Duration(seconds: 1));
    _bg = CurvedAnimation(parent: _ctrl, curve: Curves.linear);
    _timer = Timer.periodic(const Duration(milliseconds: 60), _tick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WebSocketService>().joinRoom(room, 'racer');
    });
  }

  void _tick(Timer t) {
    if (_over) return;
    setState(() {
      _top += 6;
      if (_top > 600) _top = 0;
      _obstacles.add(Offset(
        ((_playerX * 2 + 1) / 2).clamp(0.0, 4.0) * 60,
        -_top,
      ));
      _obstacles.removeWhere((o) => o.dy > 650);
      _score++;
      _over = _obstacles.any((o) =>
          o.dy > 520 && o.dy < 600 && (o.dx - (_playerX * 2 + 1) / 2 * 60).abs() < 30);
    });
    if (_over) {
      _timer.cancel();
      _submitScore();
      _showGameOver();
    }
  }

  void _move(double dir) {
    if (_over) return;
    setState(() => _playerX = (_playerX + dir * 0.2).clamp(-1.0, 1.0));
    context.read<WebSocketService>().gameAction(room, {'action': 'move', 'x': _playerX});
  }

  void _submitScore() {
    context.read<ScoreService>().submitScore('Racing', 'player', _score);
  }

  void _showGameOver() => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Game Over! Score: $_score'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );

  @override
  void dispose() {
    _timer.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onPanUpdate: (e) => _move(e.delta.dx.sign * 0.15),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Racing'),
            actions: [Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: Text('Score: $_score', style: Theme.of(context).textTheme.titleMedium)),
            )],
          ),
          body: Stack(children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _RoadPainter(bg: _bg.value),
              ),
            ),
            ..._obstacles.map((o) => _obstacle(o)),
            Align(
              alignment: Alignment(_playerX, 0.8),
              child: const Icon(Icons.directions_car_filled, size: 48, color: Colors.red),
            ),
            if (_over) const Center(child: Text('Game Over', style: TextStyle(fontSize: 32))),
          ]),
          floatingActionButton: _over
              ? null
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  FloatingActionButton(
                    heroTag: 'left',
                    mini: true,
                    onPressed: () => _move(-0.3),
                    child: const Icon(Icons.arrow_left),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'right',
                    mini: true,
                    onPressed: () => _move(0.3),
                    child: const Icon(Icons.arrow_right),
                  ),
                ]),
        ),
      );

  Widget _obstacle(Offset o) => Positioned(
        left: o.dx,
        top: o.dy,
        child: const Icon(Icons.circle, size: 24, color: Colors.black54),
      );
}

class _RoadPainter extends CustomPainter {
  _RoadPainter({required this.bg});
  final double bg;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey.shade800;
    canvas.drawRect(Offset.zero & size, paint);
    final mid = Paint()..color = Colors.white70;
    for (double dy = -size.height + (bg * 200); dy < size.height; dy += 80) {
      canvas.drawLine(Offset(size.width / 2, dy), Offset(size.width / 2, dy + 40), mid);
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter old) => old.bg != bg;
}
