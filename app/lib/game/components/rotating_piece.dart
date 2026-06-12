import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../fitit_game.dart';

class RotatingPiece extends PositionComponent {
  final int index;

  RotatingPiece({required this.index});

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final game = findGame() as FititGame;

    if (index >= game.shapeDef.count) return;

    final aligned = game.isAligned(index);
    final collected = game.slots[index];
    final color = game.shapeDef.colors[index % game.shapeDef.colors.length];

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(game.rotation);

    final r = Rect.fromCenter(
      center: Offset.zero,
      width: size.x - 4,
      height: size.y - 4,
    );

    final fillPaint = Paint()
      ..color = collected ? color.withAlpha(60) : color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(10)),
      fillPaint,
    );

    if (aligned && !collected) {
      final glowPaint = Paint()
        ..color = Colors.greenAccent.withAlpha(80)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(10)),
        glowPaint,
      );

      final borderPaint = Paint()
        ..color = Colors.greenAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(10)),
        borderPaint,
      );
    }

    if (collected) {
      final checkPaint = Paint()
        ..color = Colors.greenAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(-8, 0)
        ..lineTo(-2, 6)
        ..lineTo(10, -6);
      canvas.drawPath(path, checkPaint);
    }

    canvas.restore();
  }
}
