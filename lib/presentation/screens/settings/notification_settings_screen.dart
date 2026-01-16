import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/notification_provider.dart';
import '../../theme/honey_theme.dart';

/// Notification settings screen allowing users to control notification preferences.
///
/// Provides toggles for:
/// - Daily challenge notifications
/// - Rank change notifications
/// - Re-engagement notifications
///
/// Also displays notification permission status and allows requesting permission.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _dailyChallengeEnabled = true;
  bool _rankChangeEnabled = true;
  bool _reEngagementEnabled = true;
  bool _permissionGranted = false;
  bool _isLoading = true;
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final notificationService = ref.read(notificationServiceProvider);

    setState(() {
      _dailyChallengeEnabled =
          prefs.getBool(NotificationPrefs.dailyChallengeKey) ?? true;
      _rankChangeEnabled =
          prefs.getBool(NotificationPrefs.rankChangeKey) ?? true;
      _reEngagementEnabled =
          prefs.getBool(NotificationPrefs.reEngagementKey) ?? true;
    });

    // Check if notification service is initialized and permission granted
    try {
      final token = await notificationService.getDeviceToken();
      setState(() {
        _permissionGranted = token != null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _permissionGranted = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleDailyChallenge(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final notificationService = ref.read(notificationServiceProvider);

    setState(() => _dailyChallengeEnabled = value);
    await prefs.setBool(NotificationPrefs.dailyChallengeKey, value);

    // Subscribe/unsubscribe to topic
    if (value) {
      await notificationService.subscribeToTopic('daily_challenge');
    } else {
      await notificationService.unsubscribeFromTopic('daily_challenge');
    }
  }

  Future<void> _toggleRankChange(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final notificationService = ref.read(notificationServiceProvider);

    setState(() => _rankChangeEnabled = value);
    await prefs.setBool(NotificationPrefs.rankChangeKey, value);

    // Subscribe/unsubscribe to topic
    if (value) {
      await notificationService.subscribeToTopic('rank_changes');
    } else {
      await notificationService.unsubscribeFromTopic('rank_changes');
    }
  }

  Future<void> _toggleReEngagement(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final notificationService = ref.read(notificationServiceProvider);

    setState(() => _reEngagementEnabled = value);
    await prefs.setBool(NotificationPrefs.reEngagementKey, value);

    // Subscribe/unsubscribe to topic
    if (value) {
      await notificationService.subscribeToTopic('re_engagement');
    } else {
      await notificationService.unsubscribeFromTopic('re_engagement');
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _isRequestingPermission = true);

    final notificationService = ref.read(notificationServiceProvider);
    final granted = await notificationService.requestPermission();

    if (!mounted) return;

    setState(() {
      _permissionGranted = granted;
      _isRequestingPermission = false;
    });

    if (granted) {
      // Initialize notification service after permission granted
      await notificationService.initialize();

      // Subscribe to enabled topics
      if (_dailyChallengeEnabled) {
        await notificationService.subscribeToTopic('daily_challenge');
      }
      if (_rankChangeEnabled) {
        await notificationService.subscribeToTopic('rank_changes');
      }
      if (_reEngagementEnabled) {
        await notificationService.subscribeToTopic('re_engagement');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission granted'),
            backgroundColor: HoneyTheme.deepHoney,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission denied'),
            backgroundColor: HoneyTheme.brownAccentDark,
          ),
        );
      }
    }
  }

  Widget _buildPermissionCard() {
    return Card(
      color: _permissionGranted
          ? HoneyTheme.cellUnvisited
          : HoneyTheme.warmCreamDark,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(HoneyTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPermissionHeader(),
            const SizedBox(height: HoneyTheme.spacingSm),
            _buildPermissionStatus(),
            if (!_permissionGranted) _buildEnableButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionHeader() {
    return Row(
      children: [
        Icon(
          _permissionGranted ? Icons.check_circle : Icons.error_outline,
          color: _permissionGranted
              ? HoneyTheme.deepHoney
              : HoneyTheme.brownAccentDark,
          size: HoneyTheme.iconSizeMd,
        ),
        const SizedBox(width: HoneyTheme.spacingSm),
        const Expanded(
          child: Text(
            'Permission Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: HoneyTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionStatus() {
    return Text(
      _permissionGranted
          ? 'Notifications are enabled'
          : 'Notifications are disabled',
      style: const TextStyle(fontSize: 14, color: HoneyTheme.textSecondary),
    );
  }

  Widget _buildEnableButton() {
    return Column(
      children: [
        const SizedBox(height: HoneyTheme.spacingMd),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isRequestingPermission ? null : _requestPermission,
            icon: _isRequestingPermission
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: HoneyTheme.textPrimary,
                    ),
                  )
                : const Icon(Icons.notifications_active),
            label: Text(
              _isRequestingPermission
                  ? 'Requesting...'
                  : 'Enable Notifications',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: HoneyTheme.deepHoney,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: HoneyTheme.spacingMd,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationToggles() {
    return Card(
      color: HoneyTheme.cellUnvisited,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildNotificationToggle(
            title: 'Daily Challenge',
            subtitle: 'Get notified when a new daily challenge is available',
            icon: Icons.calendar_today,
            value: _dailyChallengeEnabled,
            onChanged: _permissionGranted ? _toggleDailyChallenge : null,
          ),
          const Divider(height: 1, indent: 72, endIndent: 16),
          _buildNotificationToggle(
            title: 'Rank Changes',
            subtitle:
                'Get notified when your leaderboard rank changes significantly',
            icon: Icons.trending_up,
            value: _rankChangeEnabled,
            onChanged: _permissionGranted ? _toggleRankChange : null,
          ),
          const Divider(height: 1, indent: 72, endIndent: 16),
          _buildNotificationToggle(
            title: 'Re-engagement',
            subtitle: 'Get reminders to come back and play',
            icon: Icons.notifications_none,
            value: _reEngagementEnabled,
            onChanged: _permissionGranted ? _toggleReEngagement : null,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required void Function(bool)? onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: HoneyTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: HoneyTheme.textSecondary),
      ),
      value: value,
      onChanged: onChanged,
      activeTrackColor: HoneyTheme.honeyGoldLight,
      activeThumbColor: HoneyTheme.deepHoney,
      secondary: Icon(icon, color: HoneyTheme.honeyGold),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: HoneyTheme.honeyGold),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(HoneyTheme.spacingLg),
      children: [
        _buildPermissionCard(),
        const SizedBox(height: HoneyTheme.spacingXl),
        const Text(
          'Notification Types',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: HoneyTheme.textPrimary,
          ),
        ),
        const SizedBox(height: HoneyTheme.spacingMd),
        _buildNotificationToggles(),
        const SizedBox(height: HoneyTheme.spacingXl),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: HoneyTheme.spacingSm),
          child: Text(
            'Notifications help you stay engaged with daily challenges and track your progress. You can change these settings anytime.',
            style: TextStyle(
              fontSize: 12,
              color: HoneyTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoneyTheme.warmCream,
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            color: HoneyTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: HoneyTheme.honeyGold,
        iconTheme: const IconThemeData(color: HoneyTheme.textPrimary),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }
}
