import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:vibration/vibration.dart';

import '../models/game_color.dart';
import '../models/game_state.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../widgets/color_button.dart';
import 'menu_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  GameState _gameState = GameState();
  Ticker? _ticker;
  Duration _lastTickElapsed = Duration.zero;
  final ValueNotifier<double> _timerProgressNotifier = ValueNotifier<double>(
    1.0,
  );

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  bool _showingRewarded = false;
  bool _ready = false;
  bool _isCountingDown = false;
  int _countdownValue = 3;
  bool _hasVibrator = false;

  final StorageService _storage = StorageService();
  final AudioService _audio = AudioService();
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _checkVibrator();
    _initGame();
    _loadBannerAd();
  }

  Future<void> _checkVibrator() async {
    try {
      final hasVibe = await Vibration.hasVibrator();
      if (mounted) {
        _hasVibrator = hasVibe ?? false;
      }
    } catch (_) {}
  }

  Future<void> _initGame() async {
    _ticker = createTicker(_onTick);
    await _storage.init();
    _gameState = GameState.initial(_storage.getHighScore());
    _gameState.startGame();
    _timerProgressNotifier.value = 1.0;
    setState(() => _ready = true);
    await _startCountdown();
  }

  Future<void> _startCountdown() async {
    _ticker?.stop();
    _lastTickElapsed = Duration.zero;
    _timerProgressNotifier.value = 1.0;
    setState(() {
      _isCountingDown = true;
      _countdownValue = 3;
    });

    for (int i = 3; i >= 1; i--) {
      if (!mounted) return;
      setState(() => _countdownValue = i);
      _audio.playTick();
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!mounted) return;
    setState(() => _countdownValue = 0); // signals "GO!"
    _audio.playClick();
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() => _isCountingDown = false);
    _lastTickElapsed = Duration.zero;
    _ticker?.start();
  }

  Future<void> _loadBannerAd() async {
    await _adService.init();
    if (!mounted) return;
    final banner = _adService.createBannerAd(
      onLoaded: () {
        if (mounted) setState(() => _isBannerLoaded = true);
      },
      onFailed: () {
        if (mounted) {
          setState(() {
            _isBannerLoaded = false;
            _bannerAd = null;
          });
        }
      },
    );
    if (banner != null) {
      setState(() => _bannerAd = banner);
    }
  }

  void _onTick(Duration elapsed) {
    if (_gameState.status != GameStatus.playing) return;

    // Calculate real elapsed delta between frames to ensure consistent timing
    // regardless of screen refresh rate (60Hz, 90Hz, 120Hz).
    final double delta;
    if (_lastTickElapsed == Duration.zero) {
      delta = 1 / 60;
    } else {
      delta = (elapsed - _lastTickElapsed).inMicroseconds / 1000000.0;
    }
    _lastTickElapsed = elapsed;

    _gameState.tick(delta);

    // Isolate high-frequency timer bar updates to ValueNotifier to avoid
    // rebuilding the entire widget tree (GoogleFonts, buttons, shadows) every frame.
    final progress = _gameState.maxTime > 0
        ? (_gameState.timeLeft / _gameState.maxTime).clamp(0.0, 1.0)
        : 0.0;
    _timerProgressNotifier.value = progress;

    if (_gameState.status == GameStatus.gameOver && !_showingRewarded) {
      _handleGameOver();
    }
  }

  Future<void> _handleAnswer(GameColor selected) async {
    if (_gameState.status != GameStatus.playing) return;

    _audio.playClick();
    final correct = _gameState.answer(selected);
    _timerProgressNotifier.value = 1.0;
    _lastTickElapsed = Duration.zero;

    if (correct) {
      _audio.playCorrect();
      _haptic(HapticFeedback.lightImpact);
    } else {
      _audio.playWrong();
      _haptic(HapticFeedback.heavyImpact);
    }

    if (_gameState.status == GameStatus.gameOver && !_showingRewarded) {
      await _handleGameOver();
    }
    setState(() {});
  }

  Future<void> _handleGameOver() async {
    _ticker?.stop();
    _audio.playGameOver();
    await _storage.setHighScore(_gameState.highScore);
    await _storage.incrementGamesPlayed();

    // Show interstitial ad every 3 games.
    if (_storage.getGamesPlayed() % 3 == 0) {
      await _adService.showInterstitial();
    }

    if (!mounted) return;
    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    final isNewHighScore =
        _gameState.score > 0 && _gameState.score >= _gameState.highScore;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/trophy.png',
                  height: 120,
                  width: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.emoji_events_rounded,
                    size: 80,
                    color: Colors.amberAccent,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isNewHighScore ? 'NEW HIGH SCORE!' : 'GAME OVER',
                textAlign: TextAlign.center,
                style: GoogleFonts.rubik(
                  textStyle: TextStyle(
                    color: isNewHighScore ? Colors.amberAccent : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          'SCORE',
                          style: GoogleFonts.rubik(
                            textStyle: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_gameState.score}',
                          style: GoogleFonts.rubik(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(height: 36, width: 1, color: Colors.white12),
                    Column(
                      children: [
                        Text(
                          'BEST',
                          style: GoogleFonts.rubik(
                            textStyle: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_gameState.highScore}',
                          style: GoogleFonts.rubik(
                            textStyle: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          actions: [
            Column(
              children: [
                if (_gameState.canUseRewardedContinue())
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _watchRewardedAdForContinue,
                        icon: const Icon(
                          Icons.play_circle_fill,
                          color: Colors.black,
                        ),
                        label: Text(
                          'CONTINUE (+1 LIFE)',
                          style: GoogleFonts.rubik(
                            textStyle: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _goToMenu,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'MENU',
                          style: GoogleFonts.rubik(
                            textStyle: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _restartGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amberAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'PLAY AGAIN',
                          style: GoogleFonts.rubik(
                            textStyle: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _watchRewardedAdForContinue() async {
    _audio.playClick();
    Navigator.of(context).pop();
    setState(() => _showingRewarded = true);

    await _adService.showRewarded(
      onRewarded: () {
        _gameState.useRewardedContinue();
        _timerProgressNotifier.value = 1.0;
        _lastTickElapsed = Duration.zero;
      },
      onDismissed: () {
        if (mounted) {
          setState(() => _showingRewarded = false);
          _lastTickElapsed = Duration.zero;
          _ticker?.start();
        }
      },
    );
  }

  void _restartGame() {
    _audio.playClick();
    Navigator.of(context).pop();
    _gameState.startGame();
    _timerProgressNotifier.value = 1.0;
    _lastTickElapsed = Duration.zero;
    setState(() {});
    _startCountdown();
  }

  void _goToMenu() {
    _audio.playClick();
    Navigator.of(context).pop();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MenuScreen()));
  }

  void _haptic(VoidCallback feedback) {
    if (_storage.getHapticsEnabled()) {
      feedback();
      if (_hasVibrator) {
        Vibration.vibrate(duration: 20);
      }
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _timerProgressNotifier.dispose();
    _bannerAd?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final round = _ready ? _gameState.currentRound : null;
    final activeColor = round?.inkColor.color ?? Colors.transparent;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B18),
      body: !_ready
          ? const Center(child: CircularProgressIndicator(color: Colors.amberAccent))
          : Stack(
              children: [
                // Layer 1: Game background texture image
                Positioned.fill(
                  child: Image.asset(
                    'assets/game_bg.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                // Layer 2: Dynamic ambient color glow responding to current ink color
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          activeColor.withValues(alpha: 0.28),
                          activeColor.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.70),
                        ],
                        radius: 1.2,
                        center: Alignment.center,
                      ),
                    ),
                  ),
                ),
                // Layer 3: Main interactive UI layout
                SafeArea(
                  child: Column(
                    children: [
                      _buildTopBar(),
                      if (_gameState.streak >= 2) _buildStreakBadge(),
                      const SizedBox(height: 8),
                      _buildTimerBar(),
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: round == null
                              ? const CircularProgressIndicator(color: Colors.amberAccent)
                              : _buildWordDisplay(round, size),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: round == null
                              ? const SizedBox.shrink()
                              : _buildButtonsGrid(round, size),
                        ),
                      ),
                      if (_isBannerLoaded && _bannerAd != null)
                        SizedBox(
                          width: _bannerAd!.size.width.toDouble(),
                          height: _bannerAd!.size.height.toDouble(),
                          child: AdWidget(ad: _bannerAd!),
                        ),
                    ],
                  ),
                ),
                if (_isCountingDown) _buildCountdownOverlay(),
              ],
            ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Glassmorphic Score Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SCORE',
                  style: GoogleFonts.rubik(
                    textStyle: const TextStyle(
                      fontSize: 10,
                      color: Colors.white54,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Text(
                  '${_gameState.score}',
                  style: GoogleFonts.rubik(
                    textStyle: const TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Lives Indicators
          Row(
            children: List.generate(
              5,
              (index) {
                final hasLife = index < _gameState.lives;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(
                    hasLife ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: hasLife ? Colors.redAccent : Colors.white24,
                    size: 26,
                  ),
                );
              },
            ),
          ),
          // Glassmorphic Best Score Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.amberAccent.withValues(alpha: 0.1),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'BEST',
                  style: GoogleFonts.rubik(
                    textStyle: const TextStyle(
                      fontSize: 10,
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Text(
                  '${_gameState.highScore}',
                  style: GoogleFonts.rubik(
                    textStyle: const TextStyle(
                      fontSize: 26,
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBadge() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orangeAccent, Colors.redAccent],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withValues(alpha: 0.5),
            blurRadius: 12,
          ),
        ],
      ),
      child: Text(
        '🔥 ${_gameState.streak} STREAK!',
        style: GoogleFonts.rubik(
          textStyle: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildTimerBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 14,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.black.withValues(alpha: 0.5),
          border: Border.all(color: Colors.white12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: ValueListenableBuilder<double>(
            valueListenable: _timerProgressNotifier,
            builder: (context, progress, _) {
              final color = progress > 0.5
                  ? Colors.cyanAccent
                  : progress > 0.25
                      ? Colors.amberAccent
                      : Colors.pinkAccent;

              return LinearProgressIndicator(
                value: progress,
                minHeight: 14,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWordDisplay(RoundData round, Size size) {
    final inkColor = round.inkColor.color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size.width * 0.86,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: inkColor.withValues(alpha: 0.6),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: inkColor.withValues(alpha: 0.35),
            blurRadius: 30,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'TAP THE COLOR OF THIS TEXT',
              textAlign: TextAlign.center,
              style: GoogleFonts.rubik(
                textStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              round.text,
              style: GoogleFonts.rubik(
                textStyle: TextStyle(
                  fontSize: size.width * 0.19,
                  fontWeight: FontWeight.w900,
                  color: inkColor,
                  shadows: [
                    Shadow(
                      color: inkColor.withValues(alpha: 0.7),
                      blurRadius: 26,
                    ),
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonsGrid(RoundData round, Size size) {
    final buttonSize = size.width * 0.36;
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      alignment: WrapAlignment.center,
      children: round.options
          .map(
            (color) => ColorButton(
              key: ValueKey(color.name),
              gameColor: color,
              size: buttonSize,
              onPressed: _isCountingDown ? null : () => _handleAnswer(color),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCountdownOverlay() {
    final label = _countdownValue > 0 ? '$_countdownValue' : 'GO!';
    final isGo = _countdownValue == 0;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.78),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'GET READY',
              style: GoogleFonts.rubik(
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.white54,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: Tween<double>(begin: 0.4, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.elasticOut),
                ),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Text(
                label,
                key: ValueKey(label),
                style: GoogleFonts.rubik(
                  textStyle: TextStyle(
                    fontSize: isGo ? 80 : 120,
                    fontWeight: FontWeight.w900,
                    color: isGo ? Colors.amberAccent : Colors.white,
                    shadows: [
                      Shadow(
                        color: (isGo ? Colors.amberAccent : Colors.white)
                            .withValues(alpha: 0.6),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

