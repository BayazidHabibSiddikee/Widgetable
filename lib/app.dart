import 'package:flutter/material.dart';
import 'package:widgetboard/core/theme.dart';
import 'package:widgetboard/features/home/home_page.dart';

class WidgetBoardApp extends StatelessWidget {
  const WidgetBoardApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'WidgetBoard',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const HomePage(),
      );
}
