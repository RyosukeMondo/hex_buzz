import 'package:flutter/material.dart';

import '../theme/honey_theme.dart';

/// Result of the rating dialog interaction.
enum RatingDialogResult {
  /// User tapped "Rate Now" to leave a review.
  rateNow,

  /// User tapped "Later" to defer the prompt.
  later,

  /// User tapped "No Thanks" to decline permanently.
  noThanks,
}

/// A honey-themed dialog that encourages users to rate the app.
///
/// Displays a bee mascot icon, a warm message, and three action buttons.
/// Returns a [RatingDialogResult] indicating the user's choice.
///
/// Usage:
/// ```dart
/// final result = await showRatingDialog(context);
/// ```
class RatingDialog extends StatelessWidget {
  const RatingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoneyTheme.radiusXl),
      ),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(HoneyTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMascot(),
            const SizedBox(height: HoneyTheme.spacingLg),
            _buildTitle(context),
            const SizedBox(height: HoneyTheme.spacingSm),
            _buildSubtitle(context),
            const SizedBox(height: HoneyTheme.spacingXl),
            _buildRateButton(context),
            const SizedBox(height: HoneyTheme.spacingMd),
            _buildSecondaryButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMascot() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HoneyTheme.honeyGold, HoneyTheme.deepHoney],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: HoneyTheme.honeyGold.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.favorite,
        color: Colors.white,
        size: HoneyTheme.iconSizeLg,
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      'Enjoying HexBuzz?',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: HoneyTheme.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Text(
      'Your feedback helps us make the game even better. '
      'Would you mind leaving a quick rating?',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: HoneyTheme.textSecondary,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildRateButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () =>
            Navigator.of(context).pop(RatingDialogResult.rateNow),
        icon: const Icon(Icons.star, size: 20),
        label: const Text('Rate Now'),
        style: FilledButton.styleFrom(
          backgroundColor: HoneyTheme.honeyGold,
          foregroundColor: HoneyTheme.textOnPrimary,
          padding: const EdgeInsets.symmetric(
            vertical: HoneyTheme.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () =>
                Navigator.of(context).pop(RatingDialogResult.later),
            child: Text(
              'Later',
              style: TextStyle(color: HoneyTheme.brownAccent),
            ),
          ),
        ),
        Expanded(
          child: TextButton(
            onPressed: () =>
                Navigator.of(context).pop(RatingDialogResult.noThanks),
            child: Text(
              'No Thanks',
              style: TextStyle(color: HoneyTheme.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shows the rating dialog and returns the user's choice.
///
/// Returns `null` if the dialog is dismissed without making a selection.
Future<RatingDialogResult?> showRatingDialog(BuildContext context) {
  return showDialog<RatingDialogResult>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const RatingDialog(),
  );
}
