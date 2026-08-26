import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_color.dart';

class ColorButton extends StatefulWidget {
  final GameColor gameColor;
  final VoidCallback? onPressed;
  final double size;

  const ColorButton({
    super.key,
    required this.gameColor,
    required this.onPressed,
    this.size = 80,
  });

  @override
  State<ColorButton> createState() => _ColorButtonState();
}

class _ColorButtonState extends State<ColorButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed == null) return;
    _ctrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _ctrl.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final color = widget.gameColor.color;
    final textColor = _contrastingColor(color);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.size * 0.28),
            gradient: LinearGradient(
              colors: [
                Color.alphaBlend(Colors.white.withValues(alpha: 0.25), color),
                color,
                Color.alphaBlend(Colors.black.withValues(alpha: 0.20), color),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              // Outer neon aura glow
              BoxShadow(
                color: color.withValues(alpha: 0.55),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              // 3D Bottom depth shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Glossy top sheen highlight curve
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: widget.size * 0.38,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(widget.size * 0.26),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.35),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  widget.gameColor.displayLabel,
                  style: GoogleFonts.rubik(
                    textStyle: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: widget.size * 0.22,
                      letterSpacing: 1.0,
                      shadows: [
                        Shadow(
                          color: textColor == Colors.white
                              ? Colors.black.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _contrastingColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.45 ? Colors.black : Colors.white;
  }
}

