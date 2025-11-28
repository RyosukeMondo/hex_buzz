import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:hex_buzz/debug/api/server.dart';
import 'package:hex_buzz/domain/data/test_level.dart';
import 'package:hex_buzz/domain/models/game_mode.dart';
import 'package:hex_buzz/domain/models/progress_state.dart';
import 'package:hex_buzz/domain/services/game_engine.dart';
import 'package:hex_buzz/domain/services/progress_repository.dart';

/// In-memory implementation of [ProgressRepository] for testing.
///
/// Stores progress per-user. Uses 'api_test_user' as default user for API tests.
class InMemoryProgressRepository implements ProgressRepository {
  static const String defaultUserId = 'api_test_user';
  final Map<String, ProgressState> _userProgress = {};

  @override
  Future<ProgressState> loadForUser(String userId) async {
    return _userProgress[userId] ?? const ProgressState.empty();
  }

  @override
  Future<void> saveForUser(String userId, ProgressState state) async {
    _userProgress[userId] = state;
  }

  @override
  Future<void> resetForUser(String userId) async {
    _userProgress.remove(userId);
  }
}

void main() {
  group('ProgressRoutes', () {
    late GameEngine engine;
    late InMemoryProgressRepository repository;
    late DebugApiServer server;
    const testPort = 8183;
    late String baseUrl;

    setUp(() async {
      engine = GameEngine(level: getTestLevel(), mode: GameMode.practice);
      repository = InMemoryProgressRepository();
      server = DebugApiServer(
        engine: engine,
        progressRepository: repository,
        port: testPort,
      );
      await server.start();
      baseUrl = 'http://localhost:$testPort';
    });

    tearDown(() async {
      await server.stop();
    });

    group('GET /api/progress/', () {
      test('returns empty state initially', () async {
        final response = await http.get(Uri.parse('$baseUrl/api/progress/'));

        expect(response.statusCode, equals(200));
        expect(response.headers['content-type'], contains('application/json'));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['totalStars'], equals(0));
        expect(body['completedLevels'], equals(0));
        expect(body['highestUnlockedLevel'], equals(0));
        expect(body['levels'], isEmpty);
      });

      test('returns progress state after completion', () async {
        // Complete a level first
        await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'level': 0, 'timeMs': 8000}),
        );

        final response = await http.get(Uri.parse('$baseUrl/api/progress/'));

        expect(response.statusCode, equals(200));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['totalStars'], equals(3)); // 8s = 3 stars
        expect(body['completedLevels'], equals(1));
        expect(body['highestUnlockedLevel'], equals(1));

        final levels = body['levels'] as Map<String, dynamic>;
        expect(levels.containsKey('0'), isTrue);

        final level0 = levels['0'] as Map<String, dynamic>;
        expect(level0['completed'], isTrue);
        expect(level0['stars'], equals(3));
        expect(level0['bestTimeMs'], equals(8000));
      });
    });

    group('POST /api/progress/complete', () {
      test('completes level 0 with 3 stars (time <= 10s)', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'level': 0, 'timeMs': 9999}),
        );

        expect(response.statusCode, equals(200));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isTrue);
        expect(body['stars'], equals(3));

        final progress = body['progress'] as Map<String, dynamic>;
        expect(progress['totalStars'], equals(3));
        expect(progress['completedLevels'], equals(1));
      });

      test('completes level with 2 stars (10s < time <= 30s)', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'level': 0, 'timeMs': 25000}),
        );

        expect(response.statusCode, equals(200));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isTrue);
        expect(body['stars'], equals(2));
      });

      test('completes level with 1 star (30s < time <= 60s)', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'level': 0, 'timeMs': 45000}),
        );

        expect(response.statusCode, equals(200));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isTrue);
        expect(body['stars'], equals(1));
      });

      test('completes level with 0 stars (time > 60s)', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'level': 0, 'timeMs': 65000}),
        );

        expect(response.statusCode, equals(200));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isTrue);
        expect(body['stars'], equals(0));
      });

      test('unlocks next level after completion', () async {
        // Complete level 0
        await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'level': 0, 'timeMs': 8000}),
        );

        // Level 1 should now be unlocked - try to complete it
        final response = await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'level': 1, 'timeMs': 15000}),
        );

        expect(response.statusCode, equals(200));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isTrue);
        expect(body['stars'], equals(2)); // 15s = 2 stars

        final progress = body['progress'] as Map<String, dynamic>;
        expect(progress['completedLevels'], equals(2));
        expect(progress['totalStars'], equals(5)); // 3 + 2
      });

      test('rejects locked level', () async {
        // Try to complete level 1 without completing level 0
        final response = await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'level': 1, 'timeMs': 8000}),
        );

        expect(response.statusCode, equals(400));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('level_locked'));
        expect(body['message'], contains('Level 1'));
      });

      test('rejects missing level', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'timeMs': 8000}),
        );

        expect(response.statusCode, equals(400));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('missing_level'));
      });

      test('rejects missing timeMs', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'level': 0}),
        );

        expect(response.statusCode, equals(400));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('missing_time'));
      });

      test('rejects invalid level type', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'level': 'abc', 'timeMs': 8000}),
        );

        expect(response.statusCode, equals(400));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('invalid_level'));
      });

      test('rejects negative level', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'level': -1, 'timeMs': 8000}),
        );

        expect(response.statusCode, equals(400));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('invalid_level'));
      });

      test('rejects invalid timeMs type', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'level': 0, 'timeMs': 'slow'}),
        );

        expect(response.statusCode, equals(400));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('invalid_time'));
      });

      test('rejects negative timeMs', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'level': 0, 'timeMs': -100}),
        );

        expect(response.statusCode, equals(400));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('invalid_time'));
      });

      test('rejects invalid JSON body', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: 'not valid json',
        );

        expect(response.statusCode, equals(400));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('invalid_json'));
      });

      test('rejects empty body', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: '',
        );

        expect(response.statusCode, equals(400));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('invalid_json'));
      });
    });

    group('POST /api/progress/reset', () {
      test('resets all progress', () async {
        // Complete some levels first
        await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'level': 0, 'timeMs': 8000}),
        );

        // Reset
        final response = await http.post(
          Uri.parse('$baseUrl/api/progress/reset'),
        );

        expect(response.statusCode, equals(200));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isTrue);

        final progress = body['progress'] as Map<String, dynamic>;
        expect(progress['totalStars'], equals(0));
        expect(progress['completedLevels'], equals(0));
        expect(progress['highestUnlockedLevel'], equals(0));
      });

      test('returns empty state after reset', () async {
        // Complete a level
        await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'level': 0, 'timeMs': 8000}),
        );

        // Reset
        await http.post(Uri.parse('$baseUrl/api/progress/reset'));

        // Check state
        final response = await http.get(Uri.parse('$baseUrl/api/progress/'));

        expect(response.statusCode, equals(200));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['totalStars'], equals(0));
        expect(body['completedLevels'], equals(0));
        expect(body['levels'], isEmpty);
      });

      test('allows completing levels again after reset', () async {
        // Complete level 0
        await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'level': 0, 'timeMs': 8000}),
        );

        // Reset
        await http.post(Uri.parse('$baseUrl/api/progress/reset'));

        // Complete level 0 again
        final response = await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'level': 0, 'timeMs': 15000}),
        );

        expect(response.statusCode, equals(200));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isTrue);
        expect(body['stars'], equals(2)); // 15s = 2 stars
      });
    });

    group('star calculation boundaries', () {
      test('exactly 10000ms gets 3 stars', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'level': 0, 'timeMs': 10000}),
        );

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['stars'], equals(3));
      });

      test('10001ms gets 2 stars', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'level': 0, 'timeMs': 10001}),
        );

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['stars'], equals(2));
      });

      test('exactly 30000ms gets 2 stars', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'level': 0, 'timeMs': 30000}),
        );

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['stars'], equals(2));
      });

      test('30001ms gets 1 star', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'level': 0, 'timeMs': 30001}),
        );

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['stars'], equals(1));
      });

      test('exactly 60000ms gets 1 star', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'level': 0, 'timeMs': 60000}),
        );

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['stars'], equals(1));
      });

      test('60001ms gets 0 stars', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/progress/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'level': 0, 'timeMs': 60001}),
        );

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['stars'], equals(0));
      });
    });
  });

  group('ProgressRoutes disabled', () {
    test('routes not available when no repository provided', () async {
      final engine = GameEngine(level: getTestLevel(), mode: GameMode.practice);
      final server = DebugApiServer(
        engine: engine,
        port: 8184,
        // No progressRepository provided
      );
      await server.start();

      try {
        final response = await http.get(
          Uri.parse('http://localhost:8184/api/progress/'),
        );
        expect(response.statusCode, equals(404));
      } finally {
        await server.stop();
      }
    });
  });
}
