import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetboard/core/services/score_service.dart';
import 'package:widgetboard/features/chat/chat_page.dart';
import 'package:widgetboard/features/friends/friends_page.dart';
import 'package:widgetboard/features/games/games_home.dart';
import 'package:widgetboard/features/media/media_page.dart';
import 'package:widgetboard/features/widget_add/add_widget_page.dart';
import 'package:widgetboard/features/widget_write/widget_write_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _pages = [
    ChatsPage(),
    GamesHome(),
    MediaPage(),
    AddWidgetPage(),
  ];

  void _setPage(int i) => setState(() => _index = i);

  void _showLeaderboard() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Consumer<ScoreService>(builder: (_, svc, __) {
        final allScores = svc.scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        if (allScores.isEmpty) {
          return const SizedBox(
            height: 160,
            child: Center(child: Text('No high scores yet. Play a game!')),
          );
        }
        return SizedBox(
          height: 320,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 12),
            const Center(child: Text('Leaderboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: allScores.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final e = allScores[i];
                  final parts = e.key.split(':');
                  return ListTile(
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text(parts[1]),
                    subtitle: Text(parts[0]),
                    trailing: Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
          ]),
        );
      }),
    );
  }

  void _openFriends() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FriendsPage()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: _pages[_index],
        floatingActionButton: _index == 1
            ? FloatingActionButton.small(
                onPressed: _showLeaderboard,
                tooltip: 'Leaderboard',
                child: const Icon(Icons.emoji_events),
              )
            : _index == 0
                ? FloatingActionButton.small(
                    onPressed: _openFriends,
                    tooltip: 'Friends',
                    child: const Icon(Icons.person_add),
                  )
                : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _setPage,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
            NavigationDestination(icon: Icon(Icons.gamepad_outlined), label: 'Games'),
            NavigationDestination(icon: Icon(Icons.photo_library_outlined), label: 'Media'),
            NavigationDestination(icon: Icon(Icons.widgets_outlined), label: 'Widget'),
          ],
        ),
      );
}
