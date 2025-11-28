import 'package:flutter/material.dart';

/// A widget that animates its child with a scale and opacity effect when
/// the [isVisited] property changes to true.
///
/// Used to provide satisfying visual feedback when hex grid cells are visited
/// during gameplay. The animation runs once when the cell becomes visited.
///
/// Respects system reduced motion settings via [MediaQuery.disableAnimations].
///
/// Animation properties:
/// - Scale: 0.8 -> 1.0
/// - Opacity: 0.0 -> 1.0
/// - Duration: 200ms
/// - Curve: easeOutCubic
class AnimatedCellPaint extends StatefulWidget {
  /// Whether the cell has been visited.
  /// Animation triggers when this changes from false to true.
  final bool isVisited;

  /// The child widget to animate.
  final Widget child;

  const AnimatedCellPaint({
    super.key,
    required this.isVisited,
    required this.child,
  });

  @override
  State<AnimatedCellPaint> createState() => _AnimatedCellPaintState();
}

class _AnimatedCellPaintState extends State<AnimatedCellPaint>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  /// Track if we've already animated to avoid re-triggering on rebuilds.
  bool _hasAnimated = false;

  /// Whether reduced motion is enabled.
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // If already visited on init, skip animation and show final state.
    if (widget.isVisited) {
      _controller.value = 1.0;
      _hasAnimated = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;

    // If reduce motion is enabled and we haven't animated yet, jump to final state.
    if (_reduceMotion && !_hasAnimated && widget.isVisited) {
      _controller.value = 1.0;
      _hasAnimated = true;
    }
  }

  @override
  void didUpdateWidget(AnimatedCellPaint oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger animation only when isVisited changes from false to true
    // and we haven't animated yet.
    if (widget.isVisited && !oldWidget.isVisited && !_hasAnimated) {
      _hasAnimated = true;
      if (_reduceMotion) {
        // Skip animation, jump to final state.
        _controller.value = 1.0;
      } else {
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If not visited, show nothing (or could show the child with no effect).
    if (!widget.isVisited) {
      return const SizedBox.shrink();
    }

    // If reduced motion, show static final state.
    if (_reduceMotion) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(scale: _scaleAnimation.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}
