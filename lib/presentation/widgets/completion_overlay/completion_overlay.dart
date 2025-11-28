import 'package:flutter/material.dart';

import '../../theme/honey_theme.dart';

/// Overlay displayed when a level is completed.
///
/// Shows:
/// - Star rating (0-3 stars) with sequential animation
/// - Completion time
/// - Navigation buttons: Next Level, Replay, Level Select
class CompletionOverlay extends StatefulWidget {
  /// Number of stars earned (0-3).
  final int stars;

  /// Time taken to complete the level.
  final Duration completionTime;

  /// Callback when "Next Level" button is tapped.
  final VoidCallback? onNextLevel;

  /// Callback when "Replay" button is tapped.
  final VoidCallback? onReplay;

  /// Callback when "Level Select" button is tapped.
  final VoidCallback? onLevelSelect;

  /// Whether the "Next Level" button should be enabled.
  /// Set to false when on the last level.
  final bool hasNextLevel;

  const CompletionOverlay({
    super.key,
    required this.stars,
    required this.completionTime,
    this.onNextLevel,
    this.onReplay,
    this.onLevelSelect,
    this.hasNextLevel = true,
  }) : assert(stars >= 0 && stars <= 3, 'Stars must be between 0 and 3');

  @override
  State<CompletionOverlay> createState() => _CompletionOverlayState();
}

class _CompletionOverlayState extends State<CompletionOverlay>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late Animation<double> _cardScale;
  late Animation<double> _cardOpacity;

  late List<AnimationController> _starControllers;
  late List<Animation<double>> _starScales;

  @override
  void initState() {
    super.initState();
    _initCardAnimation();
    _initStarAnimations();
    _startAnimations();
  }

  void _initCardAnimation() {
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _cardScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack),
    );

    _cardOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));
  }

  void _initStarAnimations() {
    _starControllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      );
    });

    _starScales = _starControllers.map((controller) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 60),
        TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 20),
      ]).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    }).toList();
  }

  Future<void> _startAnimations() async {
    // Start card animation
    if (!mounted) return;
    await _cardController.forward();

    // Animate stars sequentially with delay
    for (int i = 0; i < widget.stars && i < 3; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      _starControllers[i].forward();
    }
  }

  @override
  void dispose() {
    _cardController.dispose();
    for (final controller in _starControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_cardScale, _cardOpacity]),
          builder: (context, child) {
            return Opacity(
              opacity: _cardOpacity.value,
              child: Transform.scale(scale: _cardScale.value, child: child),
            );
          },
          child: _buildCard(context),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: HoneycombDecorations.completionCard(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTitle(context),
          const SizedBox(height: 20),
          _buildStarsRow(),
          const SizedBox(height: 16),
          _buildTimeDisplay(context),
          const SizedBox(height: 24),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.emoji_events, size: 48, color: HoneyTheme.honeyGold),
        const SizedBox(height: 8),
        Text(
          'Level Complete!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: HoneyTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStarsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: HoneycombDecorations.starContainer(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          final isFilled = index < widget.stars;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedBuilder(
              animation: _starScales[index],
              builder: (context, child) {
                final scale = isFilled ? _starScales[index].value : 1.0;
                return Transform.scale(
                  scale: scale == 0.0 ? 1.0 : scale,
                  child: Icon(
                    isFilled ? Icons.star : Icons.star_border,
                    color: isFilled
                        ? HoneyTheme.starFilled
                        : HoneyTheme.starEmpty,
                    size: 48,
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimeDisplay(BuildContext context) {
    return Column(
      children: [
        Text('Time', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          _formatDuration(widget.completionTime),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: HoneyTheme.deepHoney,
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        // Primary action: Next Level (if available)
        if (widget.hasNextLevel)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.onNextLevel,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next Level'),
              style: FilledButton.styleFrom(
                backgroundColor: HoneyTheme.honeyGold,
                foregroundColor: HoneyTheme.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        if (widget.hasNextLevel) const SizedBox(height: 12),

        // Secondary actions row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onReplay,
                icon: const Icon(Icons.refresh),
                label: const Text('Replay'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onLevelSelect,
                icon: const Icon(Icons.grid_view),
                label: const Text('Levels'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final milliseconds = (duration.inMilliseconds % 1000) ~/ 10;

    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}.'
          '${milliseconds.toString().padLeft(2, '0')}';
    }
    return '$seconds.${milliseconds.toString().padLeft(2, '0')}s';
  }
}
