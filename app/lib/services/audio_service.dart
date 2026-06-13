import 'package:flame_audio/flame_audio.dart';
import 'storage_service.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final StorageService _storage = StorageService();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await FlameAudio.audioCache.loadAll([
        'correct.wav',
        'wrong.wav',
        'tick.wav',
        'game_over.wav',
        'tap.wav',
        'bgm.wav',
      ]);
      _initialized = true;
    } catch (e) {
      // Audio assets are optional; the game works without them.
      _initialized = false;
    }
  }

  bool get isEnabled => _storage.getSoundEnabled();

  Future<void> setEnabled(bool value) async {
    await _storage.setSoundEnabled(value);
    if (!value) {
      await stopBgm();
    }
  }

  void playCorrect() => _play('correct.wav');
  void playWrong() => _play('wrong.wav');
  void playTick() => _play('tick.wav');
  void playGameOver() => _play('game_over.wav');
  void playClick() => _play('tap.wav');

  Future<void> playBgm() async {
    if (!_initialized || !isEnabled) return;
    try {
      await FlameAudio.bgm.play('bgm.wav', volume: 0.35);
    } catch (_) {
      // Ignore missing audio asset.
    }
  }

  Future<void> stopBgm() async {
    if (!_initialized) return;
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {
      // Ignore if not playing.
    }
  }

  void _play(String file) {
    if (!_initialized || !isEnabled) return;
    try {
      FlameAudio.play(file, volume: 0.6);
    } catch (_) {
      // Ignore missing audio assets.
    }
  }
}
