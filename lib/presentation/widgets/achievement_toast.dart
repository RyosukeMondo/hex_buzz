import 'package:flutter/material.dart';

import '../../domain/models/achievement.dart';
import '../theme/honey_theme.dart';

/// Shows a golden toast notification when an achievement is unlocked.
///
/// Displays achievement icon and name with honey theme styling.
/// Auto-dismisses after 3 seconds.
class AchievementToast {
  AchievementToast._();

  /// Shows a toast for a newly unlocked achievement.
  static void show(BuildContext context, Achievement achievement) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _AchievementToastWidget(
        achievement: achievement,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }

  /// Shows toasts for multiple achievements, staggered by delay.
  static void showMultiple(
    BuildContext context,
    List<Achievement> achievements,
  ) {
    for (var i = 0; i < achievements.length; i++) {
      Future.delayed(Duration(milliseconds: i * 500), () {
        if (context.mounted) {
          show(context, achievements[i]);
        }
      });
    }
  }
}

/// Animated toast widget for a single achievement unlock.
class _AchievementToastWidget extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback onDismiss;

  const _AchievementToastWidget({
    required this.achievement,
    required this.onDismiss,
  });

  @override
  State<_AchievementToastWidget> createState() =>
      _AchievementToastWidgetState();
}

class _AchievementToastWidgetState extends State<_AchievementToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + HoneyTheme.spacingLg,
      left: HoneyTheme.spacingLg,
      right: HoneyTheme.spacingLg,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _buildToastContent(context),
        ),
      ),
    );
  }

  Widget _buildToastContent(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: HoneyTheme.spacingLg,
          vertical: HoneyTheme.spacingMd,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
          border: Border.all(color: HoneyTheme.honeyGold, width: 2),
          boxShadow: [
            BoxShadow(
              color: HoneyTheme.honeyGold.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: HoneyTheme.honeyGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(HoneyTheme.radiusSm),
              ),
              child: const Icon(
                Icons.emoji_events,
                color: HoneyTheme.deepHoney,
                size: HoneyTheme.iconSizeMd,
              ),
            ),
            const SizedBox(width: HoneyTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Achievement Unlocked!',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: HoneyTheme.deepHoney,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.achievement.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: HoneyTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _dismiss,
              child: const Icon(
                Icons.close,
                size: 18,
                color: HoneyTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
