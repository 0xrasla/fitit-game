import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/shape_def.dart';

class SilhouettePainter extends CustomPainter {
  final ShapeDef shapeDef;
  final List<bool> slots;

  SilhouettePainter({required this.shapeDef, required this.slots});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = 85.0;
    final n = shapeDef.count;

    for (int i = 0; i < n; i++) {
      if (slots[i]) {
        final fillPaint = Paint()
          ..color = shapeDef.colors[i % shapeDef.colors.length].withAlpha(180)
          ..style = PaintingStyle.fill;
        _drawPiecePath(canvas, c, r, shapeDef.kind, i, n, fillPaint);
      }
    }

    final outline = Paint()
      ..color = const Color(0xFF566573).withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    _drawOutline(canvas, c, r, shapeDef.kind, outline);

    final div = Paint()
      ..color = const Color(0xFF566573).withAlpha(50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (int i = 0; i < n; i++) {
      final a = shapeDef.targetAngles[i];
      canvas.drawLine(c, c + Offset(r * math.cos(a), r * math.sin(a)), div);
    }

    if (slots.every((s) => s)) {
      final glow = Paint()
        ..color = const Color(0xFF82E0AA).withAlpha(180)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      _drawOutline(canvas, c, r + 4, shapeDef.kind, glow);
    }
  }

  void _drawPiecePath(Canvas canvas, Offset c, double r, ShapeKind kind, int i, int n, Paint paint) {
    final sweep = 2 * math.pi / n;
    final start = shapeDef.targetAngles[i];
    final mid = start + sweep / 2;
    final end = start + sweep;

    Offset pt(double a, double s) => c + Offset(s * math.cos(a), s * math.sin(a));

    switch (kind) {
      case ShapeKind.circle:
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, sweep, true, paint);
      case ShapeKind.square:
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy)
            ..lineTo(pt(start, r).dx, pt(start, r).dy)
            ..lineTo(pt(end, r).dx, pt(end, r).dy)
            ..close(),
          paint,
        );
      case ShapeKind.diamond:
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy)
            ..lineTo(pt(start, r).dx, pt(start, r).dy)
            ..lineTo(pt(mid, r * 0.5).dx, pt(mid, r * 0.5).dy)
            ..close(),
          paint,
        );
      case ShapeKind.hexagon:
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy)
            ..lineTo(pt(start, r).dx, pt(start, r).dy)
            ..lineTo(pt(mid, r).dx, pt(mid, r).dy)
            ..lineTo(pt(end, r).dx, pt(end, r).dy)
            ..close(),
          paint,
        );
      case ShapeKind.star:
        canvas.drawOval(Rect.fromCircle(center: pt(mid, r * 0.55), radius: r * 0.28), paint);
      case ShapeKind.cross:
        final a = start + sweep * 0.15;
        final b = start + sweep * 0.35;
        final c2 = start + sweep * 0.65;
        final d = start + sweep * 0.85;
        canvas.drawPath(
          Path()
            ..moveTo(pt(a, r).dx, pt(a, r).dy)
            ..lineTo(pt(b, r).dx, pt(b, r).dy)
            ..lineTo(pt(b, r * 0.4).dx, pt(b, r * 0.4).dy)
            ..lineTo(pt(c2, r * 0.4).dx, pt(c2, r * 0.4).dy)
            ..lineTo(pt(c2, r).dx, pt(c2, r).dy)
            ..lineTo(pt(d, r).dx, pt(d, r).dy)
            ..lineTo(pt(d, r * 0.4).dx, pt(d, r * 0.4).dy)
            ..lineTo(pt(end, r * 0.4).dx, pt(end, r * 0.4).dy)
            ..close(),
          paint,
        );
      case ShapeKind.flower:
        canvas.drawOval(Rect.fromCircle(center: pt(mid, r * 0.5), radius: r * 0.32), paint);
        canvas.drawOval(Rect.fromCircle(center: pt(mid - sweep * 0.2, r * 0.35), radius: r * 0.15), paint);
        canvas.drawOval(Rect.fromCircle(center: pt(mid + sweep * 0.2, r * 0.35), radius: r * 0.15), paint);
      case ShapeKind.gear:
        final a = start + sweep * 0.1;
        final b = start + sweep * 0.3;
        final c2 = start + sweep * 0.5;
        final d = start + sweep * 0.7;
        final e = start + sweep * 0.9;
        canvas.drawPath(
          Path()
            ..moveTo(pt(start, r).dx, pt(start, r).dy)
            ..lineTo(pt(a, r * 0.5).dx, pt(a, r * 0.5).dy)
            ..lineTo(pt(b, r).dx, pt(b, r).dy)
            ..lineTo(pt(c2, r * 0.5).dx, pt(c2, r * 0.5).dy)
            ..lineTo(pt(d, r).dx, pt(d, r).dy)
            ..lineTo(pt(e, r * 0.5).dx, pt(e, r * 0.5).dy)
            ..lineTo(pt(end, r).dx, pt(end, r).dy)
            ..close(),
          paint,
        );
    }
  }

  void _drawOutline(Canvas canvas, Offset c, double r, ShapeKind kind, Paint paint) {
    switch (kind) {
      case ShapeKind.circle:
        canvas.drawCircle(c, r, paint);
      case ShapeKind.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: c, width: r * 1.8, height: r * 1.8),
            const Radius.circular(8),
          ),
          paint,
        );
      case ShapeKind.diamond:
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy - r)
            ..lineTo(c.dx + r, c.dy)
            ..lineTo(c.dx, c.dy + r)
            ..lineTo(c.dx - r, c.dy)
            ..close(),
          paint,
        );
      case ShapeKind.hexagon:
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final a = i * math.pi / 3 - math.pi / 6;
          final p = c + Offset(r * math.cos(a), r * math.sin(a));
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path..close(), paint);
      case ShapeKind.star:
        final path = Path();
        for (int i = 0; i < 10; i++) {
          final a = i * math.pi / 5 - math.pi / 2;
          final rr = i.isEven ? r : r * 0.45;
          final p = c + Offset(rr * math.cos(a), rr * math.sin(a));
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path..close(), paint);
      case ShapeKind.cross:
        final hw = r * 0.4;
        final arm = r * 0.4;
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - arm, c.dy - hw)
            ..lineTo(c.dx - arm, c.dy - arm)
            ..lineTo(c.dx - hw, c.dy - arm)
            ..lineTo(c.dx - hw, c.dy + arm)
            ..lineTo(c.dx - arm, c.dy + arm)
            ..lineTo(c.dx - arm, c.dy + hw)
            ..lineTo(c.dx + arm, c.dy + hw)
            ..lineTo(c.dx + arm, c.dy + arm)
            ..lineTo(c.dx + hw, c.dy + arm)
            ..lineTo(c.dx + hw, c.dy - arm)
            ..lineTo(c.dx + arm, c.dy - arm)
            ..lineTo(c.dx + arm, c.dy - hw)
            ..close(),
          paint,
        );
      case ShapeKind.flower:
        for (int i = 0; i < 5; i++) {
          final a = i * 2 * math.pi / 5 - math.pi / 2;
          canvas.drawCircle(c + Offset(r * 0.5 * math.cos(a), r * 0.5 * math.sin(a)), r * 0.35, paint);
        }
      case ShapeKind.gear:
        final path = Path();
        for (int i = 0; i < 16; i++) {
          final a = i * 2 * math.pi / 16;
          final rr = i.isEven ? r : r * 0.75;
          final p = c + Offset(rr * math.cos(a), rr * math.sin(a));
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path..close(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant SilhouettePainter old) => old.slots != slots;
}
