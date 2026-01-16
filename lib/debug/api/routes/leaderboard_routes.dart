import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../domain/models/leaderboard_entry.dart';
import '../../../domain/services/auth_repository.dart';
import '../../../domain/services/leaderboard_repository.dart';

/// REST API routes for leaderboard operations.
///
/// Provides endpoints for AI agents to interact with leaderboards:
/// - GET /api/leaderboard?limit=N&offset=N - Get top players from global leaderboard
/// - GET /api/leaderboard/daily?date=YYYY-MM-DD&limit=N - Get daily challenge leaderboard
/// - GET /api/leaderboard/rank/:userId - Get specific user's rank
/// - POST /api/leaderboard/scores - Submit a score (requires authentication)
///
/// Uses LeaderboardRepository for leaderboard operations and AuthRepository
/// for authentication checks on protected endpoints.
class LeaderboardRoutes {
  final LeaderboardRepository repository;
  final AuthRepository authRepository;

  LeaderboardRoutes({required this.repository, required this.authRepository});

  /// Creates a router with all leaderboard routes.
  Router get router {
    final router = Router();

    router.get('/', _handleGetLeaderboard);
    router.get('/daily', _handleGetDailyLeaderboard);
    router.get('/rank/<userId>', _handleGetUserRank);
    router.post('/scores', _handleSubmitScore);

    return router;
  }

  /// GET /api/leaderboard?limit=N&offset=N
  ///
  /// Get top players from the global leaderboard.
  /// Query params:
  ///   - limit: Number of entries to fetch (default: 100, max: 500)
  ///   - offset: Pagination offset (default: 0)
  /// Response: {"entries": [LeaderboardEntry...], "count": int}
  Future<Response> _handleGetLeaderboard(Request request) async {
    try {
      final params = request.url.queryParameters;
      final limit = _parseIntParam(
        params['limit'],
        defaultValue: 100,
        max: 500,
      );
      final offset = _parseIntParam(params['offset'], defaultValue: 0);

      final entries = await repository.getTopPlayers(
        limit: limit,
        offset: offset,
      );

      return _jsonResponse({
        'entries': entries.map(_serializeEntry).toList(),
        'count': entries.length,
      });
    } catch (e) {
      return _errorResponse('fetch_failed', e.toString());
    }
  }

  /// GET /api/leaderboard/daily?date=YYYY-MM-DD&limit=N
  ///
  /// Get daily challenge leaderboard for a specific date.
  /// Query params:
  ///   - date: Date in YYYY-MM-DD format (default: today UTC)
  ///   - limit: Number of entries to fetch (default: 100, max: 500)
  /// Response: {"entries": [LeaderboardEntry...], "date": string, "count": int}
  Future<Response> _handleGetDailyLeaderboard(Request request) async {
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

      final entries = await repository.getDailyChallengeLeaderboard(
        date: date,
        limit: limit,
      );

      return _jsonResponse({
        'entries': entries.map(_serializeEntry).toList(),
        'date': _formatDate(date),
        'count': entries.length,
      });
    } catch (e) {
      return _errorResponse('fetch_failed', e.toString());
    }
  }

  /// GET /api/leaderboard/rank/:userId
  ///
  /// Get a specific user's rank on the global leaderboard.
  /// Path params:
  ///   - userId: User ID to query
  /// Response: {"entry": LeaderboardEntry?} (null if user not found)
  Future<Response> _handleGetUserRank(Request request, String userId) async {
    try {
      final entry = await repository.getUserRank(userId);

      if (entry == null) {
        return _jsonResponse({'entry': null});
      }

      return _jsonResponse({'entry': _serializeEntry(entry)});
    } catch (e) {
      return _errorResponse('fetch_failed', e.toString());
    }
  }

  /// POST /api/leaderboard/scores
  ///
  /// Submit a score to the leaderboard.
  /// Requires authentication (user must be logged in).
  /// Request body: {"userId": string, "stars": int, "levelId"?: string}
  /// Response: {"success": bool, "error"?: string}
  Future<Response> _handleSubmitScore(Request request) async {
    // Check authentication
    final currentUser = await authRepository.getCurrentUser();
    if (currentUser == null) {
      return _errorResponse(
        'unauthorized',
        'User must be logged in to submit scores',
      );
    }

    final body = await _parseJsonBody(request);
    if (body == null) {
      return _errorResponse('invalid_json', 'Request body must be valid JSON');
    }

    final validationError = _validateSubmitScoreRequest(body);
    if (validationError != null) return validationError;

    final userId = body['userId'] as String;
    final stars = body['stars'] as int;
    final levelId = body['levelId'] as String?;

    // Verify the user is submitting their own score
    if (userId != currentUser.uid) {
      return _errorResponse(
        'forbidden',
        'Users can only submit their own scores',
      );
    }

    try {
      final success = await repository.submitScore(
        userId: userId,
        stars: stars,
        levelId: levelId,
      );

      return _jsonResponse({'success': success});
    } catch (e) {
      return _errorResponse('submit_failed', e.toString());
    }
  }

  /// Validates the submit score request body. Returns error response if invalid.
  Response? _validateSubmitScoreRequest(Map<String, dynamic> body) {
    final userId = body['userId'];
    final stars = body['stars'];

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
    if (stars is! int || stars < 0) {
      return _errorResponse(
        'invalid_stars',
        '"stars" must be a non-negative integer',
      );
    }
    return null;
  }

  /// Serializes a LeaderboardEntry to JSON.
  Map<String, dynamic> _serializeEntry(LeaderboardEntry entry) {
    return {
      'userId': entry.userId,
      'username': entry.username,
      'avatarUrl': entry.avatarUrl,
      'totalStars': entry.totalStars,
      'rank': entry.rank,
      'updatedAt': entry.updatedAt.toIso8601String(),
      if (entry.completionTime != null)
        'completionTimeMs': entry.completionTime,
      if (entry.stars != null) 'stars': entry.stars,
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
