import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetboard/core/services/score_service.dart';
import 'package:widgetboard/core/services/websocket_service.dart';

/// Higher-or-Lower card prediction game. Win streaks boost score.
class CardsGame extends StatefulWidget {
  const CardsGame({super.key});
  @override
  State<CardsGame> createState() => _CardsGameState();
}

class _CardsGameState extends State<CardsGame> {
  static const room = 'cards-room';
  int _value = 7;
  String _result = '';
  bool _guessed = false;
  int _wins = 0;
  int _streak = 0;

  void _guess(bool higher) {
    if (_guessed) return;
    setState(() => _guessed = true);
    final next = 1 + (6 * (DateTime.now().millisecondsSinceEpoch % 6));
    String res;
    if ((higher && next > _value) || (!higher && next < _value)) {
      res = 'Correct! $next beats $_value';
      _wins++;
      _streak++;
    } else if (next == _value) {
      res = 'Tie! $next';
      _streak = 0;
    } else {
      res = 'Wrong — was $next';
      _streak = 0;
    }
    context
      .read<WebSocketService>()
      .gameAction(room, {'action': 'guess', 'higher': higher, 'next': next});
    context
      .read<ScoreService>()
      .submitScore('Cards', 'player', _wins * 10 + _streak);
    setState(() {
      _result = res;
      _value = next;
    });
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _guessed = false;
        _result = '';
      });
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Cards: Higher or Lower'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text('Best: $_wins  Streak: $_streak',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
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
                const Text('Current card', style: TextStyle(fontSize: 18)),
                Text('$_value',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: Colors.deepPurple,
                    )),
                const SizedBox(height: 12),
                Text(_result,
                    style: TextStyle(
                        fontSize: 18,
                        color: _result.contains('Correct')
                            ? Colors.green
                            : _result.contains('Wrong')
                                ? Colors.red
                                : Colors.grey)),
                const SizedBox(height: 12),
                if (!_guessed)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    FilledButton.icon(
                      onPressed: () => _guess(false),
                      icon: const Icon(Icons.arrow_downward),
                      label: const Text('Lower'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () => _guess(true),
                      icon: const Icon(Icons.arrow_upward),
                      label: const Text('Higher'),
                    ),
                  ]),
              ]),
            ),
          ),
        ),
      );
}
