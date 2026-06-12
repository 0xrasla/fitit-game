import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../fitit_game.dart';

const _topPad = 44.0;
const _homeSize = 22.0;
const _homeCx = 24.0;
const _homeCy = _topPad;

class HudComponent extends PositionComponent with HasGameReference<FititGame> {
  late TextComponent _scoreText;
  late TextComponent _timerText;
  late TextComponent _timerLabel;
  late TextComponent _countdownText;

  HudComponent() {
    priority = 10;
  }

  @override
  Future<void> onLoad() async {
    final cx = game.size.x / 2;

    _scoreText = TextComponent(
      text: 'SCORE: 0',
      textRenderer: TextPaint(
        style: GoogleFonts.orbitron(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      anchor: Anchor.topRight,
      position: Vector2(game.size.x - 16, _topPad - 8),
    );
    add(_scoreText);

    _timerText = TextComponent(
      text: '45',
      textRenderer: TextPaint(
        style: GoogleFonts.orbitron(
          fontSize: 56,
          fontWeight: FontWeight.w300,
          color: AppColors.textPrimary,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(cx, 76),
    );
    add(_timerText);

    _timerLabel = TextComponent(
      text: 'TIME LEFT',
      textRenderer: TextPaint(
        style: GoogleFonts.orbitron(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 4,
          color: AppColors.textHint,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(cx, 118),
    );
    add(_timerLabel);

    _countdownText = TextComponent(
      text: '3',
      textRenderer: TextPaint(
        style: GoogleFonts.orbitron(
          fontSize: 80,
          fontWeight: FontWeight.w300,
          color: AppColors.textPrimary,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(cx, game.size.y / 2 - 40),
    );
    add(_countdownText);
  }

  @override
  void render(Canvas canvas) {
    final g = game;

    if (g.phase == GamePhase.playing) {
      _drawHomeIcon(canvas);
    }

    if (g.phase == GamePhase.countdown) {
      _countdownText.text = g.countdownValue > 0 ? '${g.countdownValue}' : 'GO!';
      _countdownText.textRenderer = TextPaint(
        style: GoogleFonts.orbitron(
          fontSize: 80,
          fontWeight: FontWeight.w300,
          color: g.countdownValue > 0 ? AppColors.textPrimary : AppColors.success,
        ),
      );
      _countdownText.render(canvas);
      return;
    }

    if (g.phase == GamePhase.playing || g.phase == GamePhase.levelComplete) {
      _scoreText.text = 'SCORE: ${g.score}';
      _scoreText.render(canvas);

      final seconds = g.timeRemaining.ceil();
      final ratio = (g.timeRemaining / 45).clamp(0.0, 1.0);
      final isLow = ratio <= 0.25;

      _timerText.text = seconds.toString().padLeft(2, '0');
      _timerText.textRenderer = TextPaint(
        style: GoogleFonts.orbitron(
          fontSize: 56,
          fontWeight: FontWeight.w300,
          color: isLow ? Colors.redAccent : AppColors.textPrimary,
        ),
      );
      _timerText.render(canvas);

      _timerLabel.textRenderer = TextPaint(
        style: GoogleFonts.orbitron(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 4,
          color: isLow ? Colors.redAccent : AppColors.textHint,
        ),
      );
      _timerLabel.render(canvas);
    }
  }

  void _drawHomeIcon(Canvas canvas) {
    final paint = Paint()..color = AppColors.textPrimary;
    final half = _homeSize / 2;
    final cx = _homeCx;
    final cy = _homeCy;

    final roof = Path()
      ..moveTo(cx, cy - half)
      ..lineTo(cx - half, cy + 2)
      ..lineTo(cx + half, cy + 2)
      ..close();
    canvas.drawPath(roof, paint);

    final bodyRect = Rect.fromCenter(
      center: Offset(cx, cy + 4),
      width: 14,
      height: 12,
    );
    canvas.drawRect(bodyRect, paint);

    final doorRect = Rect.fromCenter(
      center: Offset(cx, cy + 8),
      width: 5,
      height: 7,
    );
    canvas.drawRect(doorRect, Paint()..color = AppColors.background);
  }
}
