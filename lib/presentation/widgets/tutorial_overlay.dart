import 'package:flutter/material.dart';

import '../theme/honey_theme.dart';

/// A coach-mark style overlay that displays tutorial instructions.
///
/// Shows a styled instruction card at the top of the screen with
/// a semi-transparent backdrop. Supports an optional pulsing indicator
/// arrow pointing downward toward the grid area.
class TutorialOverlay extends StatefulWidget {
  /// Primary instruction text.
  final String instruction;

  /// Secondary subtitle text shown below the instruction.
  final String subtitle;

  /// Whether to show a pulsing arrow pointing downward.
  final bool showArrow;

  /// Label for the action button (e.g. "Next", "Got it").
  /// If null, no button is shown (step waits for grid interaction).
  final String? buttonLabel;

  /// Callback when the action button is tapped.
  final VoidCallback? onButtonTap;

  /// Whether to show the "Skip Tutorial" button.
  final bool showSkipButton;

  /// Callback when "Skip Tutorial" is tapped.
  final VoidCallback? onSkip;

  const TutorialOverlay({
    super.key,
    required this.instruction,
    required this.subtitle,
    this.showArrow = false,
    this.buttonLabel,
    this.onButtonTap,
    this.showSkipButton = true,
    this.onSkip,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _arrowController;
  late Animation<double> _arrowOffset;

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _arrowOffset = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startArrowAnimation();
  }

  void _startArrowAnimation() {
    if (!widget.showArrow) return;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _arrowController.value = 0.5;
      return;
    }
    if (!_arrowController.isAnimating) {
      _arrowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showArrow && !_arrowController.isAnimating) {
      _startArrowAnimation();
    } else if (!widget.showArrow && _arrowController.isAnimating) {
      _arrowController.stop();
    }
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInstructionCard(context),
        if (widget.showArrow) _buildPulsingArrow(),
      ],
    );
  }

  Widget _buildInstructionCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: HoneyTheme.spacingLg,
        vertical: HoneyTheme.spacingSm,
      ),
      padding: const EdgeInsets.all(HoneyTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(HoneyTheme.radiusLg),
        border: Border.all(
          color: HoneyTheme.honeyGold,
          width: HoneyTheme.borderNormal,
        ),
        boxShadow: [
          BoxShadow(
            color: HoneyTheme.honeyGold.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeaderRow(context),
          const SizedBox(height: HoneyTheme.spacingMd),
          Text(
            widget.instruction,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: HoneyTheme.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: HoneyTheme.spacingXs),
          Text(
            widget.subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: HoneyTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.buttonLabel != null) ...[
            const SizedBox(height: HoneyTheme.spacingLg),
            _buildActionButton(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ExcludeSemantics(
          child: Icon(
            Icons.school_outlined,
            color: HoneyTheme.deepHoney,
            size: HoneyTheme.iconSizeMd,
          ),
        ),
        if (widget.showSkipButton)
          Semantics(
            label: 'Skip tutorial',
            button: true,
            child: TextButton(
              onPressed: widget.onSkip,
              child: Text(
                'Skip Tutorial',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: HoneyTheme.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: widget.onButtonTap,
        style: FilledButton.styleFrom(
          backgroundColor: HoneyTheme.honeyGold,
          foregroundColor: HoneyTheme.textOnPrimary,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HoneyTheme.radiusXl),
          ),
        ),
        child: Text(widget.buttonLabel!),
      ),
    );
  }

  Widget _buildPulsingArrow() {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _arrowOffset,
        builder: (context, child) {
          return Padding(
            padding: EdgeInsets.only(top: _arrowOffset.value),
            child: child,
          );
        },
        child: Icon(
          Icons.keyboard_arrow_down,
          color: HoneyTheme.deepHoney,
          size: 32,
        ),
      ),
    );
  }
}
