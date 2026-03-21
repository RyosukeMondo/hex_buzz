import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../domain/models/daily_challenge_state.dart' as domain;
import '../../../presentation/providers/achievement_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/daily_challenge_provider.dart';
import '../../../presentation/providers/game_provider.dart';
import '../../../presentation/providers/hint_provider.dart';
import '../../../presentation/providers/progress_provider.dart';
import '../../../presentation/providers/theme_provider.dart';

/// REST API routes for reading Riverpod provider state.
///
/// Provides read-only endpoints for inspecting the current state of
/// all major providers. Only available in debug mode.
class StateRoutes {
  final WidgetRef ref;

  StateRoutes({required this.ref});

  /// Creates a router with all state routes.
  Router get router {
    assert(kDebugMode, 'StateRoutes must only be used in debug builds');
    final router = Router();

    router.get('/game', _handleGameState);
    router.get('/auth', _handleAuthState);
    router.get('/progress', _handleProgressState);
    router.get('/daily', _handleDailyState);
    router.get('/hints', _handleHintState);
    router.get('/achievements', _handleAchievementState);
    router.get('/theme', _handleThemeState);
    router.get('/locale', _handleLocaleState);
    router.get('/all', _handleAllState);

    return router;
  }

  /// GET /api/state/game - Full game state.
  Response _handleGameState(Request request) {
    try {
      final state = ref.read(gameProvider);
      final notifier = ref.read(gameProvider.notifier);

      return _jsonResponse({
        'game': {
          'mode': state.mode.name,
          'isStarted': state.isStarted,
          'isComplete': state.isComplete,
          'pathLength': state.path.length,
          'path': state.path
              .map((c) => {'q': c.q, 'r': c.r})
              .toList(),
          'nextCheckpoint': state.nextCheckpoint,
          'elapsedTimeMs': state.elapsedTime.inMilliseconds,
          'currentCell': state.currentCell != null
              ? {'q': state.currentCell!.q, 'r': state.currentCell!.r}
              : null,
          'level': {
            'id': state.level.id,
            'size': state.level.size,
            'checkpointCount': state.level.checkpointCount,
            'cellCount': state.level.cells.length,
          },
          'currentLevelIndex': notifier.currentLevelIndex,
          'edgeSize': notifier.edgeSize,
          'isRepositoryLoaded': notifier.isRepositoryLoaded,
          'isGenerating': notifier.isGenerating,
        },
      });
    } catch (e) {
      return _errorResponse('game_state_error', e.toString());
    }
  }

  /// GET /api/state/auth - Auth state.
  Response _handleAuthState(Request request) {
    try {
      final authState = ref.read(authProvider);

      return _jsonResponse({
        'auth': authState.when(
          data: (user) => {
            'status': 'authenticated',
            'isLoggedIn': user != null,
            'user': user != null
                ? {
                    'id': user.id,
                    'username': user.username,
                    'isGuest': user.isGuest,
                    'email': user.email,
                    'displayName': user.displayName,
                    'totalStars': user.totalStars,
                    'rank': user.rank,
                    'createdAt': user.createdAt.toIso8601String(),
                  }
                : null,
          },
          loading: () => {'status': 'loading'},
          error: (e, _) => {'status': 'error', 'error': e.toString()},
        ),
      });
    } catch (e) {
      return _errorResponse('auth_state_error', e.toString());
    }
  }

  /// GET /api/state/progress - Progress state.
  Response _handleProgressState(Request request) {
    try {
      final progressAsync = ref.read(progressProvider);

      return _jsonResponse({
        'progress': progressAsync.when(
          data: (state) => {
            'status': 'loaded',
            'totalStars': state.totalStars,
            'completedLevels': state.completedLevels,
            'highestUnlockedLevel': state.highestUnlockedLevel,
            'levels': state.levels.map(
              (key, value) => MapEntry(key.toString(), {
                'completed': value.completed,
                'stars': value.stars,
                'bestTimeMs': value.bestTime?.inMilliseconds,
              }),
            ),
          },
          loading: () => {'status': 'loading'},
          error: (e, _) => {'status': 'error', 'error': e.toString()},
        ),
      });
    } catch (e) {
      return _errorResponse('progress_state_error', e.toString());
    }
  }

  /// GET /api/state/daily - Daily challenge state with sealed union info.
  Response _handleDailyState(Request request) {
    try {
      // Daily challenge provider requires a userId.
      final authState = ref.read(authProvider);
      final user = authState.valueOrNull;
      if (user == null) {
        return _jsonResponse({
          'daily': {
            'status': 'no_user',
            'message': 'No user logged in. Daily challenge requires auth.',
          },
        });
      }

      final userId = user.isGuest ? 'guest' : user.id;
      final dailyState = ref.read(dailyChallengeProvider(userId));

      return _jsonResponse({
        'daily': _serializeDailyChallengeState(dailyState),
      });
    } catch (e) {
      return _errorResponse('daily_state_error', e.toString());
    }
  }

  /// GET /api/state/hints - Hint state.
  Response _handleHintState(Request request) {
    try {
      final hintState = ref.read(hintProvider);

      return _jsonResponse({
        'hints': {
          'hintsRemaining': hintState.hintsRemaining,
          'maxHints': hintState.maxHints,
          'hasHintsRemaining': hintState.hasHintsRemaining,
          'isCalculating': hintState.isCalculating,
          'currentHint': hintState.currentHint?.toString(),
        },
      });
    } catch (e) {
      return _errorResponse('hint_state_error', e.toString());
    }
  }

  /// GET /api/state/achievements - Achievement state.
  Response _handleAchievementState(Request request) {
    try {
      final achievementAsync = ref.read(achievementProvider);

      return _jsonResponse({
        'achievements': achievementAsync.when(
          data: (state) => {
            'status': 'loaded',
            'totalCount': state.totalCount,
            'unlockedCount': state.unlockedCount,
            'progress': state.progress.map(
              (key, value) => MapEntry(key, value.toJson()),
            ),
            'recentlyUnlocked': state.recentlyUnlocked
                .take(5)
                .map((p) => p.toJson())
                .toList(),
          },
          loading: () => {'status': 'loading'},
          error: (e, _) => {'status': 'error', 'error': e.toString()},
        ),
      });
    } catch (e) {
      return _errorResponse('achievement_state_error', e.toString());
    }
  }

  /// GET /api/state/theme - Current theme preference.
  Response _handleThemeState(Request request) {
    try {
      final theme = ref.read(themeProvider);

      return _jsonResponse({
        'theme': {
          'preference': theme.name,
          'values': ThemePreference.values.map((v) => v.name).toList(),
        },
      });
    } catch (e) {
      return _errorResponse('theme_state_error', e.toString());
    }
  }

  /// GET /api/state/locale - Current locale (not implemented, returns info).
  Response _handleLocaleState(Request request) {
    return _jsonResponse({
      'locale': {
        'status': 'not_available',
        'message': 'Locale provider is not implemented in this app.',
      },
    });
  }

  /// GET /api/state/all - All states combined.
  Response _handleAllState(Request request) {
    final responses = <String, dynamic>{};

    // Collect all states, catching individual errors
    responses['game'] = _safeRead(() {
      final state = ref.read(gameProvider);
      final notifier = ref.read(gameProvider.notifier);
      return {
        'mode': state.mode.name,
        'isStarted': state.isStarted,
        'isComplete': state.isComplete,
        'pathLength': state.path.length,
        'nextCheckpoint': state.nextCheckpoint,
        'elapsedTimeMs': state.elapsedTime.inMilliseconds,
        'currentLevelIndex': notifier.currentLevelIndex,
        'edgeSize': notifier.edgeSize,
      };
    });

    responses['auth'] = _safeRead(() {
      final authState = ref.read(authProvider);
      final user = authState.valueOrNull;
      return {
        'isLoggedIn': user != null,
        'isGuest': user?.isGuest,
        'userId': user?.id,
        'username': user?.username,
      };
    });

    responses['progress'] = _safeRead(() {
      final progressAsync = ref.read(progressProvider);
      final state = progressAsync.valueOrNull;
      return state != null
          ? {
              'totalStars': state.totalStars,
              'completedLevels': state.completedLevels,
              'highestUnlockedLevel': state.highestUnlockedLevel,
            }
          : {'status': 'loading_or_error'};
    });

    responses['hints'] = _safeRead(() {
      final hintState = ref.read(hintProvider);
      return {
        'hintsRemaining': hintState.hintsRemaining,
        'maxHints': hintState.maxHints,
        'hasHintsRemaining': hintState.hasHintsRemaining,
      };
    });

    responses['achievements'] = _safeRead(() {
      final achievementAsync = ref.read(achievementProvider);
      final state = achievementAsync.valueOrNull;
      return state != null
          ? {
              'totalCount': state.totalCount,
              'unlockedCount': state.unlockedCount,
            }
          : {'status': 'loading_or_error'};
    });

    responses['theme'] = _safeRead(() {
      final theme = ref.read(themeProvider);
      return {'preference': theme.name};
    });

    responses['locale'] = {'status': 'not_available'};

    return _jsonResponse({
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'states': responses,
    });
  }

  // -- Helpers --

  Map<String, dynamic> _serializeDailyChallengeState(
    domain.DailyChallengeState state,
  ) {
    return switch (state) {
      domain.DailyChallengeStateLoading() => {
        'stateType': 'loading',
      },
      domain.DailyChallengeStateNotStarted(:final challenge) => {
        'stateType': 'not_started',
        'challengeId': challenge.id,
        'levelSize': challenge.level.size,
        'date': challenge.date.toIso8601String(),
      },
      domain.DailyChallengeStatePlaying(
        :final challenge,
        :final startTime,
        :final currentPath,
      ) =>
        {
          'stateType': 'playing',
          'challengeId': challenge.id,
          'startTime': startTime.toIso8601String(),
          'pathLength': currentPath.length,
          'elapsedMs':
              DateTime.now().difference(startTime).inMilliseconds,
        },
      domain.DailyChallengeStateSuspended(
        :final challenge,
        :final startTime,
        :final suspendedTime,
      ) =>
        {
          'stateType': 'suspended',
          'challengeId': challenge.id,
          'startTime': startTime.toIso8601String(),
          'suspendedTime': suspendedTime.toIso8601String(),
        },
      domain.DailyChallengeStateCompleted(:final completion) => {
        'stateType': 'completed',
        'userId': completion.userId,
        'stars': completion.stars,
        'completionTimeMs': completion.completionTimeMs,
      },
      domain.DailyChallengeStateAlreadyCompleted(:final completion) => {
        'stateType': 'already_completed',
        'userId': completion.userId,
        'stars': completion.stars,
        'completionTimeMs': completion.completionTimeMs,
      },
      domain.DailyChallengeStateError(:final message) => {
        'stateType': 'error',
        'message': message,
      },
    };
  }

  dynamic _safeRead(dynamic Function() reader) {
    try {
      return reader();
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Response _errorResponse(String error, String message) {
    return _jsonResponse({
      'error': error,
      'message': message,
    }, statusCode: 500);
  }

  static Response _jsonResponse(
    Map<String, dynamic> data, {
    int statusCode = 200,
  }) {
    return Response(
      statusCode,
      body: jsonEncode(data),
      headers: {'content-type': 'application/json'},
    );
  }
}
