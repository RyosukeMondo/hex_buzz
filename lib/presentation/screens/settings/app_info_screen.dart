import 'package:flutter/material.dart';

import '../../../domain/services/app_update_service.dart';
import '../../../main.dart';
import '../../theme/honey_theme.dart';
import '../../widgets/assets/game_assets.dart';

/// Displays app information including version, links, and credits.
///
/// Provides navigation to the What's New screen, privacy policy,
/// terms of service, and open source licenses. Features a honey-themed
/// design with the app icon and a "Made with love" footer.
class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoneyTheme.warmCream,
      appBar: AppBar(
        title: const Text(
          'About HexBuzz',
          style: TextStyle(
            color: HoneyTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: HoneyTheme.honeyGold,
        iconTheme: const IconThemeData(color: HoneyTheme.textPrimary),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(HoneyTheme.spacingLg),
        children: [
          _buildAppHeader(context),
          const SizedBox(height: HoneyTheme.spacingXl),
          _buildLinksCard(context),
          const SizedBox(height: HoneyTheme.spacingXl),
          _buildLegalCard(context),
          const SizedBox(height: HoneyTheme.spacingXxl),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildAppHeader(BuildContext context) {
    final version = AppUpdateService.getAppVersion();

    return Column(
      children: [
        const SizedBox(height: HoneyTheme.spacingLg),
        AssetImageWithFallback(
          assetPath: GameAssetPaths.appIcon,
          width: 100,
          height: 100,
          fallback: _buildFallbackIcon(),
        ),
        const SizedBox(height: HoneyTheme.spacingLg),
        Text(
          'HexBuzz',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: HoneyTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: HoneyTheme.spacingXs),
        Text(
          'Version $version',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: HoneyTheme.textSecondary,
          ),
        ),
        const SizedBox(height: HoneyTheme.spacingSm),
        Text(
          'One Path Challenge',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: HoneyTheme.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 100,
      height: 100,
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
        Icons.hexagon,
        color: Colors.white,
        size: HoneyTheme.iconSizeXl,
      ),
    );
  }

  Widget _buildLinksCard(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
      ),
      child: Column(
        children: [
          _buildLinkTile(
            context,
            icon: Icons.new_releases,
            title: "What's New",
            subtitle: 'See the latest changes',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.whatsNew),
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),
          _buildLinkTile(
            context,
            icon: Icons.star,
            title: 'Rate HexBuzz',
            subtitle: 'Leave a review on the store',
            onTap: () => _showRateSnackbar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalCard(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
      ),
      child: Column(
        children: [
          _buildLinkTile(
            context,
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            subtitle: 'How we handle your data',
            onTap: () => Navigator.of(context)
                .pushNamed(AppRoutes.privacyPolicy),
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),
          _buildLinkTile(
            context,
            icon: Icons.description,
            title: 'Terms of Service',
            subtitle: 'Usage terms and conditions',
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.terms),
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),
          _buildLinkTile(
            context,
            icon: Icons.code,
            title: 'Open Source Licenses',
            subtitle: 'Third-party software we use',
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'HexBuzz',
              applicationVersion: AppUpdateService.getAppVersion(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: HoneyTheme.honeyGold),
      title: Text(
        title,
        style: const TextStyle(
          color: HoneyTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: HoneyTheme.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: HoneyTheme.brownAccent,
      ),
      onTap: onTap,
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.favorite,
          color: HoneyTheme.deepHoney,
          size: HoneyTheme.iconSizeMd,
        ),
        const SizedBox(height: HoneyTheme.spacingSm),
        Text(
          'Made with love',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: HoneyTheme.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: HoneyTheme.spacingLg),
      ],
    );
  }

  void _showRateSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Store link will be available after launch'),
        backgroundColor: HoneyTheme.brownAccent,
      ),
    );
  }

}
