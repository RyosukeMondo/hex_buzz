/// Service for generating shareable game result text.
///
/// Creates formatted text strings that users can share on social media
/// or messaging apps to show off their puzzle completions.
class ShareService {
  const ShareService();

  /// Generates shareable text for a completed puzzle.
  ///
  /// The [stars] parameter is the number of stars earned (0-3).
  /// The [time] parameter is the completion duration.
  /// The [mode] describes the game mode (e.g., "Level 5", "Daily Challenge").
  ///
  /// Returns a formatted string like:
  /// "HexBuzz \ud83d\udc1d Level 5 \u2b50\u2b50\u2b50 8.5s #HexBuzz"
  String generateShareText({
    required int stars,
    required Duration time,
    required String mode,
  }) {
    final starEmojis = _buildStarEmojis(stars);
    final timeStr = _formatDuration(time);
    return 'HexBuzz \ud83d\udc1d $mode $starEmojis $timeStr\nhttps://mondo-ai-studio.xvps.jp/hex_buzz/\n#HexBuzz';
  }

  /// Builds a string of star emojis based on count.
  String _buildStarEmojis(int stars) {
    if (stars <= 0) return '\u2606'; // empty star
    return '\u2b50' * stars;
  }

  /// Formats a duration into a human-readable time string.
  ///
  /// Uses seconds with one decimal for times under 60s (e.g., "8.5s"),
  /// or minutes:seconds format for longer times (e.g., "2:05").
  String _formatDuration(Duration time) {
    final totalSeconds = time.inMilliseconds / 1000.0;

    if (totalSeconds < 60) {
      // Format as X.Xs for times under 60 seconds
      final formatted = totalSeconds.toStringAsFixed(1);
      return '${formatted}s';
    }

    // Format as M:SS for longer times
    final minutes = time.inMinutes;
    final seconds = time.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
