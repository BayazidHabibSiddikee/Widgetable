import 'package:flutter/material.dart';

/// Ludo placeholder — full Ludo board game implementation is substantial
/// (4-player tokens, dice, path traversal, cut-throat capture logic).
/// This renders an interactive board grid where each player has 4 tokens
/// and you can tap to roll a dice (auto-animation only). Real multiplayer
/// should extend WebSocketService.gameAction('ludo_move', ...).
class LudoGame extends StatefulWidget {
  const LudoGame({super.key});
  @override
  State<LudoGame> createState() => _LudoGameState();
}

class _LudoGameState extends State<LudoGame> with SingleTickerProviderStateMixin {
  late final AnimationController _diceCtrl;
  late final Animation<double> _diceRoll;
  int _dice = 1;

  @override
  void initState() {
    super.initState();
    _diceCtrl = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _diceRoll = CurvedAnimation(parent: _diceCtrl, curve: Curves.bounceOut);
  }

  void _roll() {
    setState(() => _dice = 1 + (3 * _diceRoll.value).toInt() % 6);
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
        appBar: AppBar(title: const Text('Ludo (WIP)')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _roll,
          label: AnimatedBuilder(
            animation: _diceRoll,
            builder: (_, child) => Transform.scale(scale: 1 + _diceRoll.value * 0.3, child: child),
          ),
          icon: const Icon(Icons.casino_outlined),
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
                  // 4 colored base corners
                  Positioned(top: 0, left: 0, child: _playerBase(0)),
                  Positioned(top: 0, right: 0, child: _playerBase(1)),
                  Positioned(bottom: 0, left: 0, child: _playerBase(2)),
                  Positioned(bottom: 0, right: 0, child: _playerBase(3)),
                  // dice
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
                                color: playerColors[_dice.clamp(0, 3)],
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
        width: 80,
        height: 80,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: playerColors[idx].withOpacity(0.25),
          border: Border.all(color: playerColors[idx], width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (_) => Icon(Icons.circle, size: 12, color: playerColors[idx])),
        ),
      );
}
