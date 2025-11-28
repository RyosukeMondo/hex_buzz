import 'package:flutter/material.dart';

import '../../theme/honey_theme.dart';
import '../assets/game_assets.dart';

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

  /// Best completion time for this level (null if not completed).
  final Duration? bestTime;

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
    this.bestTime,
    this.onTap,
    this.size = HoneyTheme.levelCellSize,
  }) : assert(stars >= 0 && stars <= 3, 'Stars must be between 0 and 3');

  @override
  State<LevelCellWidget> createState() => _LevelCellWidgetState();
}

class _LevelCellWidgetState extends State<LevelCellWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  /// Whether reduced motion is enabled.
  bool _reduceMotion = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isUnlocked) {
      widget.onTap?.call();
    } else if (!_reduceMotion) {
      // Only animate shake if reduced motion is not enabled.
      _shakeController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String semanticsLabel;
    if (widget.isUnlocked) {
      if (widget.isCompleted) {
        semanticsLabel =
            'Level ${widget.levelNumber}, completed with ${widget.stars} '
            '${widget.stars == 1 ? 'star' : 'stars'}';
      } else {
        semanticsLabel = 'Level ${widget.levelNumber}, not completed';
      }
    } else {
      semanticsLabel = 'Level ${widget.levelNumber}, locked';
    }

    return Semantics(
      label: semanticsLabel,
      button: widget.isUnlocked,
      enabled: widget.isUnlocked,
      child: GestureDetector(
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
      ),
    );
  }

  Widget _buildCell() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background texture from SD-generated asset
        AssetImageWithFallback(
          assetPath: widget.isUnlocked
              ? GameAssetPaths.levelButton
              : GameAssetPaths.levelButton,
          width: widget.size,
          height: widget.size,
          fallback: Container(
            width: widget.size,
            height: widget.size,
            decoration: HoneycombDecorations.levelCell(
              isUnlocked: widget.isUnlocked,
              isCompleted: widget.isCompleted,
            ),
          ),
        ),
        // Overlay for locked state
        if (!widget.isUnlocked)
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
            ),
          ),
        // Content on top
        widget.isUnlocked ? _buildUnlockedContent() : _buildLockedContent(),
      ],
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
            fontSize: widget.size * 0.45,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: HoneyTheme.spacingXs),
        _buildStarsRow(),
        if (widget.isCompleted && widget.bestTime != null) ...[
          const SizedBox(height: HoneyTheme.spacingXs / 2),
          _buildTimeDisplay(),
        ],
      ],
    );
  }

  /// Formats duration as MM:SS for times >= 60s, or SS.ss for times < 60s.
  String _formatTime(Duration duration) {
    final totalSeconds = duration.inMilliseconds / 1000;
    if (totalSeconds >= 60) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    } else {
      final seconds = duration.inSeconds;
      final centiseconds = (duration.inMilliseconds % 1000) ~/ 10;
      return '$seconds.${centiseconds.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildTimeDisplay() {
    return Text(
      _formatTime(widget.bestTime!),
      style: TextStyle(
        color: HoneyTheme.textSecondary,
        fontSize: widget.size * 0.12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildLockedContent() {
    final iconSize = widget.size * 0.45;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AssetImageWithFallback(
          assetPath: GameAssetPaths.lockIcon,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
          fallback: Icon(
            Icons.lock,
            color: HoneyTheme.lockColor,
            size: iconSize,
          ),
        ),
        const SizedBox(height: HoneyTheme.spacingXs),
        Text(
          widget.levelNumber.toString(),
          style: TextStyle(
            color: HoneyTheme.lockColor,
            fontSize: widget.size * 0.28,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStarsRow() {
    final starSize = widget.size * 0.22;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isFilled = index < widget.stars;
        return isFilled
            ? _buildFilledStar(starSize)
            : _buildEmptyStar(starSize);
      }),
    );
  }

  Widget _buildFilledStar(double size) {
    return AssetImageWithFallback(
      assetPath: GameAssetPaths.starFilled,
      width: size,
      height: size,
      fit: BoxFit.contain,
      fallback: _buildFallbackFilledStar(size),
    );
  }

  Widget _buildFallbackFilledStar(double size) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: HoneyTheme.starFilled.withValues(alpha: 0.4),
            blurRadius: 2,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(Icons.star, color: HoneyTheme.starFilled, size: size),
    );
  }

  Widget _buildEmptyStar(double size) {
    return AssetImageWithFallback(
      assetPath: GameAssetPaths.starEmpty,
      width: size,
      height: size,
      fit: BoxFit.contain,
      fallback: _buildFallbackEmptyStar(size),
    );
  }

  Widget _buildFallbackEmptyStar(double size) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outline/stroke layer
        Icon(Icons.star, color: HoneyTheme.starEmptyOutline, size: size),
        // Inner fill slightly smaller to create stroke effect
        Icon(Icons.star, color: HoneyTheme.starEmpty, size: size * 0.85),
      ],
    );
  }
}
