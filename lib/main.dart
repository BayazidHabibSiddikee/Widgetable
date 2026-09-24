import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/services/score_service.dart';
import 'core/services/websocket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final wsService = WebSocketService();
  final scoreService = ScoreService();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<WebSocketService>.value(value: wsService),
        ChangeNotifierProvider<ScoreService>.value(value: scoreService),
      ],
      child: const WidgetBoardApp(),
    ),
  );
}
