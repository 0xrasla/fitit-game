import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  static bool _loaded = false;
  static bool sfxEnabled = true;
  static bool musicEnabled = true;

  static Future<void> load() async {
    if (_loaded) return;
    final cache = FlameAudio.audioCache;
    await Future.wait([
      cache.load('correct.wav'),
      cache.load('wrong.wav'),
      cache.load('level_complete.wav'),
      cache.load('game_over.wav'),
      cache.load('tick.wav'),
      cache.load('tap.wav'),
      cache.load('bgm.wav'),
    ]);
    _loaded = true;
  }

  static void playCorrect() {
    if (sfxEnabled) FlameAudio.play('correct.wav');
  }

  static void playWrong() {
    if (sfxEnabled) FlameAudio.play('wrong.wav');
  }

  static void playLevelComplete() {
    if (sfxEnabled) FlameAudio.play('level_complete.wav');
  }

  static void playGameOver() {
    if (sfxEnabled) FlameAudio.play('game_over.wav');
  }

  static void playTick() {
    if (sfxEnabled) FlameAudio.play('tick.wav');
  }

  static void playTap() {
    if (sfxEnabled) FlameAudio.play('tap.wav');
  }

  static void playBgm() {
    if (musicEnabled) FlameAudio.loop('bgm.wav', volume: 0.3);
  }

  static void stopBgm() => FlameAudio.bgm.stop();
}
