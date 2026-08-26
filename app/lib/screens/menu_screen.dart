import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/game_color.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import 'game_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  final AudioService _audio = AudioService();
  int _highScore = 0;
  bool _soundEnabled = true;
  late AnimationController _animController;
  Timer? _demoTimer;
  int _demoWordIndex = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _loadData();
    AdService().init();
    _demoTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!mounted) return;
      setState(() {
        _demoWordIndex = (_demoWordIndex + 1) % gameColors.length;
      });
    });
  }

  Future<void> _loadData() async {
    await _storage.init();
    await _audio.init();
    setState(() {
      _highScore = _storage.getHighScore();
      _soundEnabled = _storage.getSoundEnabled();
    });
    if (_soundEnabled) {
      await _audio.playBgm();
    }
  }

  Future<void> _startGame() async {
    _audio.playClick();
    await _audio.stopBgm();
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const GameScreen()));
    if (!mounted) return;
    await _audio.playBgm();
    _loadData();
  }

  void _toggleSound() async {
    _audio.playClick();
    final newValue = !_soundEnabled;
    await _audio.setEnabled(newValue);
    setState(() => _soundEnabled = newValue);
    if (newValue) {
      await _audio.playBgm();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _demoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // inkColor = the actual text ink color (what the player must tap)
    // wordColor = what the word label says (the distractor)
    final inkColor = gameColors[_demoWordIndex];
    final wordColor = gameColors[(_demoWordIndex + 2) % gameColors.length];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B18),
      body: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          return Stack(
            children: [
              // Layer 1: Game background texture image
              Positioned.fill(
                child: Image.asset(
                  'assets/game_bg.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              // Layer 2: Dynamic radial light beam
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.amberAccent.withValues(alpha: 0.15),
                        Colors.deepPurpleAccent.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      radius: 1.4,
                      focal: Alignment(
                        sin(_animController.value * pi * 2) * 0.35,
                        cos(_animController.value * pi * 2) * 0.35,
                      ),
                    ),
                  ),
                ),
              ),
              // Layer 3: Floating particle bubbles
              CustomPaint(
                painter: _BubblePainter(
                  progress: _animController.value,
                  colorValues: const [
                    Colors.amberAccent,
                    Colors.redAccent,
                    Colors.blueAccent,
                    Colors.greenAccent,
                    Colors.deepPurpleAccent,
                    Colors.orangeAccent,
                  ],
                ),
                size: size,
              ),
              // Layer 4: Main Menu Cards & Controls
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: size.height * 0.04,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildTitleBlock(size),
                        SizedBox(height: size.height * 0.04),
                        _buildDemoCard(wordColor, inkColor),
                        SizedBox(height: size.height * 0.03),
                        _buildHighScoreCard(),
                        SizedBox(height: size.height * 0.04),
                        _buildPlayButton(),
                        const SizedBox(height: 14),
                        _buildSoundToggle(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTitleBlock(Size size) {
    return Column(
      children: [
        Container(
          constraints: BoxConstraints(
            maxHeight: size.height * 0.22,
            maxWidth: size.width * 0.72,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.amberAccent.withValues(alpha: 0.18),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => FittedBox(
                fit: BoxFit.scaleDown,
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.rubik(
                      textStyle: TextStyle(
                        fontSize: size.width * 0.17,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: 2,
                      ),
                    ),
                    children: const [
                      TextSpan(
                        text: 'INK',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: 'STINCT',
                        style: TextStyle(color: Colors.amberAccent),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap the color of the text —\nnot the word itself!',
          textAlign: TextAlign.center,
          style: GoogleFonts.rubik(
            textStyle: const TextStyle(
              fontSize: 15,
              color: Colors.white54,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // wordColor = the label the word says (distractor)
  // inkColor  = the actual ink color (correct answer)
  Widget _buildDemoCard(GameColor wordColor, GameColor inkColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Column(
        children: [
          Text(
            'EXAMPLE ROUND',
            style: GoogleFonts.rubik(
              textStyle: const TextStyle(
                fontSize: 10,
                color: Colors.white30,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // The Stroop word: label says "wordColor.name" but is written in inkColor
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              wordColor.displayLabel,
              key: ValueKey(wordColor.name),
              style: GoogleFonts.rubik(
                textStyle: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  color: inkColor.color,
                  shadows: [
                    Shadow(
                      color: inkColor.color.withValues(alpha: 0.5),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDemoChoice(
                color: wordColor.color,
                label: 'WRONG',
                labelColor: Colors.redAccent.withValues(alpha: 0.7),
                isCorrect: false,
              ),
              const SizedBox(width: 28),
              _buildDemoChoice(
                color: inkColor.color,
                label: 'CORRECT',
                labelColor: Colors.greenAccent.withValues(alpha: 0.8),
                isCorrect: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemoChoice({
    required Color color,
    required String label,
    required Color labelColor,
    required bool isCorrect,
  }) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10),
            ],
            border: isCorrect
                ? Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.7),
                    width: 2,
                  )
                : null,
          ),
          child: isCorrect
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 26)
              : const Icon(
                  Icons.close_rounded,
                  color: Colors.white54,
                  size: 22,
                ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.rubik(
            textStyle: TextStyle(
              fontSize: 10,
              color: labelColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHighScoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.amberAccent.withValues(alpha: 0.06),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: 22,
                color: Colors.amberAccent.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 10),
              Text(
                'HIGH SCORE',
                style: GoogleFonts.rubik(
                  textStyle: const TextStyle(
                    fontSize: 14,
                    color: Colors.white38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: _highScore),
            duration: const Duration(milliseconds: 600),
            builder: (_, value, child) {
              return Text(
                '$value',
                style: GoogleFonts.rubik(
                  textStyle: const TextStyle(
                    fontSize: 38,
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    final glowIntensity = 18 + sin(_animController.value * pi * 2) * 8;

    return SizedBox(
      width: double.infinity,
      height: 66,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFD54F),
              Color(0xFFFFB300),
              Color(0xFFFF8F00),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amberAccent.withValues(alpha: 0.5),
              blurRadius: glowIntensity,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: ElevatedButton(
          onPressed: _startGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'PLAY NOW',
                style: GoogleFonts.rubik(
                  textStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.play_arrow_rounded,
                size: 32,
                color: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoundToggle() {
    return TextButton.icon(
      onPressed: _toggleSound,
      icon: Icon(
        _soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
        color: Colors.white38,
        size: 20,
      ),
      label: Text(
        _soundEnabled ? 'SOUND ON' : 'SOUND OFF',
        style: GoogleFonts.rubik(
          textStyle: const TextStyle(
            fontSize: 13,
            color: Colors.white38,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final double progress;
  final List<Color> colorValues;

  _BubblePainter({required this.progress, required this.colorValues});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rng = Random(0);

    for (int i = 0; i < 18; i++) {
      final x =
          (rng.nextDouble() * size.width) +
          sin(progress * pi * 2 + i * 1.7) * 20;
      final y =
          (rng.nextDouble() * size.height) +
          cos(progress * pi * 2 + i * 1.3) * 20;
      final radius = rng.nextDouble() * 28 + 6;
      final opacity = (sin(progress * pi * 2 + i * 0.9) + 1) / 2 * 0.12;

      paint.color = colorValues[i % colorValues.length].withValues(
        alpha: opacity,
      );
      canvas.drawCircle(Offset(x % size.width, y % size.height), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
