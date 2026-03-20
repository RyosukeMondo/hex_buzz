import 'package:flutter/material.dart';

import '../../theme/honey_theme.dart';

/// Displays the HexBuzz Terms of Service.
///
/// A scrollable text screen covering acceptance, game rules,
/// user content, intellectual property, and liability.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoneyTheme.warmCream,
      appBar: AppBar(
        title: const Text(
          'Terms of Service',
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
      ..._buildAcceptanceAndAccountSections(context),
      ..._buildGameRulesAndContentSections(context),
      ..._buildLegalSections(context),
      ..._buildPolicySections(context),
    ];
  }

  List<Widget> _buildAcceptanceAndAccountSections(BuildContext context) {
    return [
      _buildSection(
        context,
        title: '1. Acceptance of Terms',
        body: 'By downloading, installing, or using HexBuzz '
            '("the App"), you agree to be bound by these Terms '
            'of Service ("Terms"). If you do not agree to these '
            'Terms, do not use the App.\n\n'
            'We reserve the right to modify these Terms at any '
            'time. Continued use of the App after changes are '
            'posted constitutes acceptance of the modified Terms.',
      ),
      _buildSection(
        context,
        title: '2. Account Registration',
        body: 'You may create an account to access certain '
            'features such as leaderboards, progress syncing, '
            'and social features. You are responsible for '
            'maintaining the confidentiality of your account '
            'credentials.\n\n'
            'You agree to provide accurate information when '
            'creating your account and to update it as needed. '
            'You are responsible for all activities that occur '
            'under your account.',
      ),
    ];
  }

  List<Widget> _buildGameRulesAndContentSections(BuildContext context) {
    return [
      _buildSection(
        context,
        title: '3. Game Rules and Fair Play',
        body: 'You agree to play HexBuzz fairly and in '
            'accordance with the intended game mechanics. The '
            'following activities are prohibited:\n\n'
            '  - Using cheats, exploits, automation software, '
            'bots, hacks, or any unauthorized third-party '
            'tools.\n\n'
            '  - Manipulating game data, scores, or leaderboard '
            'rankings through any unauthorized means.\n\n'
            '  - Interfering with other players\' enjoyment of '
            'the game or disrupting game services.\n\n'
            '  - Creating multiple accounts to gain unfair '
            'advantages.\n\n'
            'Violation of these rules may result in account '
            'suspension or termination.',
      ),
      _buildSection(
        context,
        title: '4. User Content',
        body: 'HexBuzz allows you to create custom levels using '
            'the Level Editor. By creating and sharing levels, '
            'you:\n\n'
            '  - Retain ownership of your created content.\n\n'
            '  - Grant HexBuzz a non-exclusive, worldwide, '
            'royalty-free license to host, display, and '
            'distribute your levels within the App.\n\n'
            '  - Agree not to create levels containing offensive, '
            'inappropriate, or infringing content.\n\n'
            'We reserve the right to remove user-created content '
            'that violates these Terms or is deemed inappropriate.',
      ),
      _buildSection(
        context,
        title: '5. Intellectual Property',
        body: 'All content in HexBuzz, including but not limited '
            'to graphics, designs, game mechanics, audio, text, '
            'and software, is the intellectual property of '
            'HexBuzz and its licensors.\n\n'
            'You may not copy, modify, distribute, sell, or '
            'lease any part of the App or its content, nor may '
            'you reverse engineer or attempt to extract the '
            'source code, except as permitted by law.',
      ),
    ];
  }

  List<Widget> _buildLegalSections(BuildContext context) {
    return [
      _buildSection(
        context,
        title: '6. In-App Purchases',
        body: 'HexBuzz may offer optional in-app purchases. All '
            'purchases are final and non-refundable, except as '
            'required by applicable law or the policies of your '
            'app store platform.\n\n'
            'Virtual items and currency purchased within the App '
            'have no real-world monetary value and cannot be '
            'exchanged, transferred, or redeemed outside of the '
            'App.',
      ),
      _buildSection(
        context,
        title: '7. Limitation of Liability',
        body: 'HexBuzz is provided "as is" and "as available" '
            'without warranties of any kind, either express or '
            'implied.\n\n'
            'To the maximum extent permitted by applicable law, '
            'we shall not be liable for any indirect, incidental, '
            'special, consequential, or punitive damages, or any '
            'loss of profits or revenues, whether incurred '
            'directly or indirectly.\n\n'
            'Our total liability for any claims arising from or '
            'related to the App shall not exceed the amount you '
            'have paid us in the 12 months prior to the claim.',
      ),
      _buildSection(
        context,
        title: '8. Termination',
        body: 'We may suspend or terminate your access to the '
            'App at any time, with or without cause, and with '
            'or without notice. Upon termination, your right to '
            'use the App will immediately cease.\n\n'
            'You may delete your account at any time through the '
            'App settings or by contacting us.',
      ),
    ];
  }

  List<Widget> _buildPolicySections(BuildContext context) {
    return [
      _buildSection(
        context,
        title: '9. Changes to Terms',
        body: 'We reserve the right to modify these Terms at any '
            'time. We will provide notice of significant changes '
            'through the App or by other appropriate means.\n\n'
            'Your continued use of HexBuzz after changes are '
            'posted constitutes your acceptance of the revised '
            'Terms. If you do not agree to the new Terms, you '
            'should stop using the App.',
      ),
      _buildSection(
        context,
        title: '10. Governing Law',
        body: 'These Terms shall be governed by and construed in '
            'accordance with applicable laws, without regard to '
            'conflict of law principles.',
      ),
      _buildSection(
        context,
        title: '11. Contact Us',
        body: 'If you have any questions about these Terms of '
            'Service, please contact us at:\n\n'
            'Email: legal@hexbuzz.app',
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
