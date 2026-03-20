import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_event.dart';
import '../../../domain/services/changelog_data.dart';
import '../../providers/analytics_provider.dart';
import '../../theme/honey_theme.dart';

/// Displays a scrollable changelog showing what's new in each version.
///
/// The current (latest) version is highlighted at the top. Each entry
/// shows features (star icon) and fixes (wrench icon) in honey-themed
/// cards. A "Got it!" button at the bottom dismisses the screen.
class WhatsNewScreen extends ConsumerStatefulWidget {
  const WhatsNewScreen({super.key});

  @override
  ConsumerState<WhatsNewScreen> createState() => _WhatsNewScreenState();
}

class _WhatsNewScreenState extends ConsumerState<WhatsNewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).trackEvent(
        AnalyticsEventType.whatsNewViewed,
        properties: {'screen': 'whats_new'},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = ChangelogData.entries;

    return Scaffold(
      backgroundColor: HoneyTheme.warmCream,
      appBar: AppBar(
        title: const Text(
          "What's New",
          style: TextStyle(
            color: HoneyTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: HoneyTheme.honeyGold,
        iconTheme: const IconThemeData(color: HoneyTheme.textPrimary),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(HoneyTheme.spacingLg),
              itemCount: entries.length,
              itemBuilder: (context, index) => _ChangelogCard(
                entry: entries[index],
                isCurrent: index == 0,
              ),
            ),
          ),
          _buildDismissButton(context),
        ],
      ),
    );
  }

  Widget _buildDismissButton(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(HoneyTheme.spacingLg),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
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
            child: const Text(
              'Got it!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A card displaying a single changelog version entry.
class _ChangelogCard extends StatelessWidget {
  final ChangelogEntry entry;
  final bool isCurrent;

  const _ChangelogCard({
    required this.entry,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: HoneyTheme.spacingLg),
      elevation: isCurrent ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoneyTheme.radiusLg),
        side: isCurrent
            ? const BorderSide(color: HoneyTheme.honeyGold, width: 2)
            : BorderSide.none,
      ),
      color: isCurrent ? HoneyTheme.cellUnvisited : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(HoneyTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVersionHeader(context),
            if (entry.features.isNotEmpty) ...[
              const SizedBox(height: HoneyTheme.spacingMd),
              _buildSectionTitle(context, 'New Features'),
              const SizedBox(height: HoneyTheme.spacingSm),
              ...entry.features.map(_buildFeatureItem),
            ],
            if (entry.fixes.isNotEmpty) ...[
              const SizedBox(height: HoneyTheme.spacingMd),
              _buildSectionTitle(context, 'Bug Fixes'),
              const SizedBox(height: HoneyTheme.spacingSm),
              ...entry.fixes.map(_buildFixItem),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVersionHeader(BuildContext context) {
    return Row(
      children: [
        if (isCurrent)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: HoneyTheme.spacingSm,
              vertical: HoneyTheme.spacingXs,
            ),
            margin: const EdgeInsets.only(right: HoneyTheme.spacingSm),
            decoration: BoxDecoration(
              color: HoneyTheme.honeyGold,
              borderRadius: BorderRadius.circular(HoneyTheme.radiusSm),
            ),
            child: const Text(
              'NEW',
              style: TextStyle(
                color: HoneyTheme.textOnPrimary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Text(
          'Version ${entry.version}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: HoneyTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Text(
          entry.date,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: HoneyTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: HoneyTheme.brownAccent,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HoneyTheme.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.star,
              color: HoneyTheme.starFilled,
              size: HoneyTheme.iconSizeSm,
            ),
          ),
          const SizedBox(width: HoneyTheme.spacingSm),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(
                color: HoneyTheme.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixItem(String fix) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HoneyTheme.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.build,
              color: HoneyTheme.brownAccent,
              size: HoneyTheme.iconSizeSm,
            ),
          ),
          const SizedBox(width: HoneyTheme.spacingSm),
          Expanded(
            child: Text(
              fix,
              style: const TextStyle(
                color: HoneyTheme.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
