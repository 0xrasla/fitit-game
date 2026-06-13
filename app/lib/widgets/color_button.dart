import 'package:flutter/material.dart';
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
      duration: const Duration(milliseconds: 70),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
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
            color: widget.gameColor.color,
            borderRadius: BorderRadius.circular(widget.size * 0.25),
            boxShadow: [
              BoxShadow(
                color: widget.gameColor.color.withValues(alpha: 0.45),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.gameColor.displayLabel,
            style: TextStyle(
              color: _contrastingColor(widget.gameColor.color),
              fontWeight: FontWeight.w900,
              fontSize: widget.size * 0.22,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Color _contrastingColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}
