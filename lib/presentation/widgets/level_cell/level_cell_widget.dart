import 'package:flutter/material.dart';

import '../../theme/honey_theme.dart';

/// Widget that displays a single level cell in the level selection grid.
///
/// Shows:
/// - Level number
/// - Star rating (0-3 stars) for completed levels
/// - Lock icon for locked levels
///
/// Handles:
/// - Tap callback for unlocked levels
/// - Shake animation when tapping locked levels
class LevelCellWidget extends StatefulWidget {
  /// The level number to display (1-indexed).
  final int levelNumber;

  /// Number of stars earned (0-3).
  final int stars;

  /// Whether the level is unlocked and playable.
  final bool isUnlocked;

  /// Whether the level has been completed.
  final bool isCompleted;

  /// Callback when the cell is tapped.
  /// Only called for unlocked levels.
  final VoidCallback? onTap;

  /// Size of the cell (width and height).
  final double size;

  const LevelCellWidget({
    super.key,
    required this.levelNumber,
    this.stars = 0,
    this.isUnlocked = true,
    this.isCompleted = false,
    this.onTap,
    this.size = 80,
  }) : assert(stars >= 0 && stars <= 3, 'Stars must be between 0 and 3');

  @override
  State<LevelCellWidget> createState() => _LevelCellWidgetState();
}

class _LevelCellWidgetState extends State<LevelCellWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 0, end: 10), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 2),
        TweenSequenceItem(tween: Tween(begin: -10, end: 8), weight: 2),
        TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 2),
        TweenSequenceItem(tween: Tween(begin: -8, end: 4), weight: 2),
        TweenSequenceItem(tween: Tween(begin: 4, end: 0), weight: 1),
      ],
    ).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isUnlocked) {
      widget.onTap?.call();
    } else {
      _shakeController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          );
        },
        child: _buildCell(),
      ),
    );
  }

  Widget _buildCell() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: HoneycombDecorations.levelCell(
        isUnlocked: widget.isUnlocked,
        isCompleted: widget.isCompleted,
      ),
      child: widget.isUnlocked
          ? _buildUnlockedContent()
          : _buildLockedContent(),
    );
  }

  Widget _buildUnlockedContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.levelNumber.toString(),
          style: TextStyle(
            color: HoneyTheme.textPrimary,
            fontSize: widget.size * 0.3,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        _buildStarsRow(),
      ],
    );
  }

  Widget _buildLockedContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock, color: HoneyTheme.lockColor, size: widget.size * 0.35),
        const SizedBox(height: 4),
        Text(
          widget.levelNumber.toString(),
          style: TextStyle(
            color: HoneyTheme.lockColor,
            fontSize: widget.size * 0.2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStarsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isFilled = index < widget.stars;
        return Icon(
          isFilled ? Icons.star : Icons.star_border,
          color: isFilled ? HoneyTheme.starFilled : HoneyTheme.starEmpty,
          size: widget.size * 0.18,
        );
      }),
    );
  }
}
