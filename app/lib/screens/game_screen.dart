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
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  bool _showingRewarded = false;
  bool _ready = false;
  bool _isCountingDown = false;
  int _countdownValue = 3;

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
    _initGame();
    _loadBannerAd();
  }

  Future<void> _initGame() async {
    _ticker = createTicker(_onTick);
    await _storage.init();
    _gameState = GameState.initial(_storage.getHighScore());
    _gameState.startGame();
    setState(() => _ready = true);
    await _startCountdown();
  }

  Future<void> _startCountdown() async {
    _ticker?.stop();
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
    _ticker?.start();
  }

  void _loadBannerAd() {
    _bannerAd = _adService.createBannerAd();
    _bannerAd?.load().then((_) {
      if (mounted) {
        setState(() => _isBannerLoaded = true);
      }
    });
  }

  void _onTick(Duration elapsed) {
    if (_gameState.status != GameStatus.playing) return;
    setState(() {
      _gameState.tick(1 / 60); // approximate delta for 60fps
    });

    if (_gameState.status == GameStatus.gameOver && !_showingRewarded) {
      _handleGameOver();
    }
  }

  Future<void> _handleAnswer(GameColor selected) async {
    if (_gameState.status != GameStatus.playing) return;

    _audio.playClick();
    final correct = _gameState.answer(selected);
    if (correct) {
      _audio.playCorrect();
      await _haptic(HapticFeedback.lightImpact);
    } else {
      _audio.playWrong();
      await _haptic(HapticFeedback.heavyImpact);
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'GAME OVER',
            textAlign: TextAlign.center,
            style: GoogleFonts.rubik(
              textStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 28,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Score: ${_gameState.score}',
                style: GoogleFonts.rubik(
                  textStyle: const TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Best: ${_gameState.highScore}',
                style: GoogleFonts.rubik(
                  textStyle: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            if (_gameState.canUseRewardedContinue())
              TextButton.icon(
                onPressed: _watchRewardedAdForContinue,
                icon: const Icon(Icons.play_circle_fill, color: Colors.greenAccent),
                label: Text(
                  'CONTINUE (+1 LIFE)',
                  style: GoogleFonts.rubik(
                    textStyle: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            TextButton(
              onPressed: _goToMenu,
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
            TextButton(
              onPressed: _restartGame,
              child: Text(
                'PLAY AGAIN',
                style: GoogleFonts.rubik(
                  textStyle: const TextStyle(
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
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
      },
      onDismissed: () {
        if (mounted) {
          setState(() => _showingRewarded = false);
          _ticker?.start();
        }
      },
    );
  }

  void _restartGame() {
    _audio.playClick();
    Navigator.of(context).pop();
    _gameState.startGame();
    setState(() {});
    _startCountdown();
  }

  void _goToMenu() {
    _audio.playClick();
    Navigator.of(context).pop();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MenuScreen()),
    );
  }

  Future<void> _haptic(VoidCallback feedback) async {
    if (_storage.getHapticsEnabled()) {
      feedback();
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 20);
      }
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _bannerAd?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final round = _ready ? _gameState.currentRound : null;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: !_ready
            ? const Center(child: CircularProgressIndicator(color: Colors.amberAccent))
            : Stack(
                children: [
                  Column(
                    children: [
                      _buildTopBar(),
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
                  if (_isCountingDown) _buildCountdownOverlay(),
                ],
              ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SCORE',
                style: GoogleFonts.rubik(
                  textStyle: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${_gameState.score}',
                style: GoogleFonts.rubik(
                  textStyle: const TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: List.generate(
              _gameState.lives,
              (_) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Icon(Icons.favorite, color: Colors.redAccent, size: 28),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'BEST',
                style: GoogleFonts.rubik(
                  textStyle: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${_gameState.highScore}',
                style: GoogleFonts.rubik(
                  textStyle: const TextStyle(
                    fontSize: 32,
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBar() {
    final progress = _gameState.maxTime > 0
        ? (_gameState.timeLeft / _gameState.maxTime).clamp(0.0, 1.0)
        : 0.0;
    final color = progress > 0.5
        ? Colors.greenAccent
        : progress > 0.25
            ? Colors.amberAccent
            : Colors.redAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 12,
          backgroundColor: Colors.white12,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }

  Widget _buildWordDisplay(RoundData round, Size size) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'TAP THE COLOR OF THIS TEXT',
            textAlign: TextAlign.center,
            style: GoogleFonts.rubik(
              textStyle: const TextStyle(
                fontSize: 14,
                color: Colors.white54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            round.text,
            style: GoogleFonts.rubik(
              textStyle: TextStyle(
                fontSize: size.width * 0.18,
                fontWeight: FontWeight.w900,
                color: round.inkColor.color,
                shadows: [
                  Shadow(
                    color: round.inkColor.color.withValues(alpha: 0.5),
                    blurRadius: 20,
                  ),
                ],
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
        color: Colors.black.withValues(alpha: 0.72),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'GET READY',
              style: GoogleFonts.rubik(
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.white38,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.elasticOut),
                ),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Text(
                label,
                key: ValueKey(label),
                style: GoogleFonts.rubik(
                  textStyle: TextStyle(
                    fontSize: isGo ? 72 : 110,
                    fontWeight: FontWeight.w900,
                    color: isGo ? Colors.amberAccent : Colors.white,
                    shadows: [
                      Shadow(
                        color: (isGo ? Colors.amberAccent : Colors.white)
                            .withValues(alpha: 0.4),
                        blurRadius: 32,
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
