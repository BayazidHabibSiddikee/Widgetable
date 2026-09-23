import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetboard/core/services/websocket_service.dart';

/// Simple online "higher or lower" card game.
class CardsGame extends StatefulWidget {
  const CardsGame({super.key});
  @override
  State<CardsGame> createState() => _CardsGameState();
}

class _CardsGameState extends State<CardsGame> {
  static const _room = 'cards-room';
  int _value = 7;
  final _wins = 0;
  bool _guessed = false;
  String _result = '';

  void _guess(bool higher) {
    setState(() {
      _guessed = true;
      final next = 1 + (6 * (DateTime.now().millisecondsSinceEpoch % 6));
      if ((higher && next > _value) || (!higher && next < _value)) {
        _result = 'Correct! $next beats $_value';
      } else if (next == _value) {
        _result = 'Tie! $next';
      } else {
        _result = 'Wrong — was $next';
      }
      _value = next;
    });
    context.read<WebSocketService>().gameAction(_room, {
      'action': 'guess',
      'higher': higher,
      'next': _value,
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
        appBar: AppBar(title: const Text('Cards — Higher or Lower')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('$_value',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            Text(_result, style: const TextStyle(fontSize: 18)),
            if (!_guessed)
              Row(mainAxisSize: MainAxisSize.min, children: [
                FilledButton.icon(onPressed: () => _guess(false), icon: const Icon(Icons.arrow_downward), label: const Text('Lower')),
                const SizedBox(width: 12),
                FilledButton.icon(onPressed: () => _guess(true), icon: const Icon(Icons.arrow_upward), label: const Text('Higher')),
              ]),
          ]),
        ),
      );
}
