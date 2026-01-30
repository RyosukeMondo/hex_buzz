import 'daily_challenge.dart';
import 'daily_challenge_completion.dart';
import 'hex_cell.dart';

/// Sealed union representing all possible states of a daily challenge.
///
/// This state machine enforces the one-attempt-per-day rule and prevents
/// timer resets by preserving startTime across state transitions.
sealed class DailyChallengeState {
  const DailyChallengeState();
}

/// Initial loading state while fetching challenge data.
class DailyChallengeStateLoading extends DailyChallengeState {
  const DailyChallengeStateLoading();

  @override
  bool operator ==(Object other) => other is DailyChallengeStateLoading;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'DailyChallengeStateLoading()';
}

/// Challenge is ready to start - user has not attempted it yet today.
class DailyChallengeStateNotStarted extends DailyChallengeState {
  final DailyChallenge challenge;

  const DailyChallengeStateNotStarted(this.challenge);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyChallengeStateNotStarted &&
        other.challenge == challenge;
  }

  @override
  int get hashCode => challenge.hashCode;

  @override
  String toString() =>
      'DailyChallengeStateNotStarted(challenge: ${challenge.id})';
}

/// Challenge is actively being played.
///
/// The startTime is preserved to prevent timer resets.
class DailyChallengeStatePlaying extends DailyChallengeState {
  final DailyChallenge challenge;
  final DateTime startTime;
  final List<HexCell> currentPath;

  const DailyChallengeStatePlaying({
    required this.challenge,
    required this.startTime,
    required this.currentPath,
  });

  DailyChallengeStatePlaying copyWith({
    DailyChallenge? challenge,
    DateTime? startTime,
    List<HexCell>? currentPath,
  }) {
    return DailyChallengeStatePlaying(
      challenge: challenge ?? this.challenge,
      startTime: startTime ?? this.startTime,
      currentPath: currentPath ?? this.currentPath,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyChallengeStatePlaying &&
        other.challenge == challenge &&
        other.startTime == startTime &&
        _listEquals(other.currentPath, currentPath);
  }

  @override
  int get hashCode =>
      Object.hash(challenge, startTime, Object.hashAll(currentPath));

  @override
  String toString() =>
      'DailyChallengeStatePlaying(challenge: ${challenge.id}, startTime: $startTime, pathLength: ${currentPath.length})';
}

/// Challenge is temporarily suspended but timer keeps running.
///
/// The startTime is preserved - timer cannot be reset.
class DailyChallengeStateSuspended extends DailyChallengeState {
  final DailyChallenge challenge;
  final DateTime startTime;
  final DateTime suspendedTime;
  final List<HexCell> currentPath;

  const DailyChallengeStateSuspended({
    required this.challenge,
    required this.startTime,
    required this.suspendedTime,
    required this.currentPath,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyChallengeStateSuspended &&
        other.challenge == challenge &&
        other.startTime == startTime &&
        other.suspendedTime == suspendedTime &&
        _listEquals(other.currentPath, currentPath);
  }

  @override
  int get hashCode => Object.hash(
    challenge,
    startTime,
    suspendedTime,
    Object.hashAll(currentPath),
  );

  @override
  String toString() =>
      'DailyChallengeStateSuspended(challenge: ${challenge.id}, startTime: $startTime)';
}

/// Challenge has been completed successfully today.
class DailyChallengeStateCompleted extends DailyChallengeState {
  final DailyChallengeCompletion completion;

  const DailyChallengeStateCompleted(this.completion);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyChallengeStateCompleted &&
        other.completion == completion;
  }

  @override
  int get hashCode => completion.hashCode;

  @override
  String toString() =>
      'DailyChallengeStateCompleted(completion: ${completion.userId})';
}

/// User attempted to retry a challenge they already completed today.
///
/// This state prevents the one-attempt-per-day rule violation.
class DailyChallengeStateAlreadyCompleted extends DailyChallengeState {
  final DailyChallengeCompletion completion;

  const DailyChallengeStateAlreadyCompleted(this.completion);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyChallengeStateAlreadyCompleted &&
        other.completion == completion;
  }

  @override
  int get hashCode => completion.hashCode;

  @override
  String toString() =>
      'DailyChallengeStateAlreadyCompleted(completion: ${completion.userId})';
}

/// An error occurred while loading or processing the challenge.
class DailyChallengeStateError extends DailyChallengeState {
  final String message;

  const DailyChallengeStateError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyChallengeStateError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'DailyChallengeStateError(message: $message)';
}

/// Helper to compare lists for equality.
bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
