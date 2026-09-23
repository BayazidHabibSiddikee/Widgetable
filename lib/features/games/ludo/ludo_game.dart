import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetboard/core/services/score_service.dart';
import 'package:widgetboard/core/services/websocket_service.dart';

/// Ludo placeholder — board grid, dice roll animation, score counter.
/// Multiplayer requires WebSocketService.gameAction('ludo_place', ...).
class LudoGame extends StatefulWidget {
  const LudoGame({super.key});
  @override
  State<LudoGame> createState() => _LudoGameState();
}

class _LudoGameState extends State<LudoGame>
    with SingleTickerProviderStateMixin {
  static const room = 'ludo-room';
  late final AnimationController _diceCtrl;
  late final Animation<double> _diceRoll;
  int _dice = 1;
  int _rounds = 0;
  bool get _canRoll => !_diceCtrl.isAnimating;

  @override
  void initState() {
    super.initState();
    _diceCtrl =
        AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _diceRoll = CurvedAnimation(parent: _diceCtrl, curve: Curves.bounceOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WebSocketService>().joinRoom(room, 'player');
    });
  }

  void _roll() {
    if (!_canRoll) return;
    setState(() {
      _rounds++;
      _dice = 1 + ((_rounds * 7) % 6);
    });
    context
        .read<ScoreService>()
        .submitScore('Ludo', 'player', _rounds * _dice);
    _diceCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _diceCtrl.dispose();
    super.dispose();
  }

  static const playerColors = <Color>[Colors.red, Colors.blue, Colors.green, Colors.yellow];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Ludo (WIP)'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                  child: Text('Rounds: $_rounds',
                      style: Theme.of(context).textTheme.titleMedium)),
            )
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _canRoll ? _roll : null,
          icon: const Icon(Icons.casino_outlined),
          label: AnimatedBuilder(
            animation: _diceRoll,
            builder: (_, child) =>
                Transform.scale(scale: 1 + _diceRoll.value * 0.3, child: child),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.deepOrange.shade50,
                  border: Border.all(color: Colors.brown, width: 6),
                ),
                child: Stack(children: [
                  for (var i = 0; i < 4; i++) Positioned(top: 0, left: 0, child: _playerBase(i)),
                  for (var i = 0; i < 2; i++) Positioned(top: 0, right: 0, child: _playerBase(i + 2)),
                  for (var i = 0; i < 2; i++) Positioned(bottom: 0, left: 0, child: _playerBase(i)),
                  for (var i = 0; i < 2; i++) Positioned(bottom: 0, right: 0, child: _playerBase(i + 2)),
                  Center(
                    child: Card(
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Text('Dice', style: TextStyle(fontSize: 20)),
                          Text('$_dice',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: playerColors[(_dice - 1).clamp(0, 3)],
                              )),
                        ]),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );

  Widget _playerBase(int idx) => Container(
        width: 90,
        height: 90,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: playerColors[idx].withOpacity(0.25),
          border: Border.all(color: playerColors[idx], width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: List.generate(
            4,
            (_) => Icon(Icons.circle, size: 12, color: playerColors[idx]),
          ),
        ),
      );
}
