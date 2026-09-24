import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgetboard/core/services/websocket_service.dart';
import 'package:widgetboard/features/home/home_page.dart';

/// Entry point: enter server URL + username, then navigates to HomePage.
/// Also supports a pure-offline mode with no server needed.
class ServerConfigPage extends StatefulWidget {
  const ServerConfigPage({super.key});
  @override
  State<ServerConfigPage> createState() => _ServerConfigPageState();
}

class _ServerConfigPageState extends State<ServerConfigPage> {
  final _url = TextEditingController();
  final _name = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSaved().then((_) {
      _url.text = _savedUrl;
      _name.text = _savedName;
    });
  }

  String _savedUrl = 'http://localhost:3000';
  String _savedName = 'guest';

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedUrl = prefs.getString('server_url') ?? _savedUrl;
      _savedName = prefs.getString('username') ?? _savedName;
    });
  }

  Future<void> _connect({required bool offline}) async {
    if (!offline && (_name.text.trim().isEmpty)) return;
    final username = _name.text.trim().isEmpty ? 'guest' : _name.text.trim();
    final prefs = await SharedPreferences.getInstance();
    if (!offline) {
      await prefs.setString('server_url', _url.text.trim());
    }
    await prefs.setString('username', username);

    final ws = context.read<WebSocketService>();
    ws.isOfflineMode = offline;

    if (offline) {
      // No server — just navigate
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ws.connect(_url.text.trim());
      ws.setUsername(username);
    } finally {
      setState(() => _loading = false);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('WidgetBoard')),
        body: Center(
          child: Card(
            elevation: 6,
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Welcome to WidgetBoard',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share notes on each other\'s home-screen widgets,\nchat, share media, and play games together.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Your name',
                      hintText: 'e.g. alice',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _url,
                    decoration: const InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'http://your-ip:3000',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cloud_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(children: [
                          FilledButton(
                            onPressed: () => _connect(offline: false),
                            child: const Text('Connect & Continue'),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => _connect(offline: true),
                            icon: const Icon(Icons.wifi_off),
                            label: const Text('Use Offline Mode'),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Offline mode: widget notes work locally.\nChat and games require a server.',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ]),
                ],
              ),
            ),
          ),
        ),
      );
}
