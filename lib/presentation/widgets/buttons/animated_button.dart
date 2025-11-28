import 'package:flutter/material.dart';

/// A reusable button wrapper that provides tactile tap feedback animation.
///
/// Wraps any child widget and animates it with a subtle scale effect:
/// - On press: Scale to 0.95 over 100ms
/// - On release: Scale back to 1.0 over 100ms
///
/// Respects system reduced motion settings via [MediaQuery.disableAnimations].
class AnimatedButton extends StatefulWidget {
  /// The child widget to wrap with animation.
  final Widget child;

  /// Callback triggered when the button is tapped.
  final VoidCallback? onTap;

  /// Callback triggered when long press is detected.
  final VoidCallback? onLongPress;

  /// The scale factor when pressed. Defaults to 0.95.
  final double pressedScale;

  /// Animation duration for both press and release. Defaults to 100ms.
  final Duration animationDuration;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.95,
    this.animationDuration = const Duration(milliseconds: 100),
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!_shouldAnimate) return;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (!_shouldAnimate) return;
    _controller.reverse();
  }

  void _onTapCancel() {
    if (!_shouldAnimate) return;
    _controller.reverse();
  }

  /// Check if animations should be disabled per system settings.
  bool get _shouldAnimate {
    return !MediaQuery.of(context).disableAnimations;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // If animations disabled, just show static child.
          if (!_shouldAnimate) {
            return child!;
          }
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: widget.child,
      ),
    );
  }
}
