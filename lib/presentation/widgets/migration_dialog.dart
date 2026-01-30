import 'package:flutter/material.dart';

/// Dialog shown before migrating guest data to Firebase account.
///
/// Informs the user about the migration process and asks for confirmation
/// before proceeding with syncing their local progress to the cloud.
class MigrationDialog extends StatelessWidget {
  final int levelsToMigrate;
  final int totalStars;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const MigrationDialog({
    super.key,
    required this.levelsToMigrate,
    required this.totalStars,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.cloud_upload, color: Colors.blue),
          SizedBox(width: 8),
          Text('Upgrade to Cloud Sync'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sign in to sync your progress across all your devices.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your local progress will be merged:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            icon: Icons.grid_on,
            label: 'Levels completed',
            value: '$levelsToMigrate',
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            icon: Icons.stars,
            label: 'Total stars earned',
            value: '$totalStars',
            color: Colors.amber,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your progress will be safe and accessible from any device.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: onConfirm,
          icon: const Icon(Icons.login),
          label: const Text('Sign In & Sync'),
        ),
      ],
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Shows the migration dialog and returns true if user confirmed.
Future<bool> showMigrationDialog(
  BuildContext context, {
  required int levelsToMigrate,
  required int totalStars,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => MigrationDialog(
      levelsToMigrate: levelsToMigrate,
      totalStars: totalStars,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    ),
  );

  return result ?? false;
}
