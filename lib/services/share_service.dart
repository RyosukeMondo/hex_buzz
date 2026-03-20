import 'package:url_launcher/url_launcher.dart';
import '../domain/models/daily_challenge_completion.dart';

/// Service for sharing daily challenge results to social media platforms.
class ShareService {
  /// Formats completion time from milliseconds to human-readable format.
  ///
  /// Examples:
  /// - 45000ms -> "45s"
  /// - 83000ms -> "1m 23s"
  /// - 125000ms -> "2m 5s"
  String formatTime(int milliseconds) {
    final seconds = (milliseconds / 1000).round();
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes == 0) {
      return '${seconds}s';
    } else {
      return '${minutes}m ${remainingSeconds}s';
    }
  }

  /// Generates the share text for social media posts.
  String _generateShareText(
    DailyChallengeCompletion completion,
    String dateId,
  ) {
    final formattedTime = formatTime(completion.completionTimeMs);
    final stars = '⭐' * completion.stars;

    return '🐝 I completed today\'s HexBuzz challenge in $formattedTime! '
        '$stars${completion.stars}/3\n\n'
        'Can you beat my time?\n\n'
        'https://mondo-ai-studio.xvps.jp/hex_buzz/$dateId';
  }

  /// Shares the completion to Twitter/X.
  ///
  /// Opens Twitter web intent with pre-filled text and hashtags.
  Future<bool> shareToTwitter(
    DailyChallengeCompletion completion,
    String dateId,
  ) async {
    final text = _generateShareText(completion, dateId);
    final hashtags = 'HexBuzz,DailyChallenge';

    final url = Uri.https('twitter.com', '/intent/tweet', {
      'text': text,
      'hashtags': hashtags,
    });

    return _launchUrl(url);
  }

  /// Shares the completion to Misskey.
  ///
  /// Opens Misskey share dialog on the specified instance.
  ///
  /// [instance] should be the domain of the Misskey instance (e.g., "misskey.io")
  Future<bool> shareToMisskey(
    DailyChallengeCompletion completion,
    String dateId,
    String instance,
  ) async {
    final text = _generateShareText(completion, dateId);

    final url = Uri.https(instance, '/share', {'text': text});

    return _launchUrl(url);
  }

  /// Shares the completion to Facebook.
  ///
  /// Opens Facebook sharer with the daily challenge URL.
  Future<bool> shareToFacebook(
    DailyChallengeCompletion completion,
    String dateId,
  ) async {
    final challengeUrl = 'https://mondo-ai-studio.xvps.jp/hex_buzz/$dateId';
    final quote = _generateShareText(completion, dateId);

    final url = Uri.https('www.facebook.com', '/sharer/sharer.php', {
      'u': challengeUrl,
      'quote': quote,
    });

    return _launchUrl(url);
  }

  /// Launches a URL in the external browser/app.
  ///
  /// Returns true if the URL was successfully launched, false otherwise.
  Future<bool> _launchUrl(Uri url) async {
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Failed to launch URL (app not installed, invalid URL, etc.)
      return false;
    }
  }
}
