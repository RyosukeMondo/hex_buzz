import 'package:flutter/material.dart';
import '../../domain/models/daily_challenge_completion.dart';
import '../../services/share_service.dart';
import 'share_button.dart';
import 'misskey_instance_picker.dart';
import 'daily_leaderboard.dart';

/// Dialog shown when a user completes a daily challenge.
///
/// Displays completion stats, share buttons, and daily leaderboard.
class DailyChallengeCompletionDialog extends StatelessWidget {
  final DailyChallengeCompletion completion;
  final String dateId;
  final ShareService _shareService = ShareService();

  DailyChallengeCompletionDialog({
    super.key,
    required this.completion,
    required this.dateId,
  });

  /// Shows the completion dialog.
  static Future<void> show(
    BuildContext context, {
    required DailyChallengeCompletion completion,
    required String dateId,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DailyChallengeCompletionDialog(
        completion: completion,
        dateId: dateId,
      ),
    );
  }

  Future<void> _handleTwitterShare(BuildContext context) async {
    final success = await _shareService.shareToTwitter(completion, dateId);
    if (!success && context.mounted) {
      _showShareError(context, 'Twitter');
    }
  }

  Future<void> _handleMisskeyShare(BuildContext context) async {
    final instance = await MisskeyInstancePicker.show(context);
    if (instance == null) return; // User cancelled

    if (!context.mounted) return;

    final success = await _shareService.shareToMisskey(
      completion,
      dateId,
      instance,
    );
    if (!success && context.mounted) {
      _showShareError(context, 'Misskey');
    }
  }

  Future<void> _handleFacebookShare(BuildContext context) async {
    final success = await _shareService.shareToFacebook(completion, dateId);
    if (!success && context.mounted) {
      _showShareError(context, 'Facebook');
    }
  }

  void _showShareError(BuildContext context, String platform) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to share to $platform'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = _shareService.formatTime(completion.completionTimeMs);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title
              const Text(
                '🎉 Challenge Complete!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 24),

              // Stats section
              _buildStatsSection(formattedTime),

              const SizedBox(height: 32),

              // Share section
              const Text(
                'Share your result:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 16),

              // Share buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ShareButton.twitter(
                    onTap: () => _handleTwitterShare(context),
                  ),
                  ShareButton.misskey(
                    onTap: () => _handleMisskeyShare(context),
                  ),
                  ShareButton.facebook(
                    onTap: () => _handleFacebookShare(context),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Daily leaderboard
              DailyLeaderboard(dateId: dateId),

              const SizedBox(height: 16),

              // Come back message
              const Text(
                'Come back tomorrow for a new challenge!',
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(String formattedTime) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Stars: ', style: TextStyle(fontSize: 16)),
                ...List.generate(
                  3,
                  (index) => Icon(
                    index < completion.stars ? Icons.star : Icons.star_border,
                    color: index < completion.stars
                        ? Colors.amber
                        : Colors.grey,
                    size: 24,
                  ),
                ),
                Text(
                  ' ${completion.stars}/3',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Time
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Time: $formattedTime',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Rank (if available)
            if (completion.rank != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRankBadge(completion.rank!),
                  const SizedBox(width: 8),
                  Text(
                    'Rank: #${completion.rank}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    String emoji;
    switch (rank) {
      case 1:
        emoji = '🥇';
        break;
      case 2:
        emoji = '🥈';
        break;
      case 3:
        emoji = '🥉';
        break;
      default:
        return const Icon(Icons.emoji_events, color: Colors.grey);
    }

    return Text(emoji, style: const TextStyle(fontSize: 20));
  }
}
