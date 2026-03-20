import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_event.dart';
import '../../../domain/models/editor_state.dart';
import '../../../domain/models/game_mode.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/editor_provider.dart';
import '../../providers/game_provider.dart';
import '../../theme/honey_theme.dart';
import '../../widgets/editor_hex_grid.dart';
import '../game/game_screen.dart';

/// Main level editor screen for creating user-generated levels.
///
/// Provides a hex grid in editor mode with a tool palette, grid size
/// selector, validation, save, test play, and clear functionality.
class LevelEditorScreen extends ConsumerWidget {
  const LevelEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);

    return Scaffold(
      backgroundColor: HoneyTheme.warmCream,
      appBar: _buildAppBar(context, ref, editorState),
      body: Column(
        children: [
          _buildValidationBanner(context, editorState),
          Expanded(child: _buildEditorGrid(ref, editorState)),
          _buildToolPalette(context, ref, editorState),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    EditorState editorState,
  ) {
    return AppBar(
      title: const Text('Level Editor'),
      backgroundColor: HoneyTheme.honeyGold,
      foregroundColor: HoneyTheme.textOnPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Back',
      ),
      actions: [
        _buildGridSizeSelector(ref, editorState),
        _buildAutoCheckpointsButton(ref),
        _buildClearButton(ref),
        _buildValidateButton(ref),
        _buildTestPlayButton(context, ref, editorState),
        _buildSaveButton(context, ref, editorState),
      ],
    );
  }

  Widget _buildGridSizeSelector(WidgetRef ref, EditorState editorState) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.grid_on),
      tooltip: 'Grid Size',
      initialValue: editorState.gridSize,
      onSelected: (size) {
        ref.read(editorProvider.notifier).setGridSize(size);
      },
      itemBuilder: (context) => [
        for (var size = 2; size <= 6; size++)
          PopupMenuItem(
            value: size,
            child: Text(
              'Size $size',
              style: TextStyle(
                fontWeight:
                    size == editorState.gridSize
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAutoCheckpointsButton(WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.auto_fix_high),
      onPressed: () {
        ref.read(editorProvider.notifier).autoPlaceCheckpoints();
      },
      tooltip: 'Auto-place checkpoints',
    );
  }

  Widget _buildClearButton(WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.delete_outline),
      onPressed: () => ref.read(editorProvider.notifier).clear(),
      tooltip: 'Clear',
    );
  }

  Widget _buildValidateButton(WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.check_circle_outline),
      onPressed: () => ref.read(editorProvider.notifier).validate(),
      tooltip: 'Validate',
    );
  }

  Widget _buildTestPlayButton(
    BuildContext context,
    WidgetRef ref,
    EditorState editorState,
  ) {
    return IconButton(
      icon: const Icon(Icons.play_arrow),
      onPressed: editorState.isValid
          ? () => _testPlay(context, ref, editorState)
          : null,
      tooltip: 'Test Play',
    );
  }

  Widget _buildSaveButton(
    BuildContext context,
    WidgetRef ref,
    EditorState editorState,
  ) {
    return IconButton(
      icon: const Icon(Icons.save),
      onPressed: editorState.isValid
          ? () => _saveLevel(context, ref)
          : null,
      tooltip: 'Save',
    );
  }

  Widget _buildValidationBanner(
    BuildContext context,
    EditorState editorState,
  ) {
    if (editorState.validationError == null && !editorState.isValid) {
      return const SizedBox.shrink();
    }

    final isValid = editorState.isValid;
    final hasWarnings = editorState.warnings.isNotEmpty;

    final Color backgroundColor;
    final Color iconColor;
    final Color textColor;
    final IconData icon;
    final String message;

    if (isValid && hasWarnings) {
      backgroundColor = Colors.orange.shade50;
      iconColor = Colors.orange.shade700;
      textColor = Colors.orange.shade800;
      icon = Icons.warning_amber;
      message = editorState.warnings.join(', ');
    } else if (isValid) {
      backgroundColor = Colors.green.shade50;
      iconColor = Colors.green.shade700;
      textColor = Colors.green.shade800;
      icon = Icons.check_circle;
      message = 'Level is valid and solvable';
    } else {
      backgroundColor = Colors.red.shade50;
      iconColor = Colors.red.shade700;
      textColor = Colors.red.shade800;
      icon = Icons.error;
      message = editorState.validationError ?? 'Invalid level';
    }

    final semanticLabel = isValid
        ? 'Level is valid'
        : 'Level has errors: $message';

    return Semantics(
      label: semanticLabel,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: HoneyTheme.spacingLg,
          vertical: HoneyTheme.spacingSm,
        ),
        color: backgroundColor,
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(icon, color: iconColor, size: HoneyTheme.iconSizeMd),
            ),
            const SizedBox(width: HoneyTheme.spacingSm),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorGrid(WidgetRef ref, EditorState editorState) {
    return Padding(
      padding: const EdgeInsets.all(HoneyTheme.spacingLg),
      child: EditorHexGrid(
        editorState: editorState,
        onCellTapped: (q, r) {
          ref.read(editorProvider.notifier).tapCell(q, r);
        },
        onEdgeTapped: (q1, r1, q2, r2) {
          ref.read(editorProvider.notifier).tapEdge(q1, r1, q2, r2);
        },
      ),
    );
  }

  Widget _buildToolPalette(
    BuildContext context,
    WidgetRef ref,
    EditorState editorState,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HoneyTheme.spacingLg,
        vertical: HoneyTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ToolButton(
              tool: EditorTool.select,
              icon: Icons.touch_app,
              label: 'Select',
              isActive: editorState.currentTool == EditorTool.select,
              onTap: () {
                ref.read(editorProvider.notifier).setTool(EditorTool.select);
              },
            ),
            _ToolButton(
              tool: EditorTool.wall,
              icon: Icons.border_all,
              label: 'Wall',
              isActive: editorState.currentTool == EditorTool.wall,
              onTap: () {
                ref.read(editorProvider.notifier).setTool(EditorTool.wall);
              },
            ),
            _ToolButton(
              tool: EditorTool.checkpoint,
              icon: Icons.flag,
              label: 'Checkpoint',
              isActive: editorState.currentTool == EditorTool.checkpoint,
              onTap: () {
                ref
                    .read(editorProvider.notifier)
                    .setTool(EditorTool.checkpoint);
              },
            ),
            _ToolButton(
              tool: EditorTool.eraser,
              icon: Icons.cleaning_services,
              label: 'Eraser',
              isActive: editorState.currentTool == EditorTool.eraser,
              onTap: () {
                ref.read(editorProvider.notifier).setTool(EditorTool.eraser);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _testPlay(
    BuildContext context,
    WidgetRef ref,
    EditorState editorState,
  ) {
    final level = editorState.toLevel();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProviderScope(
          overrides: [
            gameConfigProvider.overrideWithValue(
              GameConfig(level: level, mode: GameMode.practice),
            ),
          ],
          child: const GameScreen(),
        ),
      ),
    );
  }

  Future<void> _saveLevel(BuildContext context, WidgetRef ref) async {
    await ref.read(editorProvider.notifier).saveLevel();

    ref.read(analyticsServiceProvider).trackEvent(
      AnalyticsEventType.editorLevelCreated,
      properties: {
        'gridSize': ref.read(editorProvider).gridSize,
      },
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Level saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

/// A single tool button in the editor palette.
class _ToolButton extends StatelessWidget {
  final EditorTool tool;
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolButton({
    required this.tool,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeState = isActive ? ', selected' : '';
    return Semantics(
      label: '$label tool$activeState',
      button: true,
      selected: isActive,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.symmetric(
            horizontal: HoneyTheme.spacingMd,
            vertical: HoneyTheme.spacingSm,
          ),
          decoration: BoxDecoration(
            color: isActive ? HoneyTheme.honeyGold : Colors.transparent,
            borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
            border: Border.all(
              color: isActive
                  ? HoneyTheme.honeyGoldDark
                  : HoneyTheme.cellBorder,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive
                    ? HoneyTheme.textPrimary
                    : HoneyTheme.brownAccent,
                size: HoneyTheme.iconSizeMd,
              ),
              const SizedBox(height: HoneyTheme.spacingXs),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? HoneyTheme.textPrimary
                      : HoneyTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
