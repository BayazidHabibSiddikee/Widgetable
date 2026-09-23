import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global leaderboard + scoring.
/// Games call `submitScore` to update the local leaderboard; it syncs in real
/// time across players (via WebSocketService.gameAction) and persists locally.
class ScoreService with ChangeNotifier {
  ScoreService() {
    _load();
  }

  static const _key = 'scores_v1';
  final Map<String, int> _scores = {};
  Map<String, int> get scores => Map.unmodifiable(_scores);

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null) {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      _scores
        ..clear()
        ..addAll(decoded.cast<String, int>());
      notifyListeners();
    }
  }

  Future<void> submitScore(String gameId, String player, int points) async {
    final prev = _scores['$gameId:$player'] ?? 0;
    if (points > prev) {
      _scores['$gameId:$player'] = points;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_scores));
      notifyListeners();
    }
  }

  int scoreFor(String gameId, String player) => _scores['$gameId:$player'] ?? 0;

  List<MapEntry<String, int>> top(String gameId, {int limit = 10}) {
    final entries = _scores.entries.where((e) => e.key.startsWith('$gameId:')).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }
}
