/// Steps in the onboarding tutorial flow.
///
/// Each step teaches one game concept, progressing from basic to advanced.
/// Steps are ordered to build understanding incrementally.
enum TutorialStep {
  welcome,
  explainGoal,
  tapStartCell,
  drawPath,
  checkpoints,
  walls,
  undo,
  complete,
}

/// Immutable state for the tutorial system.
///
/// Tracks which step the user is on, whether the tutorial is active,
/// and whether the user has already completed it (for skip-on-return).
class TutorialState {
  final TutorialStep currentStep;
  final bool isActive;
  final bool hasCompletedTutorial;

  const TutorialState({
    this.currentStep = TutorialStep.welcome,
    this.isActive = false,
    this.hasCompletedTutorial = false,
  });

  /// Initial state for a first-time user.
  const TutorialState.initial()
      : currentStep = TutorialStep.welcome,
        isActive = false,
        hasCompletedTutorial = false;

  /// State for a user who has already completed the tutorial.
  const TutorialState.completed()
      : currentStep = TutorialStep.complete,
        isActive = false,
        hasCompletedTutorial = true;

  /// Creates a copy with optional updated fields.
  TutorialState copyWith({
    TutorialStep? currentStep,
    bool? isActive,
    bool? hasCompletedTutorial,
  }) {
    return TutorialState(
      currentStep: currentStep ?? this.currentStep,
      isActive: isActive ?? this.isActive,
      hasCompletedTutorial:
          hasCompletedTutorial ?? this.hasCompletedTutorial,
    );
  }

  /// Serializes to JSON for persistence.
  Map<String, dynamic> toJson() {
    return {
      'currentStep': currentStep.name,
      'isActive': isActive,
      'hasCompletedTutorial': hasCompletedTutorial,
    };
  }

  /// Deserializes from JSON.
  factory TutorialState.fromJson(Map<String, dynamic> json) {
    return TutorialState(
      currentStep: TutorialStep.values.byName(
        json['currentStep'] as String? ?? 'welcome',
      ),
      isActive: json['isActive'] as bool? ?? false,
      hasCompletedTutorial: json['hasCompletedTutorial'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TutorialState &&
        other.currentStep == currentStep &&
        other.isActive == isActive &&
        other.hasCompletedTutorial == hasCompletedTutorial;
  }

  @override
  int get hashCode =>
      Object.hash(currentStep, isActive, hasCompletedTutorial);

  @override
  String toString() =>
      'TutorialState(step: ${currentStep.name}, '
      'active: $isActive, completed: $hasCompletedTutorial)';
}
