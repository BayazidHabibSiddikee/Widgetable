import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgetboard/core/services/websocket_service.dart';
import 'package:widgetboard/features/home/home_page.dart';

/// Entry point: enter server URL + username, then navigates to FriendsPage.
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

  Future<void> _connect() async {
    if (_url.text.trim().isEmpty || _name.text.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', _url.text.trim());
    await prefs.setString('username', _name.text.trim());
    setState(() => _loading = true);

    final ws = context.read<WebSocketService>();
    ws.setUsername(_name.text.trim());
    await ws.connect(_url.text.trim());

    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('WidgetBoard Setup')),
        body: Center(
          child: Card(
            elevation: 6,
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Enter your server & username', style: TextStyle(fontSize: 20)),
                const SizedBox(height: 16),
                TextField(
                  controller: _url,
                  decoration: InputDecoration(
                    labelText: 'Server URL',
                    hintText: 'http://your-ip:3000',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: 'Display name',
                    hintText: 'e.g. alice',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                _loading
                    ? const CircularProgressIndicator()
                    : FilledButton(
                        onPressed: _connect,
                        child: const Text('Connect & Continue'),
                      ),
              ]),
            ),
          ),
        ),
      );
}
