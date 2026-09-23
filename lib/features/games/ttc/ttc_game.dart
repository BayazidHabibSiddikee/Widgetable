import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetboard/core/services/score_service.dart';
import 'package:widgetboard/core/services/websocket_service.dart';

enum Player { x, o, none }

class TtcGame extends StatefulWidget {
  const TtcGame({super.key});
  @override
  State<TtcGame> createState() => _TtcGameState();
}

class _TtcGameState extends State<TtcGame> {
  static const room = 'ttc-room';
  Player _current = Player.x;
  final List<Player> _cells = List.filled(9, Player.none);

  void _tap(int idx) {
    if (_cells[idx] != Player.none) return;
    setState(() {
      _cells[idx] = _current;
      context.read<WebSocketService>().gameAction(room, {
        'action': 'move',
        'index': idx,
        'player': _current == Player.x ? 'x' : 'o',
      });
    });
    final win = _checkWin(_cells);
    if (win is Player && win != Player.none) {
      final winner = win == Player.x ? 'X' : 'O';
      _end('$winner wins!', points: 10);
      context.read<ScoreService>().submitScore('Tic-Tac-Toe', winner, 10);
    } else if (win == null && !_cells.contains(Player.none)) {
      _end('Draw!');
    }
    _current = _current == Player.x ? Player.o : Player.x;
  }

  Player? _checkWin(List<Player> board) {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];
    for (final line in lines) {
      final a = board[line[0]];
      if (a != Player.none && a == board[line[1]] && a == board[line[2]]) return a;
    }
    return null;
  }

  void _end(String msg, {int points = 0}) => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(msg),
          actions: [TextButton(onPressed: () {
            Navigator.pop(context);
            setState(() {
              _cells.fillRange(0, 9, Player.none);
              _current = Player.x;
            });
          }, child: const Text('Play again'))],
        ),
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WebSocketService>().joinRoom(room, 'player');
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Tic-Tac-Toe')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Current turn: ${_current == Player.x ? 'X' : 'O'}',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
              ),
              itemCount: 9,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _tap(i),
                child: Card(
                  elevation: 3,
                  child: Center(
                    child: Icon(
                      switch (_cells[i]) {
                        Player.x => Icons.close,
                        Player.o => Icons.circle,
                        Player.none => null,
                      },
                      size: 42,
                      color: switch (_cells[i]) {
                        Player.x => Colors.red,
                        Player.o => Colors.blue,
                        Player.none => null,
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      );
}
