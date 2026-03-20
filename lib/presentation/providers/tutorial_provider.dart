import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/local_tutorial_repository.dart';
import '../../domain/models/tutorial_state.dart';
import '../../domain/services/tutorial_repository.dart';
import '../../domain/services/tutorial_service.dart';
import 'notification_provider.dart';

/// Provider for the tutorial repository (dependency injection point).
///
/// Override this in main.dart with a concrete LocalTutorialRepository
/// initialized with SharedPreferences.
final tutorialRepositoryProvider = Provider<TutorialRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalTutorialRepository(prefs);
});

/// Provider for the tutorial service (stateless, no DI needed).
final tutorialServiceProvider = Provider<TutorialService>((ref) {
  return const TutorialService();
});

/// Notifier that manages tutorial state and step progression.
///
/// Coordinates between [TutorialService] (step logic, level creation)
/// and [LocalTutorialRepository] (persistence) to drive the tutorial flow.
class TutorialNotifier extends Notifier<TutorialState> {
  late TutorialRepository _repository;
  late TutorialService _service;

  @override
  TutorialState build() {
    _repository = ref.watch(tutorialRepositoryProvider);
    _service = ref.watch(tutorialServiceProvider);

    final completed = _repository.hasCompletedTutorial();
    if (completed) {
      return const TutorialState.completed();
    }
    return const TutorialState.initial();
  }

  /// Whether the tutorial should be shown (first-time user).
  bool get shouldShowTutorial => !state.hasCompletedTutorial;

  /// Starts the tutorial from the first step.
  void startTutorial() {
    state = const TutorialState(
      currentStep: TutorialStep.welcome,
      isActive: true,
      hasCompletedTutorial: false,
    );
  }

  /// Advances to the next tutorial step.
  ///
  /// If there is no next step, marks the tutorial as complete.
  void advance() {
    final next = _service.nextStep(state.currentStep);
    if (next == null) {
      complete();
      return;
    }
    state = state.copyWith(currentStep: next);
  }

  /// Skips the tutorial entirely and marks it as completed.
  void skip() {
    _repository.markCompleted();
    state = const TutorialState.completed();
  }

  /// Marks the tutorial as completed and persists the result.
  void complete() {
    _repository.markCompleted();
    state = const TutorialState(
      currentStep: TutorialStep.complete,
      isActive: false,
      hasCompletedTutorial: true,
    );
  }
}

/// Provider for tutorial state management.
final tutorialProvider = NotifierProvider<TutorialNotifier, TutorialState>(
  TutorialNotifier.new,
);
