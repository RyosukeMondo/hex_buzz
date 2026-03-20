import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_event.dart';
import '../../../domain/models/game_mode.dart';
import '../../../domain/models/hex_cell.dart';
import '../../../domain/models/level.dart';
import '../../../domain/models/tutorial_state.dart';
import '../../../domain/services/game_engine.dart';
import '../../../domain/services/tutorial_service.dart';
import '../../../main.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/tutorial_provider.dart';
import '../../theme/honey_theme.dart';
import '../../widgets/hex_grid/hex_grid_widget.dart';
import '../../widgets/tutorial_overlay.dart';

/// Interactive tutorial screen that teaches game mechanics step by step.
///
/// Each tutorial step either shows informational text (with a "Next" button)
/// or presents a small playable hex grid that the user must interact with.
/// The screen uses a coach-mark pattern: instruction card on top,
/// interactive grid below.
class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  final TutorialService _service = const TutorialService();
  GameEngine? _engine;
  Level? _currentLevel;
  bool _stepCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTutorial();
    });
  }

  void _initializeTutorial() {
    final notifier = ref.read(tutorialProvider.notifier);
    notifier.startTutorial();
    _loadStepLevel();
  }

  void _loadStepLevel() {
    final tutorialState = ref.read(tutorialProvider);
    final level = _service.getLevelForStep(tutorialState.currentStep);

    setState(() {
      _currentLevel = level;
      _stepCompleted = false;
      if (level != null) {
        _engine = GameEngine(level: level, mode: GameMode.practice);
      } else {
        _engine = null;
      }
    });
  }

  void _handleAdvance() {
    final notifier = ref.read(tutorialProvider.notifier);
    final tutorialState = ref.read(tutorialProvider);

    if (tutorialState.currentStep == TutorialStep.complete) {
      _navigateAfterTutorial();
      return;
    }

    ref.read(analyticsServiceProvider).trackEvent(
      AnalyticsEventType.tutorialStepCompleted,
      properties: {'step': tutorialState.currentStep.name},
    );

    notifier.advance();
    _loadStepLevel();
  }

  void _handleSkip() {
    final tutorialState = ref.read(tutorialProvider);
    ref.read(analyticsServiceProvider).trackEvent(
      AnalyticsEventType.tutorialStepSkipped,
      properties: {'skippedAtStep': tutorialState.currentStep.name},
    );

    ref.read(tutorialProvider.notifier).skip();
    _navigateAfterTutorial();
  }

  void _navigateAfterTutorial() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.auth);
  }

  void _handleCellEntered(HexCell cell) {
    if (_engine == null) return;
    final state = _engine!.state;

    // Handle undo: slide back to previous cell
    if (state.path.length >= 2) {
      final previous = state.path[state.path.length - 2];
      if (cell.q == previous.q && cell.r == previous.r) {
        _engine!.undo();
        setState(() {});
        return;
      }
    }

    final result = _engine!.tryMove(cell);
    if (result.success) {
      setState(() {
        if (result.isWin) {
          _stepCompleted = true;
        }
      });
    }
  }

  void _resetCurrentLevel() {
    if (_engine != null) {
      _engine!.reset();
      setState(() {
        _stepCompleted = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tutorialState = ref.watch(tutorialProvider);
    final step = tutorialState.currentStep;
    final requiresInteraction = _service.requiresInteraction(step);
    final hasGrid = _currentLevel != null;

    return Scaffold(
      body: Container(
        decoration: _buildBackground(),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopSection(context, step, requiresInteraction),
              if (hasGrid) Expanded(child: _buildGridSection()),
              if (!hasGrid) const Spacer(),
              if (hasGrid) _buildGridControls(context),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          HoneyTheme.warmCream,
          HoneyTheme.honeyGoldLight.withValues(alpha: 0.2),
          HoneyTheme.warmCream,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
    );
  }

  Widget _buildTopSection(
    BuildContext context,
    TutorialStep step,
    bool requiresInteraction,
  ) {
    final showButton = !requiresInteraction || _stepCompleted;
    final buttonLabel = _getButtonLabel(step);

    return TutorialOverlay(
      instruction: _service.getInstructionText(step),
      subtitle: _service.getSubtitleText(step),
      showArrow: requiresInteraction && !_stepCompleted,
      buttonLabel: showButton ? buttonLabel : null,
      onButtonTap: showButton ? _handleAdvance : null,
      showSkipButton: step != TutorialStep.complete,
      onSkip: _handleSkip,
    );
  }

  String _getButtonLabel(TutorialStep step) {
    return switch (step) {
      TutorialStep.complete => 'Start Playing!',
      TutorialStep.welcome => 'Let\'s Go!',
      _ => 'Next',
    };
  }

  Widget _buildGridSection() {
    if (_engine == null || _currentLevel == null) {
      return const SizedBox.shrink();
    }

    final state = _engine!.state;
    final visitedCells = state.path.toSet();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HoneyTheme.spacingLg),
      child: HexGridWidget(
        level: _currentLevel!,
        path: state.path,
        visitedCells: visitedCells,
        onCellEntered: _stepCompleted ? null : _handleCellEntered,
      ),
    );
  }

  Widget _buildGridControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(HoneyTheme.spacingLg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_engine != null && _engine!.state.path.isNotEmpty)
            OutlinedButton.icon(
              onPressed: _resetCurrentLevel,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset'),
            ),
          if (_stepCompleted) ...[
            const SizedBox(width: HoneyTheme.spacingMd),
            _buildCompletedBadge(context),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HoneyTheme.spacingMd,
        vertical: HoneyTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: HoneyTheme.honeyGold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(HoneyTheme.radiusXl),
        border: Border.all(color: HoneyTheme.honeyGold),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            color: HoneyTheme.deepHoney,
            size: 20,
          ),
          const SizedBox(width: HoneyTheme.spacingXs),
          Text(
            'Solved!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: HoneyTheme.deepHoney,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
