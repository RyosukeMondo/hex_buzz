/// Calculates star ratings based on level completion time.
///
/// Star thresholds:
/// - 3 stars: ≤10 seconds
/// - 2 stars: ≤30 seconds
/// - 1 star: ≤60 seconds
/// - 0 stars: >60 seconds
class StarCalculator {
  const StarCalculator._();

  /// Maximum stars achievable.
  static const int maxStars = 3;

  /// Time threshold for 3 stars (10 seconds).
  static const Duration threeStarThreshold = Duration(seconds: 10);

  /// Time threshold for 2 stars (30 seconds).
  static const Duration twoStarThreshold = Duration(seconds: 30);

  /// Time threshold for 1 star (60 seconds).
  static const Duration oneStarThreshold = Duration(seconds: 60);

  /// Calculates stars earned based on completion time.
  ///
  /// Returns 0-3 stars based on the following thresholds:
  /// - 3★: time ≤ 10 seconds
  /// - 2★: time ≤ 30 seconds
  /// - 1★: time ≤ 60 seconds
  /// - 0★: time > 60 seconds
  ///
  /// Boundary conditions are exact:
  /// - 10.000s = 3★
  /// - 10.001s = 2★
  static int calculateStars(Duration time) {
    if (time <= threeStarThreshold) return 3;
    if (time <= twoStarThreshold) return 2;
    if (time <= oneStarThreshold) return 1;
    return 0;
  }
}
