import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/theme.dart';
import 'core/services/websocket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final wsService = WebSocketService();
  await wsService.connect();
  runApp(
    ChangeNotifierProvider<WebSocketService>.value(
      value: wsService,
      child: const WidgetBoardApp(),
    ),
  );
}
