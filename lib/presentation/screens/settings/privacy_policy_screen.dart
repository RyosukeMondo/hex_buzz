import 'package:flutter/material.dart';

import '../../theme/honey_theme.dart';

/// Displays the HexBuzz privacy policy.
///
/// A scrollable text screen covering data collection, usage,
/// third-party services, retention, and COPPA compliance.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoneyTheme.warmCream,
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
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
          _buildLastUpdated(context),
          const SizedBox(height: HoneyTheme.spacingXl),
          ..._buildAllSections(context),
          const SizedBox(height: HoneyTheme.spacingXl),
        ],
      ),
    );
  }

  List<Widget> _buildAllSections(BuildContext context) {
    return [
      ..._buildDataCollectionSections(context),
      ..._buildDataUsageSections(context),
      ..._buildRightsAndPolicySections(context),
    ];
  }

  List<Widget> _buildDataCollectionSections(BuildContext context) {
    return [
      _buildSection(
        context,
        title: 'Introduction',
        body: 'Welcome to HexBuzz ("we", "our", or "us"). We are '
            'committed to protecting your privacy and ensuring that '
            'your personal information is handled responsibly. This '
            'Privacy Policy explains what data we collect, how we '
            'use it, and your rights regarding your information.',
      ),
      _buildSection(
        context,
        title: 'Information We Collect',
        body: 'We collect the following types of information to '
            'provide and improve our services:\n\n'
            '  - Email address: Used for account authentication '
            'and account recovery.\n\n'
            '  - Game progress: Level completion data, scores, '
            'stars earned, and achievements are stored to '
            'preserve your progress across devices.\n\n'
            '  - Analytics data: Anonymous usage statistics such '
            'as session duration, levels played, and feature '
            'usage help us improve the game experience.\n\n'
            '  - Device information: Device type, operating '
            'system version, and app version are collected for '
            'compatibility and debugging purposes.',
      ),
    ];
  }

  List<Widget> _buildDataUsageSections(BuildContext context) {
    return [
      _buildSection(
        context,
        title: 'How We Use Your Data',
        body: 'Your information is used for the following purposes:\n\n'
            '  - Game functionality: Saving and syncing your '
            'progress, managing your account, and enabling '
            'features like daily challenges.\n\n'
            '  - Leaderboards: Displaying your scores and rank '
            'on public leaderboards (your display name is shown, '
            'not your email).\n\n'
            '  - Notifications: Sending you daily challenge '
            'reminders and rank change alerts if you have opted '
            'in.\n\n'
            '  - Improvements: Analyzing aggregate usage patterns '
            'to improve game design, fix bugs, and develop new '
            'features.',
      ),
      _buildSection(
        context,
        title: 'Third-Party Services',
        body: 'We use the following third-party services:\n\n'
            '  - Firebase (Google): For authentication, cloud '
            'storage, push notifications, and crash reporting. '
            'See Google\'s Privacy Policy for details.\n\n'
            '  - Google Analytics for Firebase: For anonymous '
            'usage analytics. Data is aggregated and does not '
            'personally identify you.\n\n'
            'These services may collect information as described '
            'in their respective privacy policies. We encourage '
            'you to review them.',
      ),
      _buildSection(
        context,
        title: 'Data Retention and Deletion',
        body: 'Your game data is retained as long as your account '
            'is active. You may request deletion of your account '
            'and all associated data at any time by contacting us '
            'at the email address below.\n\n'
            'Upon account deletion, we will remove your personal '
            'information and game data within 30 days. Some '
            'anonymized analytics data may be retained for '
            'statistical purposes.',
      ),
      _buildSection(
        context,
        title: 'Data Security',
        body: 'We implement industry-standard security measures to '
            'protect your data, including encryption in transit '
            'and at rest. However, no method of transmission over '
            'the internet is 100% secure, and we cannot guarantee '
            'absolute security.',
      ),
    ];
  }

  List<Widget> _buildRightsAndPolicySections(BuildContext context) {
    return [
      _buildSection(
        context,
        title: "Children's Privacy (COPPA)",
        body: 'HexBuzz is not directed at children under the age '
            'of 13. We do not knowingly collect personal '
            'information from children under 13. If we become '
            'aware that we have collected personal information '
            'from a child under 13 without parental consent, we '
            'will take steps to delete that information promptly.\n\n'
            'If you are a parent or guardian and believe your '
            'child has provided us with personal information, '
            'please contact us so we can take appropriate action.',
      ),
      _buildSection(
        context,
        title: 'Your Rights',
        body: 'You have the right to:\n\n'
            '  - Access the personal data we hold about you.\n\n'
            '  - Request correction of inaccurate data.\n\n'
            '  - Request deletion of your data.\n\n'
            '  - Opt out of notifications at any time through '
            'the app settings.\n\n'
            '  - Withdraw consent for data processing where '
            'applicable.',
      ),
      _buildSection(
        context,
        title: 'Changes to This Policy',
        body: 'We may update this Privacy Policy from time to '
            'time. We will notify you of significant changes '
            'through the app or by other means. Your continued '
            'use of HexBuzz after changes are posted constitutes '
            'acceptance of the updated policy.',
      ),
      _buildSection(
        context,
        title: 'Contact Us',
        body: 'If you have any questions or concerns about this '
            'Privacy Policy or our data practices, please contact '
            'us at:\n\n'
            'Email: privacy@hexbuzz.app',
      ),
    ];
  }

  Widget _buildLastUpdated(BuildContext context) {
    return Center(
      child: Text(
        'Last updated: March 20, 2026',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: HoneyTheme.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HoneyTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: HoneyTheme.brownAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: HoneyTheme.spacingSm),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: HoneyTheme.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
