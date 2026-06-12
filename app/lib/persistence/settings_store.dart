import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore {
  static const _sfxKey = 'sfx_enabled';
  static const _musicKey = 'music_enabled';

  static Future<bool> isSfxEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sfxKey) ?? true;
  }

  static Future<bool> isMusicEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_musicKey) ?? true;
  }

  static Future<void> setSfxEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxKey, value);
  }

  static Future<void> setMusicEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicKey, value);
  }
}
