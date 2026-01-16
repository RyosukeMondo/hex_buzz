import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';

/// A button widget with hover state support for desktop platforms
///
/// Extends the basic button functionality with:
/// - Mouse cursor changes on hover
/// - Visual feedback on hover (brightness/color change)
/// - Scale animation on press
/// - Respects system accessibility settings (disableAnimations)
class HoverButton extends StatefulWidget {
  const HoverButton({
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.hoverColor,
    this.borderRadius,
    this.padding,
    this.elevation = 2.0,
    this.hoverElevation = 4.0,
    super.key,
  });

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Child widget to display
  final Widget child;

  /// Background color when not hovered
  final Color? backgroundColor;

  /// Background color when hovered (defaults to lighter backgroundColor)
  final Color? hoverColor;

  /// Border radius for the button
  final BorderRadius? borderRadius;

  /// Padding inside the button
  final EdgeInsetsGeometry? padding;

  /// Elevation when not hovered
  final double elevation;

  /// Elevation when hovered
  final double hoverElevation;

  @override
  State<HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  BoxDecoration _buildDecoration(Color currentColor, double currentElevation) {
    return BoxDecoration(
      color: currentColor,
      borderRadius: widget.borderRadius ?? BorderRadius.circular(12.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: currentElevation,
          offset: Offset(0, currentElevation / 2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    final backgroundColor = widget.backgroundColor ?? HoneyTheme.honeyGold;
    final hoverColor =
        widget.hoverColor ?? Color.lerp(backgroundColor, Colors.white, 0.15)!;

    final currentColor = _isHovered ? hoverColor : backgroundColor;
    final currentElevation = _isHovered
        ? widget.hoverElevation
        : widget.elevation;

    return MouseRegion(
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: widget.onPressed != null
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapUp: widget.onPressed != null
            ? (_) {
                setState(() => _isPressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: widget.onPressed != null
            ? () => setState(() => _isPressed = false)
            : null,
        child: AnimatedScale(
          scale: _isPressed && !disableAnimations ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          child: AnimatedContainer(
            duration: disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            decoration: _buildDecoration(currentColor, currentElevation),
            padding:
                widget.padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// A text button with hover support (flat, no elevation)
class HoverTextButton extends StatefulWidget {
  const HoverTextButton({
    required this.onPressed,
    required this.child,
    this.textColor,
    this.hoverTextColor,
    this.backgroundColor,
    this.hoverBackgroundColor,
    this.borderRadius,
    this.padding,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? textColor;
  final Color? hoverTextColor;
  final Color? backgroundColor;
  final Color? hoverBackgroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  State<HoverTextButton> createState() => _HoverTextButtonState();
}

class _HoverTextButtonState extends State<HoverTextButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  Widget _buildContent(BuildContext context, Color currentTextColor) {
    return DefaultTextStyle(
      style: DefaultTextStyle.of(
        context,
      ).style.copyWith(color: currentTextColor),
      child: widget.child,
    );
  }

  Widget _buildInteractiveChild(
    BuildContext context,
    bool disableAnimations,
    Color currentTextColor,
    Color currentBackgroundColor,
  ) {
    return AnimatedScale(
      scale: _isPressed && !disableAnimations ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      child: AnimatedContainer(
        duration: disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: currentBackgroundColor,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8.0),
        ),
        padding:
            widget.padding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: _buildContent(context, currentTextColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    final textColor = widget.textColor ?? theme.primaryColor;
    final hoverTextColor =
        widget.hoverTextColor ?? Color.lerp(textColor, Colors.white, 0.2)!;

    final backgroundColor = widget.backgroundColor ?? Colors.transparent;
    final hoverBackgroundColor =
        widget.hoverBackgroundColor ??
        theme.primaryColor.withValues(alpha: 0.1);

    final currentTextColor = _isHovered ? hoverTextColor : textColor;
    final currentBackgroundColor = _isHovered
        ? hoverBackgroundColor
        : backgroundColor;

    return MouseRegion(
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: widget.onPressed != null
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapUp: widget.onPressed != null
            ? (_) {
                setState(() => _isPressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: widget.onPressed != null
            ? () => setState(() => _isPressed = false)
            : null,
        child: _buildInteractiveChild(
          context,
          disableAnimations,
          currentTextColor,
          currentBackgroundColor,
        ),
      ),
    );
  }
}

/// An icon button with hover support
class HoverIconButton extends StatefulWidget {
  const HoverIconButton({
    required this.icon,
    required this.onPressed,
    this.iconColor,
    this.hoverIconColor,
    this.backgroundColor,
    this.hoverBackgroundColor,
    this.size = 40.0,
    this.iconSize = 24.0,
    this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final Color? hoverIconColor;
  final Color? backgroundColor;
  final Color? hoverBackgroundColor;
  final double size;
  final double iconSize;
  final String? tooltip;

  @override
  State<HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<HoverIconButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  Widget _buildButton(
    bool disableAnimations,
    Color currentIconColor,
    Color currentBackgroundColor,
  ) {
    return MouseRegion(
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: widget.onPressed != null
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapUp: widget.onPressed != null
            ? (_) {
                setState(() => _isPressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: widget.onPressed != null
            ? () => setState(() => _isPressed = false)
            : null,
        child: AnimatedScale(
          scale: _isPressed && !disableAnimations ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          child: AnimatedContainer(
            duration: disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: currentBackgroundColor,
              borderRadius: BorderRadius.circular(widget.size / 2),
            ),
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: currentIconColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    final iconColor =
        widget.iconColor ?? theme.iconTheme.color ?? Colors.black87;
    final hoverIconColor = widget.hoverIconColor ?? theme.primaryColor;

    final backgroundColor = widget.backgroundColor ?? Colors.transparent;
    final hoverBackgroundColor =
        widget.hoverBackgroundColor ??
        theme.primaryColor.withValues(alpha: 0.1);

    final currentIconColor = _isHovered ? hoverIconColor : iconColor;
    final currentBackgroundColor = _isHovered
        ? hoverBackgroundColor
        : backgroundColor;

    final button = _buildButton(
      disableAnimations,
      currentIconColor,
      currentBackgroundColor,
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}
