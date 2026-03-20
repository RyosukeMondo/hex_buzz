import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_event.dart';
import '../../../domain/models/user_level.dart';
import '../../../domain/services/level_editor_service.dart';
import '../../../main.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/editor_provider.dart';
import '../../theme/honey_theme.dart';

/// Provider that loads the current user's created levels.
final myLevelsProvider = FutureProvider<List<UserLevel>>((ref) async {
  final user = ref.watch(authProvider).valueOrNull;
  final userId = user?.id ?? 'guest';
  final repository = ref.watch(userLevelRepositoryProvider);
  return repository.getMyLevels(userId);
});

/// Screen showing the user's created levels.
///
/// Displays a list of levels with preview information, share codes,
/// and actions for editing, deleting, and importing levels.
class MyLevelsScreen extends ConsumerWidget {
  const MyLevelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(myLevelsProvider);

    return Scaffold(
      backgroundColor: HoneyTheme.warmCream,
      appBar: AppBar(
        title: const Text('My Levels'),
        backgroundColor: HoneyTheme.honeyGold,
        foregroundColor: HoneyTheme.textOnPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _importLevel(context, ref),
            tooltip: 'Import Level',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewLevel(context, ref),
        backgroundColor: HoneyTheme.honeyGold,
        foregroundColor: HoneyTheme.textOnPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Create New'),
      ),
      body: levelsAsync.when(
        data: (levels) => _buildLevelsList(context, ref, levels),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: HoneyTheme.iconSizeLg,
                color: Colors.red,
              ),
              const SizedBox(height: HoneyTheme.spacingLg),
              Text('Error loading levels: $error'),
              const SizedBox(height: HoneyTheme.spacingLg),
              ElevatedButton(
                onPressed: () => ref.invalidate(myLevelsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelsList(
    BuildContext context,
    WidgetRef ref,
    List<UserLevel> levels,
  ) {
    if (levels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.create,
              size: HoneyTheme.iconSizeXl,
              color: HoneyTheme.brownAccent.withValues(alpha: 0.5),
            ),
            const SizedBox(height: HoneyTheme.spacingLg),
            Text(
              'No levels created yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HoneyTheme.textSecondary,
              ),
            ),
            const SizedBox(height: HoneyTheme.spacingSm),
            Text(
              'Tap "Create New" to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HoneyTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(HoneyTheme.spacingLg),
      itemCount: levels.length,
      itemBuilder: (context, index) {
        return _LevelCard(
          userLevel: levels[index],
          onTap: () => _editLevel(context, ref, levels[index]),
          onDelete: () => _deleteLevel(context, ref, levels[index]),
          onShare: () => _shareLevel(context, ref, levels[index]),
        );
      },
    );
  }

  void _createNewLevel(BuildContext context, WidgetRef ref) {
    ref.read(editorProvider.notifier).clear();
    Navigator.of(context).pushNamed(AppRoutes.editor);
  }

  void _editLevel(BuildContext context, WidgetRef ref, UserLevel userLevel) {
    ref.read(editorProvider.notifier).loadLevel(userLevel.level);
    Navigator.of(context).pushNamed(AppRoutes.editor);
  }

  Future<void> _deleteLevel(
    BuildContext context,
    WidgetRef ref,
    UserLevel userLevel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Level'),
        content: const Text(
          'Are you sure you want to delete this level?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repository = ref.read(userLevelRepositoryProvider);
      await repository.deleteLevel(userLevel.id);
      ref.invalidate(myLevelsProvider);
    }
  }

  void _shareLevel(
    BuildContext context,
    WidgetRef ref,
    UserLevel userLevel,
  ) {
    if (userLevel.shareCode == null) return;

    ref.read(analyticsServiceProvider).trackEvent(
      AnalyticsEventType.editorLevelShared,
      properties: {'levelId': userLevel.id},
    );

    Clipboard.setData(ClipboardData(text: userLevel.shareCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share code copied to clipboard'),
        backgroundColor: HoneyTheme.brownAccent,
      ),
    );
  }

  Future<void> _importLevel(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();

    final shareCode = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Level'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Paste share code here',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (shareCode == null || shareCode.isEmpty) return;

    final service = const LevelEditorService();
    final level = service.decodeShareCode(shareCode);

    if (level == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid share code'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    ref.read(editorProvider.notifier).loadLevel(level);
    if (context.mounted) {
      Navigator.of(context).pushNamed(AppRoutes.editor);
    }
  }
}

/// Card widget displaying a single user-created level.
class _LevelCard extends StatelessWidget {
  final UserLevel userLevel;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const _LevelCard({
    required this.userLevel,
    required this.onTap,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: HoneyTheme.spacingMd),
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(HoneyTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(HoneyTheme.spacingLg),
          child: Row(
            children: [
              _buildPreview(context),
              const SizedBox(width: HoneyTheme.spacingLg),
              Expanded(child: _buildInfo(context)),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: HoneyTheme.honeyGoldLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(HoneyTheme.radiusSm),
        border: Border.all(color: HoneyTheme.honeyGold),
      ),
      child: Center(
        child: Text(
          '${userLevel.level.size}',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: HoneyTheme.honeyGoldDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    final dateStr = _formatDate(userLevel.createdAt);
    final cellCount = userLevel.level.cells.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Size ${userLevel.level.size} - $cellCount cells',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: HoneyTheme.spacingXs),
        Text(
          'Created $dateStr',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (userLevel.shareCode != null) ...[
          const SizedBox(height: HoneyTheme.spacingXs),
          Text(
            'Code: ${_truncateCode(userLevel.shareCode!)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: HoneyTheme.brownAccent,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.share, size: 20),
          onPressed: onShare,
          tooltip: 'Share',
          color: HoneyTheme.brownAccent,
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: onTap,
          tooltip: 'Edit',
          color: HoneyTheme.brownAccent,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _truncateCode(String code) {
    if (code.length <= 16) return code;
    return '${code.substring(0, 16)}...';
  }
}
