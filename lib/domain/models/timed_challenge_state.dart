/// Represents the state of a timed challenge session.
///
/// Tracks puzzles solved, timing, streaks, and whether the challenge
/// is currently active or has ended (time ran out).
class TimedChallengeState {
  final int puzzlesSolved;
  final int totalTimeMs;
  final int timeRemainingMs;
  final int currentStreak;
  final bool isActive;
  final bool isGameOver;
  final List<int> solveTimes;
  final int bestStreak;
  final int score;

  const TimedChallengeState({
    this.puzzlesSolved = 0,
    this.totalTimeMs = 0,
    this.timeRemainingMs = 0,
    this.currentStreak = 0,
    this.isActive = false,
    this.isGameOver = false,
    this.solveTimes = const [],
    this.bestStreak = 0,
    this.score = 0,
  });

  /// The initial state before a challenge has started.
  const TimedChallengeState.initial()
    : puzzlesSolved = 0,
      totalTimeMs = 0,
      timeRemainingMs = 0,
      currentStreak = 0,
      isActive = false,
      isGameOver = false,
      solveTimes = const [],
      bestStreak = 0,
      score = 0;

  /// Average solve time in milliseconds across all solved puzzles.
  double get averageSolveTime {
    if (solveTimes.isEmpty) return 0;
    final total = solveTimes.fold<int>(0, (sum, t) => sum + t);
    return total / solveTimes.length;
  }

  /// Creates a copy with optional updated fields.
  TimedChallengeState copyWith({
    int? puzzlesSolved,
    int? totalTimeMs,
    int? timeRemainingMs,
    int? currentStreak,
    bool? isActive,
    bool? isGameOver,
    List<int>? solveTimes,
    int? bestStreak,
    int? score,
  }) {
    return TimedChallengeState(
      puzzlesSolved: puzzlesSolved ?? this.puzzlesSolved,
      totalTimeMs: totalTimeMs ?? this.totalTimeMs,
      timeRemainingMs: timeRemainingMs ?? this.timeRemainingMs,
      currentStreak: currentStreak ?? this.currentStreak,
      isActive: isActive ?? this.isActive,
      isGameOver: isGameOver ?? this.isGameOver,
      solveTimes: solveTimes ?? this.solveTimes,
      bestStreak: bestStreak ?? this.bestStreak,
      score: score ?? this.score,
    );
  }

  /// Serializes the state to JSON.
  Map<String, dynamic> toJson() {
    return {
      'puzzlesSolved': puzzlesSolved,
      'totalTimeMs': totalTimeMs,
      'timeRemainingMs': timeRemainingMs,
      'currentStreak': currentStreak,
      'isActive': isActive,
      'isGameOver': isGameOver,
      'solveTimes': solveTimes,
      'bestStreak': bestStreak,
      'score': score,
    };
  }

  /// Creates a TimedChallengeState from JSON data.
  factory TimedChallengeState.fromJson(Map<String, dynamic> json) {
    return TimedChallengeState(
      puzzlesSolved: json['puzzlesSolved'] as int? ?? 0,
      totalTimeMs: json['totalTimeMs'] as int? ?? 0,
      timeRemainingMs: json['timeRemainingMs'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? false,
      isGameOver: json['isGameOver'] as bool? ?? false,
      solveTimes: (json['solveTimes'] as List?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
      bestStreak: json['bestStreak'] as int? ?? 0,
      score: json['score'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    final status = isGameOver
        ? 'game-over'
        : isActive
            ? 'active'
            : 'inactive';
    return 'TimedChallengeState('
        '$status, solved: $puzzlesSolved, '
        'remaining: ${timeRemainingMs}ms, '
        'streak: $currentStreak, score: $score)';
  }
}
