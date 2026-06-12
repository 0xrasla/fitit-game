import 'dart:math' as math;

import 'package:flutter/material.dart';

enum ShapeKind { circle, square, diamond, hexagon, star, cross, flower, gear }

class ShapeDef {
  final ShapeKind kind;
  final int count;
  final List<Color> colors;
  final List<double> targetAngles;

  ShapeDef({
    required this.kind,
    required this.count,
    required this.colors,
    required this.targetAngles,
  });
}

final List<ShapeDef> levels = [
  ShapeDef(
    kind: ShapeKind.circle,
    count: 4,
    colors: const [Color(0xFFAED6F0), Color(0xFF82E0AA), Color(0xFFF7DC6F), Color(0xFFBB8FCE)],
    targetAngles: [0, math.pi / 2, math.pi, 3 * math.pi / 2],
  ),
  ShapeDef(
    kind: ShapeKind.square,
    count: 4,
    colors: const [Color(0xFFFFB3B3), Color(0xFFAED6F0), Color(0xFF82E0AA), Color(0xFFF7DC6F)],
    targetAngles: [0, math.pi / 2, math.pi, 3 * math.pi / 2],
  ),
  ShapeDef(
    kind: ShapeKind.diamond,
    count: 4,
    colors: const [Color(0xFFBB8FCE), Color(0xFFFFB3B3), Color(0xFFAED6F0), Color(0xFF82E0AA)],
    targetAngles: [math.pi / 4, 3 * math.pi / 4, 5 * math.pi / 4, 7 * math.pi / 4],
  ),
  ShapeDef(
    kind: ShapeKind.cross,
    count: 4,
    colors: const [Color(0xFF82E0AA), Color(0xFFAED6F0), Color(0xFFFFB3B3), Color(0xFFF7DC6F)],
    targetAngles: [math.pi / 4, 3 * math.pi / 4, 5 * math.pi / 4, 7 * math.pi / 4],
  ),
  ShapeDef(
    kind: ShapeKind.hexagon,
    count: 6,
    colors: const [
      Color(0xFFF7DC6F), Color(0xFFAED6F0), Color(0xFFBB8FCE),
      Color(0xFFFFB3B3), Color(0xFF82E0AA), Color(0xFFAED6F0),
    ],
    targetAngles: [0, math.pi / 3, 2 * math.pi / 3, math.pi, 4 * math.pi / 3, 5 * math.pi / 3],
  ),
  ShapeDef(
    kind: ShapeKind.star,
    count: 5,
    colors: const [Color(0xFFF7DC6F), Color(0xFFBB8FCE), Color(0xFFAED6F0), Color(0xFFFFB3B3), Color(0xFF82E0AA)],
    targetAngles: [0, 2 * math.pi / 5, 4 * math.pi / 5, 6 * math.pi / 5, 8 * math.pi / 5],
  ),
  ShapeDef(
    kind: ShapeKind.flower,
    count: 5,
    colors: const [Color(0xFFFFB3B3), Color(0xFFF7DC6F), Color(0xFFAED6F0), Color(0xFFBB8FCE), Color(0xFF82E0AA)],
    targetAngles: [0, 2 * math.pi / 5, 4 * math.pi / 5, 6 * math.pi / 5, 8 * math.pi / 5],
  ),
  ShapeDef(
    kind: ShapeKind.gear,
    count: 8,
    colors: const [
      Color(0xFFAED6F0), Color(0xFF82E0AA), Color(0xFFF7DC6F), Color(0xFFBB8FCE),
      Color(0xFFFFB3B3), Color(0xFFAED6F0), Color(0xFF82E0AA), Color(0xFFF7DC6F),
    ],
    targetAngles: [0, math.pi / 4, math.pi / 2, 3 * math.pi / 4, math.pi, 5 * math.pi / 4, 3 * math.pi / 2, 7 * math.pi / 4],
  ),
];
