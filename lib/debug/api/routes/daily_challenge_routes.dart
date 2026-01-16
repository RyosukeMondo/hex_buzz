import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../domain/models/daily_challenge.dart';
import '../../../domain/models/leaderboard_entry.dart';
import '../../../domain/services/auth_repository.dart';
import '../../../domain/services/daily_challenge_repository.dart';

/// REST API routes for daily challenge operations.
///
/// Provides endpoints for AI agents to interact with daily challenges:
/// - GET /api/daily-challenge - Get today's daily challenge
/// - GET /api/daily-challenge/leaderboard?date=YYYY-MM-DD - Get challenge leaderboard
/// - POST /api/daily-challenge/complete - Submit a completion (requires authentication)
/// - GET /api/daily-challenge/completed/:userId - Check if user completed today
///
/// Uses DailyChallengeRepository for challenge operations and AuthRepository
/// for authentication checks on protected endpoints.
class DailyChallengeRoutes {
  final DailyChallengeRepository repository;
  final AuthRepository authRepository;

  DailyChallengeRoutes({
    required this.repository,
    required this.authRepository,
  });

  /// Creates a router with all daily challenge routes.
  Router get router {
    final router = Router();

    router.get('/', _handleGetTodaysChallenge);
    router.get('/leaderboard', _handleGetLeaderboard);
    router.post('/complete', _handleSubmitCompletion);
    router.get('/completed/<userId>', _handleCheckCompleted);

    return router;
  }

  /// GET /api/daily-challenge
  ///
  /// Get today's daily challenge.
  /// Response: {"challenge": DailyChallenge?} (null if not available)
  Future<Response> _handleGetTodaysChallenge(Request request) async {
    try {
      final challenge = await repository.getTodaysChallenge();

      if (challenge == null) {
        return _jsonResponse({'challenge': null});
      }

      return _jsonResponse({'challenge': _serializeChallenge(challenge)});
    } catch (e) {
      return _errorResponse('fetch_failed', e.toString());
    }
  }

  /// GET /api/daily-challenge/leaderboard?date=YYYY-MM-DD&limit=N
  ///
  /// Get the leaderboard for a daily challenge.
  /// Query params:
  ///   - date: Date in YYYY-MM-DD format (default: today UTC)
  ///   - limit: Number of entries to fetch (default: 100, max: 500)
  /// Response: {"entries": [LeaderboardEntry...], "date": string, "count": int}
  Future<Response> _handleGetLeaderboard(Request request) async {
    try {
      final params = request.url.queryParameters;
      final limit = _parseIntParam(
        params['limit'],
        defaultValue: 100,
        max: 500,
      );

      final date = params['date'] != null
          ? DateTime.parse(params['date']!)
          : DateTime.now().toUtc();

      final entries = await repository.getChallengeLeaderboard(
        date: date,
        limit: limit,
      );

      return _jsonResponse({
        'entries': entries.map(_serializeLeaderboardEntry).toList(),
        'date': _formatDate(date),
        'count': entries.length,
      });
    } catch (e) {
      return _errorResponse('fetch_failed', e.toString());
    }
  }

  /// POST /api/daily-challenge/complete
  ///
  /// Submit a completion for today's daily challenge.
  /// Requires authentication (user must be logged in).
  /// Request body: {"userId": string, "stars": int, "completionTimeMs": int}
  /// Response: {"success": bool, "error"?: string}
  Future<Response> _handleSubmitCompletion(Request request) async {
    // Check authentication
    final currentUser = await authRepository.getCurrentUser();
    if (currentUser == null) {
      return _errorResponse(
        'unauthorized',
        'User must be logged in to submit completions',
      );
    }

    final body = await _parseJsonBody(request);
    if (body == null) {
      return _errorResponse('invalid_json', 'Request body must be valid JSON');
    }

    final validationError = _validateCompletionRequest(body);
    if (validationError != null) return validationError;

    final userId = body['userId'] as String;
    final stars = body['stars'] as int;
    final completionTimeMs = body['completionTimeMs'] as int;

    // Verify the user is submitting their own completion
    if (userId != currentUser.uid) {
      return _errorResponse(
        'forbidden',
        'Users can only submit their own completions',
      );
    }

    try {
      final success = await repository.submitChallengeCompletion(
        userId: userId,
        stars: stars,
        completionTimeMs: completionTimeMs,
      );

      return _jsonResponse({'success': success});
    } catch (e) {
      return _errorResponse('submit_failed', e.toString());
    }
  }

  /// GET /api/daily-challenge/completed/:userId
  ///
  /// Check if a user has completed today's challenge.
  /// Path params:
  ///   - userId: User ID to check
  /// Response: {"completed": bool, "userId": string}
  Future<Response> _handleCheckCompleted(Request request, String userId) async {
    try {
      final completed = await repository.hasCompletedToday(userId);

      return _jsonResponse({'completed': completed, 'userId': userId});
    } catch (e) {
      return _errorResponse('check_failed', e.toString());
    }
  }

  /// Validates the completion request body. Returns error response if invalid.
  Response? _validateCompletionRequest(Map<String, dynamic> body) {
    final userId = body['userId'];
    final stars = body['stars'];
    final completionTimeMs = body['completionTimeMs'];

    if (userId == null) {
      return _errorResponse('missing_user_id', 'Request must include "userId"');
    }
    if (userId is! String || userId.isEmpty) {
      return _errorResponse(
        'invalid_user_id',
        '"userId" must be a non-empty string',
      );
    }
    if (stars == null) {
      return _errorResponse('missing_stars', 'Request must include "stars"');
    }
    if (stars is! int || stars < 1 || stars > 3) {
      return _errorResponse(
        'invalid_stars',
        '"stars" must be an integer between 1 and 3',
      );
    }
    if (completionTimeMs == null) {
      return _errorResponse(
        'missing_completion_time',
        'Request must include "completionTimeMs"',
      );
    }
    if (completionTimeMs is! int || completionTimeMs < 0) {
      return _errorResponse(
        'invalid_completion_time',
        '"completionTimeMs" must be a non-negative integer',
      );
    }
    return null;
  }

  /// Serializes a DailyChallenge to JSON.
  Map<String, dynamic> _serializeChallenge(DailyChallenge challenge) {
    return {
      'id': challenge.id,
      'date': challenge.date.toIso8601String(),
      'level': {'id': challenge.level.id, 'size': challenge.level.size},
      'completionCount': challenge.completionCount,
      if (challenge.userBestTime != null)
        'userBestTimeMs': challenge.userBestTime,
      if (challenge.userStars != null) 'userStars': challenge.userStars,
      if (challenge.userRank != null) 'userRank': challenge.userRank,
    };
  }

  /// Serializes a LeaderboardEntry to JSON.
  Map<String, dynamic> _serializeLeaderboardEntry(LeaderboardEntry entry) {
    return {
      'userId': entry.userId,
      'username': entry.username,
      'avatarUrl': entry.avatarUrl,
      'rank': entry.rank,
      if (entry.completionTime != null)
        'completionTimeMs': entry.completionTime,
      if (entry.stars != null) 'stars': entry.stars,
      'updatedAt': entry.updatedAt.toIso8601String(),
    };
  }

  /// Formats a date as YYYY-MM-DD.
  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// Parses an integer parameter with validation.
  int _parseIntParam(String? value, {required int defaultValue, int? max}) {
    if (value == null) return defaultValue;
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 0) return defaultValue;
    if (max != null && parsed > max) return max;
    return parsed;
  }

  /// Parses JSON from request body, returns null if invalid.
  Future<Map<String, dynamic>?> _parseJsonBody(Request request) async {
    try {
      final bodyString = await request.readAsString();
      if (bodyString.isEmpty) return null;
      return jsonDecode(bodyString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Creates an error response with consistent format.
  static Response _errorResponse(String error, String message) {
    return _jsonResponse(
      {'success': false, 'error': error, 'message': message},
      statusCode: error == 'unauthorized'
          ? 401
          : error == 'forbidden'
          ? 403
          : 400,
    );
  }

  /// Creates a JSON response with proper content type.
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
