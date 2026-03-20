import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_event.dart';
import '../../domain/models/game_mode.dart';
import '../../domain/services/hint_service.dart';
import 'analytics_provider.dart';
import 'game_provider.dart';

/// Tracks hint state for the current level.
///
/// Each level gets a fixed number of hints:
/// - Practice mode: 3 hints per level
/// - Daily challenge: 1 hint per level
class HintState {
  final int hintsRemaining;
  final int maxHints;
  final HintResult? currentHint;
  final bool isCalculating;

  const HintState({
    required this.hintsRemaining,
    required this.maxHints,
    this.currentHint,
    this.isCalculating = false,
  });

  /// Default state for practice mode.
  const HintState.practice()
    : hintsRemaining = 3,
      maxHints = 3,
      currentHint = null,
      isCalculating = false;

  /// Default state for daily challenge mode.
  const HintState.daily()
    : hintsRemaining = 1,
      maxHints = 1,
      currentHint = null,
      isCalculating = false;

  /// Whether hints are still available to use.
  bool get hasHintsRemaining => hintsRemaining > 0;

  HintState copyWith({
    int? hintsRemaining,
    int? maxHints,
    HintResult? currentHint,
    bool? isCalculating,
    bool clearHint = false,
  }) {
    return HintState(
      hintsRemaining: hintsRemaining ?? this.hintsRemaining,
      maxHints: maxHints ?? this.maxHints,
      currentHint: clearHint ? null : (currentHint ?? this.currentHint),
      isCalculating: isCalculating ?? this.isCalculating,
    );
  }

  @override
  String toString() =>
      'HintState(remaining: $hintsRemaining/$maxHints, '
      'hint: $currentHint, calculating: $isCalculating)';
}

/// Manages hint state and coordinates with [HintService] and [GameNotifier].
///
/// Listens to game state changes to clear stale hints when the player
/// makes a move or resets the game.
class HintNotifier extends Notifier<HintState> {
  final HintService _hintService;

  HintNotifier({HintService? hintService})
    : _hintService = hintService ?? const HintService();

  @override
  HintState build() {
    final gameState = ref.watch(gameProvider);

    // Determine hints based on game mode
    final isDaily = gameState.mode == GameMode.daily;
    final maxHints = isDaily ? 1 : 3;

    // Reset hint state when level changes (detected by level id change)
    // but preserve remaining count within same level
    return HintState(
      hintsRemaining: maxHints,
      maxHints: maxHints,
    );
  }

  /// Requests a hint for the current game state.
  ///
  /// Decrements remaining hints and computes the suggestion.
  /// Does nothing if no hints remain or game is complete.
  void requestHint() {
    final analytics = ref.read(analyticsServiceProvider);

    if (!state.hasHintsRemaining) {
      analytics.trackEvent(
        AnalyticsEventType.hintUnavailable,
        properties: {'reason': 'no_hints_remaining'},
      );
      return;
    }

    final gameState = ref.read(gameProvider);
    if (gameState.isComplete) return;

    analytics.trackEvent(
      AnalyticsEventType.hintRequested,
      properties: {
        'hintsRemaining': state.hintsRemaining - 1,
        'mode': gameState.mode.name,
      },
    );

    state = state.copyWith(isCalculating: true);

    final hint = _hintService.getHint(gameState);

    state = state.copyWith(
      currentHint: hint,
      hintsRemaining: state.hintsRemaining - 1,
      isCalculating: false,
    );
  }

  /// Clears the currently displayed hint.
  ///
  /// Called when the player makes a move so the highlight disappears.
  void clearHint() {
    if (state.currentHint != null) {
      state = state.copyWith(clearHint: true);
    }
  }
}

/// Provider for hint state management.
final hintProvider = NotifierProvider<HintNotifier, HintState>(
  HintNotifier.new,
);
