import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetboard/core/services/score_service.dart';
import 'package:widgetboard/features/games/ttc/ttc_game.dart';
import 'package:widgetboard/features/games/racing/racing_game.dart';
import 'package:widgetboard/features/games/ludo/ludo_game.dart';
import 'package:widgetboard/features/games/cards/cards_game.dart';
import 'package:widgetboard/features/games/truth_dare/truth_dare.dart';
import 'package:widgetboard/features/games/builder/builder_game.dart';
import 'package:widgetboard/features/games/angry_birds/angry_birds.dart';

class _HighScoreBadge extends StatelessWidget {
  const _HighScoreBadge({required this.gameId});
  final String gameId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final score = context.watch<ScoreService>().scoreFor(gameId, 'player');
    if (score == 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.emoji_events, size: 12, color: cs.secondary),
        const SizedBox(width: 2),
        Text('$score', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _GameEntry {
  _GameEntry({required this.id, required this.name, required this.icon, required this.page});
  final String id;
  final String name;
  final IconData icon;
  final Widget page;
}

class GamesHome extends StatelessWidget {
  const GamesHome({super.key});

  static final List<_GameEntry> _games = [
    _GameEntry(id: 'tictactoe', name: 'Tic-Tac-Toe', icon: Icons.grid_3x3, page: const TtcGame()),
    _GameEntry(id: 'racing', name: 'Racing', icon: Icons.directions_car, page: const RacingGame()),
    _GameEntry(id: 'ludo', name: 'Ludo', icon: Icons.casino, page: const LudoGame()),
    _GameEntry(id: 'cards', name: 'Cards', icon: Icons.credit_card, page: const CardsGame()),
    _GameEntry(id: 'truthdare', name: 'Truth or Dare', icon: Icons.favorite, page: const TruthDare()),
    _GameEntry(id: 'builder', name: 'Builder', icon: Icons.home_work, page: const BuilderGame()),
    _GameEntry(id: 'angrybirds', name: 'Angry Birds', icon: Icons.sports_esports, page: const AngryBirds()),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Games')),
      body: LayoutBuilder(
        builder: (_, constraints) {
          final cols = (constraints.maxWidth / 140).floor().clamp(2, 4);
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: _games.length,
            itemBuilder: (_, i) {
              final g = _games[i];
              return Card.filled(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => g.page),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(g.icon, size: 36, color: cs.primary),
                        const SizedBox(height: 4),
                        Text(g.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        _HighScoreBadge(gameId: g.id),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
