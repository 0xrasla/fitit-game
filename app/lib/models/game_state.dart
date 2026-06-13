import 'dart:math';
import 'game_color.dart';

enum GameStatus { idle, playing, gameOver, watchingRewardAd }

class RoundData {
  final GameColor inkColor;
  final GameColor textColor;
  final String text;
  final List<GameColor> options;

  const RoundData({
    required this.inkColor,
    required this.textColor,
    required this.text,
    required this.options,
  });
}

class GameState {
  GameStatus status;
  int score;
  int highScore;
  int lives;
  RoundData? currentRound;
  double timeLeft;
  double maxTime;
  int roundNumber;
  int streak;
  int rewardedContinuesUsed;

  GameState({
    this.status = GameStatus.idle,
    this.score = 0,
    this.highScore = 0,
    this.lives = 3,
    this.currentRound,
    this.timeLeft = 0,
    this.maxTime = 0,
    this.roundNumber = 0,
    this.streak = 0,
    this.rewardedContinuesUsed = 0,
  });

  GameState copyWith({
    GameStatus? status,
    int? score,
    int? highScore,
    int? lives,
    RoundData? currentRound,
    double? timeLeft,
    double? maxTime,
    int? roundNumber,
    int? streak,
    int? rewardedContinuesUsed,
  }) {
    return GameState(
      status: status ?? this.status,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
      lives: lives ?? this.lives,
      currentRound: currentRound ?? this.currentRound,
      timeLeft: timeLeft ?? this.timeLeft,
      maxTime: maxTime ?? this.maxTime,
      roundNumber: roundNumber ?? this.roundNumber,
      streak: streak ?? this.streak,
      rewardedContinuesUsed: rewardedContinuesUsed ?? this.rewardedContinuesUsed,
    );
  }

  static final Random _random = Random();

  factory GameState.initial(int highScore) {
    return GameState(highScore: highScore);
  }

  void startGame() {
    score = 0;
    lives = 3;
    roundNumber = 0;
    streak = 0;
    rewardedContinuesUsed = 0;
    status = GameStatus.playing;
    nextRound();
  }

  void nextRound() {
    roundNumber++;
    streak = 0;
    maxTime = _calculateRoundTime();
    timeLeft = maxTime;
    currentRound = _generateRound();
  }

  double _calculateRoundTime() {
    // Start with 3.0 seconds and decrease as score grows, minimum 1.2 seconds.
    final base = 3.0 - (score * 0.04);
    return base.clamp(1.2, 3.0);
  }

  RoundData _generateRound() {
    final available = List<GameColor>.from(gameColors)..shuffle(_random);
    final inkColor = available.first;
    // 70% chance the text word does NOT match the ink color (Stroop effect).
    GameColor textColor;
    if (available.length > 1 && _random.nextDouble() < 0.7) {
      textColor = available.skip(1).firstWhere(
            (c) => c.name != inkColor.name,
            orElse: () => available[1],
          );
    } else {
      textColor = inkColor;
    }

    // Generate 4 options including the correct ink color.
    final options = _randomSample(available, 4, inkColor);
    options.shuffle(_random);

    return RoundData(
      inkColor: inkColor,
      textColor: textColor,
      text: textColor.displayLabel,
      options: options,
    );
  }

  List<GameColor> _randomSample(List<GameColor> source, int count, GameColor mustInclude) {
    final pool = List<GameColor>.from(source);
    pool.shuffle(_random);
    final result = pool.take(count).toList();
    if (!result.any((c) => c.name == mustInclude.name)) {
      result[_random.nextInt(result.length)] = mustInclude;
    }
    return result;
  }

  bool answer(GameColor selected) {
    if (status != GameStatus.playing || currentRound == null) return false;

    final correct = selected.name == currentRound!.inkColor.name;
    if (correct) {
      score++;
      streak++;
      if (score > highScore) {
        highScore = score;
      }
      // Bonus life every 15 correct answers.
      if (score % 15 == 0) {
        lives = (lives + 1).clamp(0, 5);
      }
      nextRound();
    } else {
      lives--;
      streak = 0;
      if (lives <= 0) {
        status = GameStatus.gameOver;
      } else {
        nextRound();
      }
    }
    return correct;
  }

  void tick(double delta) {
    if (status != GameStatus.playing) return;
    timeLeft -= delta;
    if (timeLeft <= 0) {
      timeLeft = 0;
      lives--;
      streak = 0;
      if (lives <= 0) {
        status = GameStatus.gameOver;
      } else {
        nextRound();
      }
    }
  }

  bool canUseRewardedContinue() => rewardedContinuesUsed < 1;

  void useRewardedContinue() {
    rewardedContinuesUsed++;
    lives = 1;
    status = GameStatus.playing;
    nextRound();
  }
}
