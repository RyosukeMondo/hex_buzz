import 'game_mode.dart';
import 'hex_cell.dart';
import 'level.dart';

/// Represents the current state of a game in progress.
///
/// Tracks the level being played, the path drawn by the player,
/// the next checkpoint to reach, and timing information.
class GameState {
  final Level level;
  final GameMode mode;
  final List<HexCell> path;
  final int nextCheckpoint;
  final DateTime? startTime;
  final DateTime? endTime;

  const GameState({
    required this.level,
    required this.mode,
    this.path = const [],
    this.nextCheckpoint = 1,
    this.startTime,
    this.endTime,
  });

  /// Creates a new game state from a level with default initial values.
  factory GameState.initial({required Level level, required GameMode mode}) {
    return GameState(level: level, mode: mode);
  }

  /// Whether the game has started (first move made).
  bool get isStarted => startTime != null;

  /// Whether the game is complete (all cells visited in correct checkpoint order).
  bool get isComplete => endTime != null;

  /// The elapsed time since the game started, or total time if completed.
  Duration get elapsedTime {
    if (startTime == null) return Duration.zero;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime!);
  }

  /// Whether the game can be submitted to the leaderboard.
  ///
  /// Only daily mode games that have been completed can be submitted.
  bool get canSubmitToLeaderboard => mode == GameMode.daily && isComplete;

  /// The current cell (last cell in the path), or null if path is empty.
  HexCell? get currentCell => path.isEmpty ? null : path.last;

  /// Set of visited cell coordinates for quick lookup.
  Set<(int, int)> get visitedCoordinates =>
      path.map((cell) => (cell.q, cell.r)).toSet();

  /// Creates a copy with optional updated fields.
  GameState copyWith({
    Level? level,
    GameMode? mode,
    List<HexCell>? path,
    int? nextCheckpoint,
    DateTime? startTime,
    DateTime? endTime,
    bool clearStartTime = false,
    bool clearEndTime = false,
  }) {
    return GameState(
      level: level ?? this.level,
      mode: mode ?? this.mode,
      path: path ?? this.path,
      nextCheckpoint: nextCheckpoint ?? this.nextCheckpoint,
      startTime: clearStartTime ? null : (startTime ?? this.startTime),
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
    );
  }

  /// Serializes the game state to JSON.
  Map<String, dynamic> toJson() {
    return {
      'level': level.toJson(),
      'mode': mode.name,
      'path': path.map((c) => c.toJson()).toList(),
      'nextCheckpoint': nextCheckpoint,
      if (startTime != null) 'startTime': startTime!.toIso8601String(),
      if (endTime != null) 'endTime': endTime!.toIso8601String(),
    };
  }

  /// Creates a GameState from JSON data.
  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      level: Level.fromJson(json['level'] as Map<String, dynamic>),
      mode: GameMode.values.byName(json['mode'] as String),
      path: (json['path'] as List)
          .map((c) => HexCell.fromJson(c as Map<String, dynamic>))
          .toList(),
      nextCheckpoint: json['nextCheckpoint'] as int,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
    );
  }

  @override
  String toString() {
    final status = isComplete
        ? 'complete'
        : isStarted
        ? 'in-progress'
        : 'not-started';
    return 'GameState($status, path: ${path.length}, nextCheckpoint: $nextCheckpoint)';
  }
}
