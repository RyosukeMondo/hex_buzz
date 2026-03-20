import 'package:flutter/material.dart';

import '../../domain/services/ad_service.dart';
import '../../presentation/theme/honey_theme.dart';

/// Mock implementation of [AdService] that simulates ads with in-app UI.
///
/// Used during development and testing when real ad SDKs are not available.
/// Interstitials show a brief "Ad would appear here" dialog.
/// Rewarded ads show a 5-second countdown the user must watch.
/// Banner ads display a styled placeholder container.
class PlaceholderAdService implements AdService {
  bool _initialized = false;

  /// Global navigator key used to show ad dialogs.
  ///
  /// Must be set before showing interstitial or rewarded ads.
  /// Typically set from the app's root navigator key.
  GlobalKey<NavigatorState>? navigatorKey;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<bool> isAdReady(AdType type) async {
    return _initialized;
  }

  @override
  Future<AdResult> showInterstitial() async {
    if (!_initialized) return AdResult.notReady;

    final context = navigatorKey?.currentContext;
    if (context == null) return AdResult.failed;

    await _showInterstitialDialog(context);
    return AdResult.shown;
  }

  @override
  Future<AdResult> showRewarded() async {
    if (!_initialized) return AdResult.notReady;

    final context = navigatorKey?.currentContext;
    if (context == null) return AdResult.failed;

    final completed = await _showRewardedDialog(context);
    return completed ? AdResult.completed : AdResult.dismissed;
  }

  @override
  Widget buildBannerAd() {
    return const PlaceholderBannerWidget();
  }

  @override
  void dispose() {
    _initialized = false;
  }
}

/// Shows a simulated interstitial ad dialog for 2 seconds.
Future<void> _showInterstitialDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      Future.delayed(const Duration(seconds: 2), () {
        if (dialogContext.mounted) {
          Navigator.of(dialogContext).pop();
        }
      });

      return const _InterstitialAdDialog();
    },
  );
}

/// Shows a simulated rewarded ad dialog with a 5-second countdown.
///
/// Returns true if the user watched the full countdown,
/// false if dismissed early.
Future<bool> _showRewardedDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const _RewardedAdDialog(),
  );
  return result ?? false;
}

/// Simulated interstitial ad dialog widget.
class _InterstitialAdDialog extends StatelessWidget {
  const _InterstitialAdDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoneyTheme.radiusLg),
        side: const BorderSide(color: HoneyTheme.honeyGold, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(HoneyTheme.spacingXl),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: HoneyTheme.textPrimary,
      fontWeight: FontWeight.bold,
    );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: HoneyTheme.textSecondary,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.ad_units,
          size: HoneyTheme.iconSizeXl,
          color: HoneyTheme.brownAccent,
        ),
        const SizedBox(height: HoneyTheme.spacingLg),
        Text('Ad Would Appear Here', style: titleStyle),
        const SizedBox(height: HoneyTheme.spacingSm),
        Text(
          'This is a placeholder for a real advertisement.',
          style: bodyStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: HoneyTheme.spacingLg),
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: HoneyTheme.honeyGold,
          ),
        ),
      ],
    );
  }
}

/// Simulated rewarded ad dialog with countdown timer.
class _RewardedAdDialog extends StatefulWidget {
  const _RewardedAdDialog();

  @override
  State<_RewardedAdDialog> createState() => _RewardedAdDialogState();
}

class _RewardedAdDialogState extends State<_RewardedAdDialog> {
  int _secondsRemaining = 5;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  Future<void> _startCountdown() async {
    for (int i = 5; i > 0; i--) {
      if (!mounted) return;
      setState(() => _secondsRemaining = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;
    setState(() {
      _secondsRemaining = 0;
      _completed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoneyTheme.radiusLg),
        side: const BorderSide(color: HoneyTheme.honeyGold, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(HoneyTheme.spacingXl),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: HoneyTheme.textPrimary,
      fontWeight: FontWeight.bold,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.play_circle_filled,
          size: HoneyTheme.iconSizeXl,
          color: HoneyTheme.brownAccent,
        ),
        const SizedBox(height: HoneyTheme.spacingLg),
        Text(
          _completed ? 'Ad Complete!' : 'Watch Ad for Reward',
          style: titleStyle,
        ),
        const SizedBox(height: HoneyTheme.spacingMd),
        if (!_completed) _buildCountdownText(context),
        const SizedBox(height: HoneyTheme.spacingLg),
        _buildActionButton(context),
      ],
    );
  }

  Widget _buildCountdownText(BuildContext context) {
    return Text(
      '$_secondsRemaining',
      style: Theme.of(context).textTheme.displayMedium?.copyWith(
        color: HoneyTheme.deepHoney,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (_completed) {
      return ElevatedButton(
        onPressed: () => Navigator.of(context).pop(true),
        style: ElevatedButton.styleFrom(
          backgroundColor: HoneyTheme.honeyGold,
          foregroundColor: HoneyTheme.textOnPrimary,
        ),
        child: const Text('Claim Reward'),
      );
    }
    return TextButton(
      onPressed: () => Navigator.of(context).pop(false),
      child: Text(
        'Skip',
        style: TextStyle(color: HoneyTheme.textSecondary),
      ),
    );
  }
}

/// Placeholder banner ad widget styled with the honey theme.
class PlaceholderBannerWidget extends StatelessWidget {
  const PlaceholderBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final subtleColor = HoneyTheme.textSecondary.withValues(alpha: 0.6);
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: subtleColor,
      fontStyle: FontStyle.italic,
    );

    return Container(
      width: double.infinity,
      height: 50,
      margin: const EdgeInsets.symmetric(
        horizontal: HoneyTheme.spacingLg,
        vertical: HoneyTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: HoneyTheme.warmCreamDark,
        borderRadius: BorderRadius.circular(HoneyTheme.radiusSm),
        border: Border.all(
          color: HoneyTheme.honeyGold.withValues(alpha: 0.5),
        ),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.ad_units, size: HoneyTheme.iconSizeSm, color: subtleColor),
            const SizedBox(width: HoneyTheme.spacingXs),
            Text('Ad Space', style: textStyle),
          ],
        ),
      ),
    );
  }
}
