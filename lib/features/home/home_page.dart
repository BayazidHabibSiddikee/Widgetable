import 'package:flutter/material.dart';
import 'package:widgetboard/features/chat/chat_page.dart';
import 'package:widgetboard/features/games/games_home.dart';
import 'package:widgetboard/features/media/media_page.dart';
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
    WidgetWritePage(),
  ];

  void _setPage(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: _pages[_index],
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
