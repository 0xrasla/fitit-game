import 'package:shared_preferences/shared_preferences.dart';

class HighScoreStore {
  static const _key = 'high_scores';

  static Future<List<int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null) return [];
    final scores = raw.map(int.parse).toList();
    scores.sort((a, b) => b.compareTo(a));
    return scores;
  }

  static Future<void> save(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final scores = await load();
    scores.add(score);
    scores.sort((a, b) => b.compareTo(a));
    final top5 = scores.take(5).toList();
    await prefs.setStringList(_key, top5.map((e) => e.toString()).toList());
  }
}
