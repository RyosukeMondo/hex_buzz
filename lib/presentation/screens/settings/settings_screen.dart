import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_event.dart';
import '../../../core/l10n/l10n_provider.dart';
import '../../../domain/services/rating_service.dart';
import '../../../main.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/honey_theme.dart';
import '../../widgets/rating_dialog.dart';

/// Main settings screen with grouped preferences and navigation links.
///
/// Provides toggles for notifications and effects, plus links to
/// the About screen, What's New, rating prompt, and privacy policy.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _effectsEnabled = true;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).trackEvent(
        AnalyticsEventType.settingsOpened,
        properties: {'screen': 'settings'},
      );
    });
  }

  void _loadPreferences() {
    final prefs = ref.read(sharedPreferencesProvider);
    setState(() {
      _effectsEnabled = prefs.getBool('effects_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    });
  }

  Future<void> _toggleEffects(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    setState(() => _effectsEnabled = value);
    await prefs.setBool('effects_enabled', value);
    ref.read(analyticsServiceProvider).trackEvent(
      AnalyticsEventType.settingChanged,
      properties: {'setting': 'effects_enabled', 'value': value},
    );
  }

  Future<void> _toggleSound(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    setState(() => _soundEnabled = value);
    await prefs.setBool('sound_enabled', value);
    ref.read(analyticsServiceProvider).trackEvent(
      AnalyticsEventType.settingChanged,
      properties: {'setting': 'sound_enabled', 'value': value},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoneyTheme.warmCream,
      appBar: AppBar(
        title: const Text(
          'Settings',
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
          _buildSectionTitle(context, 'Preferences'),
          const SizedBox(height: HoneyTheme.spacingSm),
          _buildPreferencesCard(),
          const SizedBox(height: HoneyTheme.spacingXl),
          _buildSectionTitle(context, 'About'),
          const SizedBox(height: HoneyTheme.spacingSm),
          _buildAboutCard(context),
          const SizedBox(height: HoneyTheme.spacingXl),
          _buildSectionTitle(context, 'Support'),
          const SizedBox(height: HoneyTheme.spacingSm),
          _buildSupportCard(context),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: HoneyTheme.brownAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
      ),
      child: Column(
        children: [
          _buildLanguageTile(context),
          const Divider(height: 1, indent: 56, endIndent: 16),
          _buildThemeTile(context),
          const Divider(height: 1, indent: 56, endIndent: 16),
          _buildNavTile(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Daily challenges and updates',
            onTap: () => Navigator.of(context)
                .pushNamed(AppRoutes.notificationSettings),
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),
          _buildToggleTile(
            icon: Icons.auto_awesome,
            title: 'Visual Effects',
            subtitle: 'Animations and particle effects',
            value: _effectsEnabled,
            onChanged: _toggleEffects,
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),
          _buildToggleTile(
            icon: Icons.volume_up,
            title: 'Sound',
            subtitle: 'Game sounds and haptics',
            value: _soundEnabled,
            onChanged: _toggleSound,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context) {
    final currentLocale = ref.watch(l10nProvider);
    return ListTile(
      leading: const Icon(Icons.language, color: HoneyTheme.honeyGold),
      title: const Text(
        'Language',
        style: TextStyle(
          color: HoneyTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: DropdownButton<AppLocale>(
        value: currentLocale,
        underline: const SizedBox.shrink(),
        items: AppLocale.values.map((locale) {
          return DropdownMenuItem(
            value: locale,
            child: Text(locale.displayName),
          );
        }).toList(),
        onChanged: (locale) {
          if (locale != null) {
            ref.read(l10nProvider.notifier).setLocale(locale);
          }
        },
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context) {
    final currentTheme = ref.watch(themeProvider);
    return ListTile(
      leading: const Icon(Icons.palette, color: HoneyTheme.honeyGold),
      title: const Text(
        'Theme',
        style: TextStyle(
          color: HoneyTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: SegmentedButton<ThemePreference>(
        segments: const [
          ButtonSegment(value: ThemePreference.system, label: Text('Auto')),
          ButtonSegment(value: ThemePreference.light, label: Text('Light')),
          ButtonSegment(value: ThemePreference.dark, label: Text('Dark')),
        ],
        selected: {currentTheme},
        onSelectionChanged: (selected) {
          ref.read(themeProvider.notifier).setTheme(selected.first);
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStatePropertyAll(
            Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: HoneyTheme.honeyGold),
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
      value: value,
      onChanged: onChanged,
      activeTrackColor: HoneyTheme.honeyGoldLight,
      activeThumbColor: HoneyTheme.deepHoney,
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
      ),
      child: Column(
        children: [
          _buildNavTile(
            context,
            icon: Icons.info,
            title: 'About HexBuzz',
            subtitle: 'App info, version, and credits',
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.appInfo),
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),
          _buildNavTile(
            context,
            icon: Icons.new_releases,
            title: "What's New",
            subtitle: 'See the latest changes',
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.whatsNew),
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),
          _buildNavTile(
            context,
            icon: Icons.school,
            title: 'Reset Tutorial',
            subtitle: 'Restart the onboarding guide',
            onTap: () => _resetTutorial(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
      ),
      child: Column(
        children: [
          _buildNavTile(
            context,
            icon: Icons.star,
            title: 'Rate HexBuzz',
            subtitle: 'Help us with a review',
            onTap: () => _handleRateTap(context),
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),
          _buildNavTile(
            context,
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            subtitle: 'How we handle your data',
            onTap: () => Navigator.of(context)
                .pushNamed(AppRoutes.privacyPolicy),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile(
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

  Future<void> _handleRateTap(BuildContext context) async {
    ref.read(analyticsServiceProvider).trackEvent(
      AnalyticsEventType.ratingPromptShown,
    );

    final prefs = ref.read(sharedPreferencesProvider);
    final ratingService = RatingService(prefs);
    final result = await showRatingDialog(context);

    if (result == null) return;

    ref.read(analyticsServiceProvider).trackEvent(
      AnalyticsEventType.ratingPromptResult,
      properties: {'result': result.name},
    );

    switch (result) {
      case RatingDialogResult.rateNow:
        await ratingService.markRated();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you for your support!'),
              backgroundColor: HoneyTheme.deepHoney,
            ),
          );
        }
      case RatingDialogResult.later:
        await ratingService.markLater();
      case RatingDialogResult.noThanks:
        await ratingService.markDeclined();
    }
  }

  void _resetTutorial(BuildContext context) {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setBool('tutorial_completed', false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tutorial will show on next game start'),
        backgroundColor: HoneyTheme.deepHoney,
      ),
    );
  }

}
