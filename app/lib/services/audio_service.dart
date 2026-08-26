import 'package:flame_audio/flame_audio.dart';
import 'storage_service.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final StorageService _storage = StorageService();
  bool _initialized = false;
  final Map<String, AudioPool> _pools = {};

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

      // Pre-create reusable audio pools for high-frequency SFX to prevent
      // creating unmanaged AudioPlayer instances during rapid gameplay taps.
      _pools['tap.wav'] = await FlameAudio.createPool('tap.wav', minPlayers: 2, maxPlayers: 4);
      _pools['correct.wav'] = await FlameAudio.createPool('correct.wav', minPlayers: 2, maxPlayers: 4);
      _pools['wrong.wav'] = await FlameAudio.createPool('wrong.wav', minPlayers: 1, maxPlayers: 2);
      _pools['tick.wav'] = await FlameAudio.createPool('tick.wav', minPlayers: 1, maxPlayers: 2);
      _pools['game_over.wav'] = await FlameAudio.createPool('game_over.wav', minPlayers: 1, maxPlayers: 2);

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

  void playCorrect() => _play('correct.wav', volume: 0.7);
  void playWrong() => _play('wrong.wav', volume: 0.7);
  void playTick() => _play('tick.wav', volume: 0.5);
  void playGameOver() => _play('game_over.wav', volume: 0.8);
  void playClick() => _play('tap.wav', volume: 0.6);

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

  void _play(String file, {double volume = 0.6}) {
    if (!_initialized || !isEnabled) return;
    try {
      final pool = _pools[file];
      if (pool != null) {
        pool.start(volume: volume);
      } else {
        FlameAudio.play(file, volume: volume);
      }
    } catch (_) {
      // Ignore missing audio assets.
    }
  }

  void dispose() {
    for (final pool in _pools.values) {
      pool.dispose();
    }
    _pools.clear();
  }
}

