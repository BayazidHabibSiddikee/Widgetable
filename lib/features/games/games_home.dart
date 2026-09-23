import 'package:flutter/material.dart';
import 'package:widgetboard/features/games/ttc/ttc_game.dart';
import 'package:widgetboard/features/games/racing/racing_game.dart';
import 'package:widgetboard/features/games/ludo/ludo_game.dart';
import 'package:widgetboard/features/games/cards/cards_game.dart';
import 'package:widgetboard/features/games/truth_dare/truth_dare.dart';
import 'package:widgetboard/features/games/builder/builder_game.dart';
import 'package:widgetboard/features/games/angry_birds/angry_birds.dart';

class GamesHome extends StatelessWidget {
  const GamesHome({super.key});

  static final List<_GameEntry> _games = [
    _GameEntry(name: 'Tic-Tac-Toe', icon: Icons.grid_3x3, page: const TtcGame()),
    _GameEntry(name: 'Racing', icon: Icons.directions_car, page: const RacingGame()),
    _GameEntry(name: 'Ludo', icon: Icons.casino, page: const LudoGame()),
    _GameEntry(name: 'Cards', icon: Icons.credit_card, page: const CardsGame()),
    _GameEntry(name: 'Truth or Dare', icon: Icons.favorite, page: const TruthDare()),
    _GameEntry(name: 'Builder', icon: Icons.home_work, page: const BuilderGame()),
    _GameEntry(name: 'Angry Birds', icon: Icons.sports_esports, page: const AngryBirds()),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Games')),
        body: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: _games.length,
          itemBuilder: (_, i) {
            final g = _games[i];
            return Card.filled(
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => g.page)),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(g.icon, size: 36, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 6),
                    Text(g.name, style: const TextStyle(fontSize: 12)),
                  ]),
                ),
              ),
            );
          },
        ),
      );
}

class _GameEntry {
  _GameEntry({required this.name, required this.icon, required this.page});
  final String name;
  final IconData icon;
  final Widget page;
}
