// Examples of State Management Patterns
// DO NOT USE IN PRODUCTION - For documentation only

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// ❌ ANTI-PATTERN: Business Logic in didUpdateWidget
// ============================================================================

class BadGameScreen extends ConsumerStatefulWidget {
  const BadGameScreen({super.key});

  @override
  ConsumerState<BadGameScreen> createState() => _BadGameScreenState();
}

class _BadGameScreenState extends ConsumerState<BadGameScreen> {
  @override
  void didUpdateWidget(BadGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ❌ BAD: This may never be called if parent doesn't rebuild
    final gameState = ref.read(gameProvider);
    if (gameState.isComplete) {
      submitScore(); // May never execute!
    }
  }

  void submitScore() {
    // Submission logic
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

// ============================================================================
// ✅ CORRECT PATTERN: ref.listen for State Changes
// ============================================================================

class GoodGameScreen extends ConsumerStatefulWidget {
  const GoodGameScreen({super.key});

  @override
  ConsumerState<GoodGameScreen> createState() => _GoodGameScreenState();
}

class _GoodGameScreenState extends ConsumerState<GoodGameScreen> {
  bool _hasSubmitted = false;

  @override
  Widget build(BuildContext context) {
    // ✅ GOOD: Listen for state changes directly
    ref.listen<GameState>(gameProvider, (previous, next) {
      // Only trigger once when game becomes complete
      if (previous?.isComplete != true && next.isComplete && !_hasSubmitted) {
        _hasSubmitted = true;
        submitScore(next);
      }
    });

    final gameState = ref.watch(gameProvider);
    return Container(
      child: gameState.isComplete
        ? CompletionOverlay()
        : GameGrid(),
    );
  }

  Future<void> submitScore(GameState state) async {
    // Submission logic with error handling
    try {
      await ref.read(dailyChallengeRepositoryProvider)
        .submitCompletion(
          userId: 'user123',
          stars: 3,
          completionTimeMs: state.elapsedTime.inMilliseconds,
        );
    } catch (e) {
      // Handle error
      print('Failed to submit: $e');
    }
  }
}

// ============================================================================
// ✅ BEST PATTERN: Event-Driven Architecture
// ============================================================================

// 1. Define events
abstract class GameEvent {}
class GameStartedEvent extends GameEvent {}
class GameCompletedEvent extends GameEvent {
  final GameState state;
  GameCompletedEvent(this.state);
}

// 2. Notifier emits events
class GameNotifier extends StateNotifier<GameState> {
  final _eventsController = StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get events => _eventsController.stream;

  GameNotifier() : super(GameState.initial());

  void completeGame() {
    state = state.copyWith(isComplete: true, endTime: DateTime.now());

    // ✅ Explicitly emit event
    _eventsController.add(GameCompletedEvent(state));
  }

  @override
  void dispose() {
    _eventsController.close();
    super.dispose();
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});

final gameEventsProvider = StreamProvider<GameEvent>((ref) {
  return ref.watch(gameProvider.notifier).events;
});

// 3. UI listens to events
class BestGameScreen extends ConsumerWidget {
  const BestGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Listen to event stream
    ref.listen<AsyncValue<GameEvent>>(gameEventsProvider, (previous, next) {
      next.whenData((event) {
        if (event is GameCompletedEvent) {
          submitScore(ref, event.state);
        }
      });
    });

    final gameState = ref.watch(gameProvider);
    return Container();
  }

  Future<void> submitScore(WidgetRef ref, GameState state) async {
    await ref.read(dailyChallengeRepositoryProvider)
      .submitCompletion(
        userId: 'user123',
        stars: 3,
        completionTimeMs: state.elapsedTime.inMilliseconds,
      );
  }
}

// ============================================================================
// ✅ STATE MACHINE PATTERN: Explicit State Transitions
// ============================================================================

enum GamePhase {
  notStarted,
  playing,
  completed,
  submitting,
  submitted,
  submitFailed,
}

class GameStateWithPhase {
  final GamePhase phase;
  final bool isComplete;

  const GameStateWithPhase({
    required this.phase,
    this.isComplete = false,
  });

  GameStateWithPhase copyWith({GamePhase? phase, bool? isComplete}) {
    return GameStateWithPhase(
      phase: phase ?? this.phase,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class GameStateMachineNotifier extends StateNotifier<GameStateWithPhase> {
  GameStateMachineNotifier() : super(
    const GameStateWithPhase(phase: GamePhase.notStarted)
  );

  void startGame() {
    if (state.phase != GamePhase.notStarted) {
      throw StateError('Cannot start from ${state.phase}');
    }
    state = state.copyWith(phase: GamePhase.playing);
  }

  void completeGame() {
    if (state.phase != GamePhase.playing) {
      throw StateError('Cannot complete from ${state.phase}');
    }
    state = state.copyWith(
      phase: GamePhase.completed,
      isComplete: true,
    );
  }

  Future<void> submitScore() async {
    if (state.phase != GamePhase.completed) {
      throw StateError('Cannot submit from ${state.phase}');
    }

    state = state.copyWith(phase: GamePhase.submitting);

    try {
      // Submission logic
      await Future.delayed(Duration(seconds: 1));
      state = state.copyWith(phase: GamePhase.submitted);
    } catch (e) {
      state = state.copyWith(phase: GamePhase.submitFailed);
      rethrow;
    }
  }
}

// ============================================================================
// Mock providers for examples
// ============================================================================

class GameState {
  final bool isComplete;
  final DateTime? endTime;
  final Duration elapsedTime;

  const GameState({
    this.isComplete = false,
    this.endTime,
    this.elapsedTime = Duration.zero,
  });

  factory GameState.initial() => const GameState();

  GameState copyWith({
    bool? isComplete,
    DateTime? endTime,
    Duration? elapsedTime,
  }) {
    return GameState(
      isComplete: isComplete ?? this.isComplete,
      endTime: endTime ?? this.endTime,
      elapsedTime: elapsedTime ?? this.elapsedTime,
    );
  }
}

final gameProvider = StateProvider<GameState>((ref) => GameState.initial());

class DailyChallengeRepository {
  Future<bool> submitCompletion({
    required String userId,
    required int stars,
    required int completionTimeMs,
  }) async {
    // Mock implementation
    return true;
  }
}

final dailyChallengeRepositoryProvider = Provider<DailyChallengeRepository>((ref) {
  return DailyChallengeRepository();
});

class CompletionOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container();
}

class GameGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container();
}
