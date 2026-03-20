import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/monetization_provider.dart';

/// A widget that conditionally displays a banner ad.
///
/// Shows the banner only if the user has not purchased "Remove Ads".
/// Gracefully handles missing or uninitialized ad service by rendering
/// an empty [SizedBox].
class AdBannerWidget extends ConsumerWidget {
  const AdBannerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monetizationState = ref.watch(monetizationProvider);

    return monetizationState.when(
      data: (purchaseState) {
        if (purchaseState.adsRemoved) return const SizedBox.shrink();

        return _buildBanner(ref);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBanner(WidgetRef ref) {
    try {
      final adService = ref.read(adServiceProvider);
      return adService.buildBannerAd();
    } catch (_) {
      // Ad service not available - fail gracefully
      return const SizedBox.shrink();
    }
  }
}
