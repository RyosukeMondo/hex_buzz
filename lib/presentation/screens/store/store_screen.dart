import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_event.dart';
import '../../../domain/models/purchase.dart';
import '../../../domain/services/ad_service.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/monetization_provider.dart';
import '../../theme/honey_theme.dart';

/// In-app store screen for purchasing premium features and hint packs.
///
/// Displays a honey-themed storefront with purchasable items organized
/// into sections: Remove Ads, Hint Packs, Premium Themes, and a
/// rewarded ad option for free hints. Includes a restore purchases button.
class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monetizationState = ref.watch(monetizationProvider);

    return Scaffold(
      backgroundColor: HoneyTheme.warmCream,
      appBar: AppBar(
        title: const Text('Honey Shop'),
        backgroundColor: HoneyTheme.honeyGold,
        foregroundColor: HoneyTheme.textOnPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: monetizationState.when(
        data: (purchaseState) => _buildStoreContent(
          context,
          ref,
          purchaseState,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorView(context, ref, error),
      ),
    );
  }

  Widget _buildStoreContent(
    BuildContext context,
    WidgetRef ref,
    PurchaseState purchaseState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(HoneyTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHintBalance(context, purchaseState),
          const SizedBox(height: HoneyTheme.spacingXl),
          _buildRemoveAdsCard(context, ref, purchaseState),
          const SizedBox(height: HoneyTheme.spacingLg),
          _buildSectionTitle(context, 'Hint Packs'),
          const SizedBox(height: HoneyTheme.spacingSm),
          _buildHintPacksRow(context, ref),
          const SizedBox(height: HoneyTheme.spacingLg),
          _buildPremiumThemesCard(context, ref, purchaseState),
          const SizedBox(height: HoneyTheme.spacingLg),
          _buildWatchAdCard(context, ref),
          const SizedBox(height: HoneyTheme.spacingXl),
          _buildRestoreButton(context, ref),
          const SizedBox(height: HoneyTheme.spacingLg),
        ],
      ),
    );
  }

  Widget _buildHintBalance(BuildContext context, PurchaseState purchaseState) {
    return Semantics(
      label: 'You have ${purchaseState.extraHints} hints remaining',
      child: Container(
        padding: const EdgeInsets.all(HoneyTheme.spacingLg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [HoneyTheme.honeyGold, HoneyTheme.honeyGoldLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(HoneyTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: HoneyTheme.honeyGold.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.lightbulb,
                color: HoneyTheme.textPrimary,
                size: HoneyTheme.iconSizeLg,
              ),
            ),
            const SizedBox(width: HoneyTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Hints',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: HoneyTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    '${purchaseState.extraHints} hints remaining',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: HoneyTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            ExcludeSemantics(
              child: Text(
                '${purchaseState.extraHints}',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: HoneyTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoveAdsCard(
    BuildContext context,
    WidgetRef ref,
    PurchaseState purchaseState,
  ) {
    final alreadyPurchased = purchaseState.adsRemoved;

    return _StoreCard(
      icon: Icons.block,
      title: 'Remove Ads',
      description: alreadyPurchased
          ? 'Ads have been removed. Enjoy ad-free play!'
          : 'Permanently remove all advertisements.',
      price: alreadyPurchased ? 'Owned' : '\$2.99',
      isPurchased: alreadyPurchased,
      onPurchase: alreadyPurchased
          ? null
          : () {
              ref.read(analyticsServiceProvider).trackEvent(
                AnalyticsEventType.storePurchaseAttempted,
                properties: {'item': 'remove_ads'},
              );
              ref.read(monetizationProvider.notifier).removeAds();
            },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: HoneyTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildHintPacksRow(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _StoreCard(
            icon: Icons.lightbulb_outline,
            title: '5 Hints',
            description: 'A small boost for tricky puzzles.',
            price: '\$0.99',
            isPurchased: false,
            onPurchase: () {
              ref.read(analyticsServiceProvider).trackEvent(
                AnalyticsEventType.storePurchaseAttempted,
                properties: {'item': 'hint_pack_5'},
              );
              ref
                  .read(monetizationProvider.notifier)
                  .purchaseHints(ProductId.hintPack5);
            },
          ),
        ),
        const SizedBox(width: HoneyTheme.spacingMd),
        Expanded(
          child: _StoreCard(
            icon: Icons.lightbulb,
            title: '20 Hints',
            description: 'Best value for hint lovers!',
            price: '\$2.99',
            isPurchased: false,
            badgeText: 'Best Value',
            onPurchase: () {
              ref.read(analyticsServiceProvider).trackEvent(
                AnalyticsEventType.storePurchaseAttempted,
                properties: {'item': 'hint_pack_20'},
              );
              ref
                  .read(monetizationProvider.notifier)
                  .purchaseHints(ProductId.hintPack20);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumThemesCard(
    BuildContext context,
    WidgetRef ref,
    PurchaseState purchaseState,
  ) {
    final alreadyPurchased = purchaseState.premiumThemes;

    return _StoreCard(
      icon: Icons.palette,
      title: 'Premium Themes',
      description: alreadyPurchased
          ? 'All premium themes unlocked!'
          : 'Unlock all visual themes for the game board.',
      price: alreadyPurchased ? 'Owned' : '\$1.99',
      isPurchased: alreadyPurchased,
      onPurchase: alreadyPurchased
          ? null
          : () {
              ref.read(analyticsServiceProvider).trackEvent(
                AnalyticsEventType.storePurchaseAttempted,
                properties: {'item': 'premium_themes'},
              );
              ref.read(monetizationProvider.notifier).purchasePremiumThemes();
            },
    );
  }

  Widget _buildWatchAdCard(BuildContext context, WidgetRef ref) {
    return _StoreCard(
      icon: Icons.play_circle_outline,
      title: 'Watch Ad for Hint',
      description: 'Watch a short video to earn a free hint.',
      price: 'Free',
      isPurchased: false,
      onPurchase: () => _handleWatchAd(context, ref),
    );
  }

  Future<void> _handleWatchAd(BuildContext context, WidgetRef ref) async {
    ref.read(analyticsServiceProvider).trackEvent(
      AnalyticsEventType.storeAdWatched,
    );

    final result =
        await ref.read(monetizationProvider.notifier).watchAdForHint();

    if (!context.mounted) return;

    switch (result) {
      case AdResult.completed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hint earned! Check your balance.'),
            backgroundColor: HoneyTheme.brownAccent,
          ),
        );
        break;
      case AdResult.notReady:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait before watching another ad.'),
          ),
        );
        break;
      case AdResult.dismissed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Watch the full ad to earn your hint.'),
          ),
        );
        break;
      default:
        break;
    }
  }

  Widget _buildRestoreButton(BuildContext context, WidgetRef ref) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _handleRestore(context, ref),
        icon: const Icon(Icons.restore),
        label: const Text('Restore Purchases'),
        style: TextButton.styleFrom(
          foregroundColor: HoneyTheme.brownAccent,
        ),
      ),
    );
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    await ref.read(monetizationProvider.notifier).restorePurchases();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Purchases restored successfully.'),
        backgroundColor: HoneyTheme.brownAccent,
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: HoneyTheme.iconSizeLg,
            color: Colors.red,
          ),
          const SizedBox(height: HoneyTheme.spacingLg),
          Text('Error loading store: $error'),
          const SizedBox(height: HoneyTheme.spacingLg),
          ElevatedButton(
            onPressed: () => ref.invalidate(monetizationProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// A themed card widget for displaying a purchasable product.
class _StoreCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String price;
  final bool isPurchased;
  final String? badgeText;
  final VoidCallback? onPurchase;

  const _StoreCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.price,
    required this.isPurchased,
    this.badgeText,
    this.onPurchase,
  });

  String get _semanticLabel {
    final status = isPurchased ? 'Owned' : price;
    return '$title, $status';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticLabel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildCardContainer(context),
          if (badgeText != null) _buildBadge(context),
        ],
      ),
    );
  }

  Widget _buildCardContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HoneyTheme.spacingLg),
      decoration: _cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildHeader(),
        const SizedBox(height: HoneyTheme.spacingSm),
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: HoneyTheme.textPrimary, fontWeight: FontWeight.bold)),
        const SizedBox(height: HoneyTheme.spacingXs),
        Text(description, style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: HoneyTheme.textSecondary),
          maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: HoneyTheme.spacingMd),
        _buildPurchaseButton(),
      ]),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(HoneyTheme.radiusLg),
      border: Border.all(
        color: isPurchased
            ? HoneyTheme.honeyGold
            : HoneyTheme.honeyGold.withValues(alpha: 0.3),
        width: isPurchased ? 2 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: HoneyTheme.honeyGold.withValues(alpha: 0.15),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return ExcludeSemantics(
      child: Row(
        children: [
          Icon(icon, color: HoneyTheme.brownAccent),
          const Spacer(),
          if (isPurchased)
            const Icon(Icons.check_circle, color: HoneyTheme.honeyGold),
        ],
      ),
    );
  }

  Widget _buildPurchaseButton() {
    final buttonLabel = isPurchased
        ? '$title already owned'
        : 'Purchase $title for $price';
    return Semantics(
      label: buttonLabel,
      button: true,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPurchase,
          style: ElevatedButton.styleFrom(
            backgroundColor: isPurchased
                ? HoneyTheme.warmCreamDark
                : HoneyTheme.honeyGold,
            foregroundColor: HoneyTheme.textOnPrimary,
            disabledBackgroundColor: HoneyTheme.warmCreamDark,
            disabledForegroundColor: HoneyTheme.textSecondary,
          ),
          child: Text(price),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context) {
    return Positioned(
      right: -4,
      top: -8,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: HoneyTheme.spacingSm,
          vertical: HoneyTheme.spacingXs,
        ),
        decoration: BoxDecoration(
          color: HoneyTheme.deepHoney,
          borderRadius: BorderRadius.circular(HoneyTheme.radiusSm),
        ),
        child: Text(
          badgeText!,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}
