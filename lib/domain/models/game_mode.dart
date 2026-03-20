/// Represents the game mode which affects gameplay behavior.
enum GameMode {
  /// Daily challenge mode - one puzzle per day, scores submitted to leaderboard.
  daily,

  /// Practice mode - unlimited retries, no leaderboard submission.
  practice,

  /// Timed challenge mode - solve as many puzzles as possible before time runs out.
  timed,
}
