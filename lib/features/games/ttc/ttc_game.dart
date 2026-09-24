import 'dart:async';
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
  bool _isVsAI = true;
  bool _aiThinking = false;

  void _tap(int idx) {
    if (_cells[idx] != Player.none || _aiThinking) return;
    _makeMove(idx, Player.x);
    if (_isVsAI && !gameOver()) {
      setState(() => _aiThinking = true);
      Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        final aiMove = _bestMove();
        if (aiMove != -1) {
          _makeMove(aiMove, Player.o);
        }
        setState(() => _aiThinking = false);
      });
    }
  }

  void _makeMove(int idx, Player player) {
    setState(() {
      _cells[idx] = player;
      context.read<WebSocketService>().gameAction(room, {
        'action': 'move',
        'index': idx,
        'player': player == Player.x ? 'x' : 'o',
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
    if (!gameOver()) {
      setState(() => _current = _current == Player.x ? Player.o : Player.x);
    }
  }

  bool gameOver() {
    return _checkWin(_cells) != null || !_cells.contains(Player.none);
  }

  int _bestMove() {
    // Minimax for O (AI)
    int bestScore = -999;
    int bestIdx = -1;
    for (int i = 0; i < 9; i++) {
      if (_cells[i] == Player.none) {
        _cells[i] = Player.o;
        int score = _minimax(_cells, 0, false);
        _cells[i] = Player.none;
        if (score > bestScore) {
          bestScore = score;
          bestIdx = i;
        }
      }
    }
    return bestIdx;
  }

  int _minimax(List<Player> board, int depth, bool isMaximizing) {
    final win = _checkWin(board);
    if (win == Player.o) return 10 - depth;
    if (win == Player.x) return depth - 10;
    if (!board.contains(Player.none)) return 0;
    if (isMaximizing) {
      int best = -999;
      for (int i = 0; i < 9; i++) {
        if (board[i] == Player.none) {
          board[i] = Player.o;
          best = best > _minimax(board, depth + 1, false) ? best : _minimax(board, depth + 1, false);
          board[i] = Player.none;
        }
      }
      return best;
    } else {
      int best = 999;
      for (int i = 0; i < 9; i++) {
        if (board[i] == Player.none) {
          board[i] = Player.x;
          best = best < _minimax(board, depth + 1, true) ? best : _minimax(board, depth + 1, true);
          board[i] = Player.none;
        }
      }
      return best;
    }
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
              _aiThinking = false;
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
        appBar: AppBar(
          title: const Text('Tic-Tac-Toe'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                const Text('vs AI', style: TextStyle(fontSize: 12)),
                Switch(
                  value: _isVsAI,
                  onChanged: (_) {
                    setState(() {
                      _isVsAI = !_isVsAI;
                      _cells.fillRange(0, 9, Player.none);
                      _current = Player.x;
                    });
                  },
                ),
              ]),
            ),
          ],
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _aiThinking ? 'AI is thinking...' : 'Your turn: ${_current == Player.x ? 'X' : 'O'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
                    child: _cells[i] == Player.none && _aiThinking
                        ? const SizedBox(width: 42, height: 42, child: CircularProgressIndicator(strokeWidth: 3))
                        : Icon(
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
