import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _highScoreKey = 'high_score';
  static const String _gamesPlayedKey = 'games_played';
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _hapticsEnabledKey = 'haptics_enabled';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  int getHighScore() => _prefs?.getInt(_highScoreKey) ?? 0;

  Future<void> setHighScore(int value) async {
    await _prefs?.setInt(_highScoreKey, value);
  }

  int getGamesPlayed() => _prefs?.getInt(_gamesPlayedKey) ?? 0;

  Future<void> incrementGamesPlayed() async {
    final current = getGamesPlayed();
    await _prefs?.setInt(_gamesPlayedKey, current + 1);
  }

  bool getSoundEnabled() => _prefs?.getBool(_soundEnabledKey) ?? true;

  Future<void> setSoundEnabled(bool value) async {
    await _prefs?.setBool(_soundEnabledKey, value);
  }

  bool getHapticsEnabled() => _prefs?.getBool(_hapticsEnabledKey) ?? true;

  Future<void> setHapticsEnabled(bool value) async {
    await _prefs?.setBool(_hapticsEnabledKey, value);
  }
}
