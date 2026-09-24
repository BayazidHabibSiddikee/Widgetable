import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetboard/core/services/websocket_service.dart';

/// Friend search + add screen. Lists online friends so you can create or
/// join game rooms with each other.
class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final TextEditingController _query = TextEditingController();
  final List<String> _results = [];
  final List<String> _pendingRequests = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ws = context.read<WebSocketService>();
      ws.onSearchResults.listen((users) {
        if (!mounted) return;
        setState(() {
          _results
            ..clear()
            ..addAll(users);
        });
      });
      ws.onEvent.listen((event) {
        if (!mounted) return;
        if (event['type'] == 'friend_request') {
          setState(() => _pendingRequests.add(event['from'] as String));
        }
      });
    });
  }

  void _search(String query) {
    if (query.trim().isNotEmpty) {
      context.read<WebSocketService>().searchUsers(query.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<WebSocketService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _query,
              decoration: InputDecoration(
                hintText: 'Search users…',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: _search,
            ),
          ),
          const SizedBox(height: 8),
          // Search results
          if (_results.isNotEmpty) ...[
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Results')),
            ..._results.map((u) => ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(u),
                  trailing: IconButton(
                    icon: const Icon(Icons.person_add, color: Colors.blue),
                    onPressed: () {
                      ws.addFriend(u);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Request sent to $u')),
                      );
                    },
                  ),
                )),
          ],
          // Pending friend requests
          if (_pendingRequests.isNotEmpty) ...[
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Incoming requests')),
            ..._pendingRequests.map((u) => ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(u),
                  trailing: Wrap(spacing: 8, children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => ws.acceptFriend(u),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => setState(() => _pendingRequests.remove(u)),
                    ),
                  ]),
                )),
          ],
          // Online friends
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Your friends'),
          ),
          Expanded(
            child: ws.friends.isEmpty
                ? const Center(child: Text('No friends yet. Search and add one!'))
                : ListView.builder(
                    itemCount: ws.friends.length,
                    itemBuilder: (_, i) {
                      final f = ws.friends[i];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                        title: Text(f),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showGamePicker(f),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showGamePicker(String friend) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SizedBox(
        height: 240,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Choose game',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: [
                  _gameItem(Icons.grid_3x3, 'Tic-Tac-Toe', 'ttc', friend),
                  _gameItem(Icons.directions_car, 'Racing', 'racing', friend),
                  _gameItem(Icons.casino, 'Ludo', 'ludo', friend),
                  _gameItem(Icons.credit_card, 'Cards', 'cards', friend),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gameItem(IconData icon, String name, String id, String friend) => ListTile(
        leading: Icon(icon),
        title: Text(name),
        onTap: () {
          Navigator.pop(context);
          Navigator.pop(context);
          final ws = context.read<WebSocketService>();
          ws.createOrJoinRoom(id, friend);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Created room for $name with $friend')),
          );
        },
      );
}
