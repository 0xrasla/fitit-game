import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../audio/audio_manager.dart';
import '../models/shape_def.dart';
import '../persistence/high_score_store.dart';
import '../theme/app_theme.dart';
import 'components/hud_component.dart';
import 'components/rotating_piece.dart';
import 'components/silhouette_component.dart';

enum GamePhase { countdown, playing, levelComplete, gameOver }

class FititGame extends FlameGame with MultiTouchTapDetector {
  @override
  Color backgroundColor() => AppColors.background;
  int level = 0;
  int score = 0;
  late ShapeDef shapeDef;
  late List<bool> slots;
  double rotation = 0;
  double timeRemaining = 45;
  GamePhase phase = GamePhase.countdown;
  int countdownValue = 3;

  final List<RotatingPiece> _pieces = [];
  late HudComponent _hud;
  late SilhouetteComponent _silhouette;

  bool get allSlotsFilled => slots.every((s) => s);

  @override
  Future<void> onLoad() async {
    await AudioManager.load();

    _silhouette = SilhouetteComponent()
      ..size = Vector2(200, 200)
      ..anchor = Anchor.center
      ..position = Vector2(size.x / 2, size.y / 2 - 40);
    add(_silhouette);

    _hud = HudComponent();
    add(_hud);

    _loadLevel();
    _buildPieces();
  }

  void _loadLevel() {
    shapeDef = levels[level % levels.length];
    slots = List.filled(shapeDef.count, false);
    rotation = 0;
    timeRemaining = 45;
  }

  void _buildPieces() {
    for (final p in _pieces) {
      remove(p);
    }
    _pieces.clear();

    final n = shapeDef.count;
    final useTwoRows = n > 4;
    final row1 = (n + 1) ~/ 2;
    final row2 = n - row1;
    final rows = useTwoRows ? 2 : 1;
    final perRow = useTwoRows ? math.max(row1, row2) : n;
    final spacing = 70.0;
    final totalW = perRow * spacing;
    final startX = (size.x - totalW) / 2 + spacing / 2;
    final baseY = size.y - (rows == 1 ? 60.0 : 100.0);

    for (int i = 0; i < n; i++) {
      final row = useTwoRows ? (i < row1 ? 0 : 1) : 0;
      final col = useTwoRows ? (i < row1 ? i : i - row1) : i;
      final x = startX + col * spacing;
      final y = baseY + row * 80;

      final piece = RotatingPiece(index: i)
        ..size = Vector2(56, 56)
        ..anchor = Anchor.center
        ..position = Vector2(x, y);
      add(piece);
      _pieces.add(piece);
    }
  }

  void _rebuildForNewLevel() {
    _loadLevel();
    for (final p in _pieces) {
      remove(p);
    }
    _pieces.clear();
    _buildPieces();
  }

  void startGame() {
    score = 0;
    level = 0;
    countdownValue = 3;
    _countdownElapsed = 0;
    phase = GamePhase.countdown;
    AudioManager.playBgm();
    _rebuildForNewLevel();
    overlays.remove('MainMenu');
    overlays.remove('GameOver');
  }

  void goToMenu() {
    AudioManager.stopBgm();
    phase = GamePhase.gameOver;
    overlays.remove('Pause');
    overlays.remove('GameOver');
    overlays.remove('Settings');
    overlays.add('MainMenu');
  }

  void showSettings() {
    overlays.add('Settings');
  }

  void hideSettings() {
    overlays.remove('Settings');
  }

  void pause() {
    if (phase == GamePhase.playing) {
      phase = GamePhase.gameOver;
      overlays.add('Pause');
    }
  }

  void resume() {
    if (overlays.isActive('Pause')) {
      phase = GamePhase.playing;
      overlays.remove('Pause');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (overlays.isActive('MainMenu') || overlays.isActive('Settings')) return;

    if (phase == GamePhase.countdown) {
      if (countdownValue > 0) {
        _countdownElapsed += dt;
        final newVal = 3 - _countdownElapsed.floor();
        if (newVal != countdownValue && newVal >= 0) {
          countdownValue = newVal;
        }
        if (countdownValue <= 0) {
          countdownValue = -1;
          _countdownElapsed = 0;
          phase = GamePhase.playing;
        }
      }
    } else if (phase == GamePhase.playing) {
      rotation += dt * _rotationSpeed;
      timeRemaining -= dt;
      if (timeRemaining <= 10 && timeRemaining + dt > 10) {
        AudioManager.playTick();
      } else if (timeRemaining <= 0) {
        timeRemaining = 0;
        _gameOver();
      }
    } else if (phase == GamePhase.levelComplete) {
      _levelCompleteElapsed += dt;
      if (_levelCompleteElapsed >= 1.0) {
        _levelCompleteElapsed = 0;
        level++;
        _rebuildForNewLevel();
        phase = GamePhase.playing;
      }
    }
  }

  double get _rotationSpeed => 1.0 + level * 0.25;

  double _countdownElapsed = 0;
  double _levelCompleteElapsed = 0;

  bool isAligned(int idx) {
    final target = shapeDef.targetAngles[idx];
    final diff = (rotation - target).abs() % (2 * math.pi);
    final norm = diff > math.pi ? (2 * math.pi - diff) : diff;
    return norm < 0.15;
  }

  void tryPlace(int idx) {
    if (phase != GamePhase.playing) return;
    if (slots[idx]) return;

    if (isAligned(idx)) {
      slots[idx] = true;
      AudioManager.playCorrect();

      final piece = _pieces[idx];
      piece.add(
        ScaleEffect.by(
          Vector2.all(0.3),
          EffectController(duration: 0.15, alternate: true),
        ),
      );

      if (allSlotsFilled) {
        AudioManager.playLevelComplete();
        score += math.max(1, 10 - level);
        phase = GamePhase.levelComplete;
        _levelCompleteElapsed = 0;
        _silhouette.add(
          SequenceEffect([
            ScaleEffect.by(Vector2.all(1.2), EffectController(duration: 0.2)),
            ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.2)),
          ]),
        );
      }
    } else {
      AudioManager.playWrong();
      final piece = _pieces[idx];
      piece.add(
        SequenceEffect([
          MoveEffect.by(Vector2(-4, 0), EffectController(duration: 0.04)),
          MoveEffect.by(Vector2(8, 0), EffectController(duration: 0.04)),
          MoveEffect.by(Vector2(-8, 0), EffectController(duration: 0.04)),
          MoveEffect.by(Vector2(4, 0), EffectController(duration: 0.04)),
        ]),
      );
    }
  }

  void _gameOver() async {
    phase = GamePhase.gameOver;
    AudioManager.playGameOver();
    await HighScoreStore.save(score);
    overlays.add('GameOver');
  }

  @override
  void onTapDown(int pointerId, TapDownInfo info) {
    final pos = info.eventPosition.widget;

    if (pos.x < 40 && pos.y < 40) {
      if (phase == GamePhase.playing) {
        pause();
      }
      return;
    }

    if (phase == GamePhase.playing) {
      for (final piece in _pieces) {
        if (piece.containsPoint(pos)) {
          tryPlace(piece.index);
          return;
        }
      }
    }
  }
}
