import 'package:flutter/material.dart';

import '../../../domain/models/daily_challenge_completion.dart';
import '../../../services/share_service.dart';
import '../../theme/honey_theme.dart';
import '../../widgets/daily_leaderboard.dart';
import '../../widgets/misskey_instance_picker.dart';
import '../../widgets/share_button.dart';

/// Displays challenge completion results (stars, time, rank) with share buttons.
class ChallengeCompletionView extends StatelessWidget {
  final DailyChallengeCompletion completion;
  final VoidCallback onBack;

  const ChallengeCompletionView({
    super.key,
    required this.completion,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(HoneyTheme.spacingXl),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events,
            size: HoneyTheme.iconSizeXl,
            color: HoneyTheme.honeyGold,
          ),
          const SizedBox(height: HoneyTheme.spacingLg),
          const Text(
            'Challenge Complete!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: HoneyTheme.spacingMd),
          _CompletionStats(completion: completion),
          const SizedBox(height: HoneyTheme.spacingXl),
          _ShareSection(completion: completion),
          const SizedBox(height: HoneyTheme.spacingXl),
          DailyLeaderboard(dateId: completion.dateId),
          const SizedBox(height: HoneyTheme.spacingLg),
          ElevatedButton(
            onPressed: onBack,
            style: ElevatedButton.styleFrom(
              backgroundColor: HoneyTheme.honeyGold,
              foregroundColor: HoneyTheme.textPrimary,
            ),
            child: const Text('Back to Menu'),
          ),
        ],
      ),
    );
  }
}

/// Displays "already completed today" with results, share buttons, and leaderboard.
class AlreadyCompletedView extends StatelessWidget {
  final DailyChallengeCompletion completion;
  final VoidCallback onBack;

  const AlreadyCompletedView({
    super.key,
    required this.completion,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(HoneyTheme.spacingXl),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: HoneyTheme.iconSizeXl,
            color: HoneyTheme.honeyGold,
          ),
          const SizedBox(height: HoneyTheme.spacingLg),
          const Text(
            'Today\'s Result',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: HoneyTheme.spacingMd),
          _CompletionStats(completion: completion),
          const SizedBox(height: HoneyTheme.spacingXl),
          _ShareSection(completion: completion),
          const SizedBox(height: HoneyTheme.spacingXl),
          DailyLeaderboard(dateId: completion.dateId),
          const SizedBox(height: HoneyTheme.spacingLg),
          const Text(
            'Come back tomorrow for a new challenge!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: HoneyTheme.spacingLg),
          ElevatedButton(
            onPressed: onBack,
            style: ElevatedButton.styleFrom(
              backgroundColor: HoneyTheme.honeyGold,
              foregroundColor: HoneyTheme.textPrimary,
            ),
            child: const Text('Back to Menu'),
          ),
        ],
      ),
    );
  }
}

/// Displays the challenge card with title, subtitle, and action button.
class ChallengeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  const ChallengeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HoneyTheme.spacingXl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HoneyTheme.honeyGold,
            HoneyTheme.honeyGoldLight.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(HoneyTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.calendar_today,
            size: HoneyTheme.iconSizeLg,
            color: HoneyTheme.textPrimary,
          ),
          const SizedBox(height: HoneyTheme.spacingMd),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: HoneyTheme.textPrimary,
            ),
          ),
          const SizedBox(height: HoneyTheme.spacingSm),
          Text(
            subtitle,
            style: TextStyle(fontSize: 16, color: HoneyTheme.textSecondary),
          ),
          const SizedBox(height: HoneyTheme.spacingXl),
          _StartButton(text: buttonText, onPressed: onPressed),
        ],
      ),
    );
  }
}

/// Displays grid size and checkpoint count for a challenge.
class ChallengeStatsCard extends StatelessWidget {
  final int gridSize;
  final int checkpointCount;

  const ChallengeStatsCard({
    super.key,
    required this.gridSize,
    required this.checkpointCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HoneyTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Challenge Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: HoneyTheme.textPrimary,
            ),
          ),
          const SizedBox(height: HoneyTheme.spacingMd),
          _StatRow(
            icon: Icons.grid_on,
            label: 'Grid Size',
            value: '$gridSize\u00d7$gridSize',
          ),
          const SizedBox(height: HoneyTheme.spacingSm),
          _StatRow(
            icon: Icons.location_on,
            label: 'Checkpoints',
            value: '$checkpointCount',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

class _ShareSection extends StatelessWidget {
  final DailyChallengeCompletion completion;
  final ShareService _shareService = ShareService();

  _ShareSection({required this.completion});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Share your result:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: HoneyTheme.spacingMd),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ShareButton.twitter(
              onTap: () => _share(context, 'twitter'),
            ),
            ShareButton.misskey(
              onTap: () => _shareMisskey(context),
            ),
            ShareButton.facebook(
              onTap: () => _share(context, 'facebook'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _share(BuildContext context, String platform) async {
    final dateId = completion.dateId;
    final success = switch (platform) {
      'twitter' => await _shareService.shareToTwitter(completion, dateId),
      'facebook' => await _shareService.shareToFacebook(completion, dateId),
      _ => false,
    };
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share to $platform')),
      );
    }
  }

  Future<void> _shareMisskey(BuildContext context) async {
    final instance = await MisskeyInstancePicker.show(context);
    if (instance == null || !context.mounted) return;
    final success = await _shareService.shareToMisskey(
      completion, completion.dateId, instance,
    );
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share to Misskey')),
      );
    }
  }
}

class _CompletionStats extends StatelessWidget {
  final DailyChallengeCompletion completion;

  const _CompletionStats({required this.completion});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Stars: ${completion.stars}/3',
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: HoneyTheme.spacingSm),
        Text(
          'Time: ${formatTime(completion.completionTimeMs)}',
          style: const TextStyle(fontSize: 18),
        ),
        if (completion.rank != null) ...[
          const SizedBox(height: HoneyTheme.spacingSm),
          Text(
            'Rank: #${completion.rank}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }
}

class _StartButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _StartButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.play_arrow),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: HoneyTheme.deepHoney,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: HoneyTheme.spacingXl,
          vertical: HoneyTheme.spacingMd,
        ),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: HoneyTheme.brownAccent),
        const SizedBox(width: HoneyTheme.spacingSm),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 16, color: HoneyTheme.textSecondary),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: HoneyTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Formatting utilities
// ---------------------------------------------------------------------------

/// Formats milliseconds as MM:SS.CC.
String formatTime(int milliseconds) {
  final duration = Duration(milliseconds: milliseconds);
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  final ms = (duration.inMilliseconds % 1000) ~/ 10;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}.'
      '${ms.toString().padLeft(2, '0')}';
}

/// Formats a [Duration] as MM:SS.
String formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

/// Formats a [DateTime] as "Mon DD, YYYY".
String formatChallengeDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
