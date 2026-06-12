import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../painters/silhouette_painter.dart';
import '../fitit_game.dart';

class SilhouetteComponent extends PositionComponent {
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final game = findGame() as FititGame;
    final painter = SilhouettePainter(shapeDef: game.shapeDef, slots: game.slots);
    painter.paint(canvas, size.toSize());
  }
}
