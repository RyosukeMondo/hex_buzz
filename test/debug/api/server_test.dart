import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:hex_buzz/debug/api/server.dart';
import 'package:hex_buzz/domain/data/test_level.dart';
import 'package:hex_buzz/domain/models/game_mode.dart';
import 'package:hex_buzz/domain/models/hex_cell.dart';
import 'package:hex_buzz/domain/models/hex_edge.dart';
import 'package:hex_buzz/domain/models/level.dart';
import 'package:hex_buzz/domain/services/game_engine.dart';

void main() {
  group('DebugApiServer', () {
    late GameEngine engine;
    late DebugApiServer server;
    const testPort = 8181;
    late String baseUrl;

    setUp(() async {
      engine = GameEngine(level: getTestLevel(), mode: GameMode.practice);
      server = DebugApiServer(engine: engine, port: testPort);
      await server.start();
      baseUrl = 'http://localhost:$testPort';
    });

    tearDown(() async {
      await server.stop();
    });

    group('server lifecycle', () {
      test('starts and stops correctly', () async {
        expect(server.isRunning, isTrue);
        await server.stop();
        expect(server.isRunning, isFalse);
      });

      test('does not fail when stopping already stopped server', () async {
        await server.stop();
        expect(server.isRunning, isFalse);
        await server.stop(); // Should not throw
        expect(server.isRunning, isFalse);
      });
    });

    group('health endpoint', () {
      test('returns ok status', () async {
        final response = await http.get(Uri.parse('$baseUrl/api/health'));

        expect(response.statusCode, equals(200));
        expect(response.headers['content-type'], contains('application/json'));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['status'], equals('ok'));
        expect(body['timestamp'], isNotNull);
      });
    });

    group('CORS', () {
      test('returns CORS headers on regular requests', () async {
        final response = await http.get(Uri.parse('$baseUrl/api/health'));

        expect(response.headers['access-control-allow-origin'], equals('*'));
      });

      test('handles OPTIONS preflight request', () async {
        final request = http.Request(
          'OPTIONS',
          Uri.parse('$baseUrl/api/health'),
        );
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        expect(response.statusCode, equals(200));
        expect(
          response.headers['access-control-allow-methods'],
          contains('POST'),
        );
        expect(
          response.headers['access-control-allow-headers'],
          contains('Content-Type'),
        );
      });
    });

    group('content type validation', () {
      test('rejects non-JSON content type on POST', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'text/plain'},
          body: 'not json',
        );

        expect(response.statusCode, equals(415));
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['error'], equals('invalid_content_type'));
      });

      test('accepts application/json content type', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'q': 0, 'r': 0}),
        );

        // Should not return 415 (content type error)
        expect(response.statusCode, isNot(415));
      });
    });

    group('GET /api/game/state', () {
      test('returns initial game state', () async {
        final response = await http.get(Uri.parse('$baseUrl/api/game/state'));

        expect(response.statusCode, equals(200));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['level'], isNotNull);
        expect(body['level']['size'], equals(3));
        expect(body['level']['checkpointCount'], equals(2));
        expect(body['mode'], equals('practice'));
        expect(body['path'], isEmpty);
        expect(body['isStarted'], isFalse);
        expect(body['isComplete'], isFalse);
        expect(body['nextCheckpoint'], equals(1));
      });

      test('returns updated state after moves', () async {
        // Make a move first - start at (0, -3)
        await http.post(
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'q': 0, 'r': -2}),
        );

        final response = await http.get(Uri.parse('$baseUrl/api/game/state'));
        final body = jsonDecode(response.body) as Map<String, dynamic>;

        expect(body['path'], hasLength(1));
        expect(body['isStarted'], isTrue);
        expect(body['nextCheckpoint'], equals(2));
      });
    });

    group('POST /api/game/move', () {
      test('valid first move to start cell succeeds', () async {
        // Start cell is now at (0, -3) in the hexagonal grid
        final response = await http.post(
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'q': 0, 'r': -2}),
        );

        expect(response.statusCode, equals(200));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isTrue);
        expect(body['state']['path'], hasLength(1));
        expect(body['state']['isStarted'], isTrue);
      });

      test('valid adjacent move succeeds', () async {
        // First move to start at (0, -3)
        await http.post(
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'q': 0, 'r': -2}),
        );

        // Adjacent move to (1, -3) - neighbor of start
        final response = await http.post(
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'q': 1, 'r': -2}),
        );

        expect(response.statusCode, equals(200));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isTrue);
        expect(body['state']['path'], hasLength(2));
      });

      test('move to non-start cell as first move fails', () async {
        // Try moving to center (0, 0) which is not the start cell
        final response = await http.post(
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'q': 0, 'r': 0}),
        );

        expect(response.statusCode, equals(400));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('move_rejected'));
        expect(body['state'], isNotNull);
      });

      test('move to non-adjacent cell fails', () async {
        // First move to start at (0, -3)
        await http.post(
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'q': 0, 'r': -2}),
        );

        // Non-adjacent move to (0, 2) - far away (end cell)
        final response = await http.post(
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'q': 0, 'r': 2}),
        );

        expect(response.statusCode, equals(400));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('move_rejected'));
      });

      test('move to visited cell fails', () async {
        // Build a path: (0,-3) -> (1,-3) -> (2,-3)
        await http.post(
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'q': 0, 'r': -2}),
        );
        await http.post(
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'q': 1, 'r': -2}),
        );
        await http.post(
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'q': 2, 'r': -2}),
        );

        // Try to move back to visited cell
        final response = await http.post(
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'q': 1, 'r': -2}),
        );

        expect(response.statusCode, equals(400));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isFalse);
      });

      test('rejects missing coordinates', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'q': 0}), // Missing 'r'
        );

        expect(response.statusCode, equals(400));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('missing_coordinates'));
      });

      test('rejects invalid coordinate types', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'q': 'invalid', 'r': 0}),
        );

        expect(response.statusCode, equals(400));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('invalid_coordinates'));
      });

      test('rejects invalid JSON body', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/game/move'),
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
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'application/json'},
          body: '',
        );

        expect(response.statusCode, equals(400));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('invalid_json'));
      });

      test('returns isWin true on game completion', () async {
        // This requires completing the entire test level
        // For simplicity, we'll create a fresh server with a simple level
        await server.stop();

        // Create simple 2x2 level
        final cells = <(int, int), HexCell>{
          (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
          (1, 0): const HexCell(q: 1, r: 0),
          (0, 1): const HexCell(q: 0, r: 1),
          (1, 1): const HexCell(q: 1, r: 1, checkpoint: 2),
        };
        final simpleLevel = Level(
          size: 2,
          cells: cells,
          walls: {},
          checkpointCount: 2,
        );

        final simpleEngine = GameEngine(
          level: simpleLevel,
          mode: GameMode.practice,
        );
        server = DebugApiServer(engine: simpleEngine, port: testPort);
        await server.start();

        // Complete the simple level
        await http.post(
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'q': 0, 'r': 0}),
        );
        await http.post(
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'q': 1, 'r': 0}),
        );
        await http.post(
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'q': 0, 'r': 1}),
        );
        final response = await http.post(
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'q': 1, 'r': 1}),
        );

        expect(response.statusCode, equals(200));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isTrue);
        expect(body['isWin'], isTrue);
        expect(body['state']['isComplete'], isTrue);
      });
    });

    group('POST /api/game/reset', () {
      test('resets game to initial state', () async {
        // Make some moves first - start at (0, -3)
        await http.post(
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'q': 0, 'r': -2}),
        );
        await http.post(
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'q': 1, 'r': -2}),
        );

        // Reset
        final response = await http.post(Uri.parse('$baseUrl/api/game/reset'));

        expect(response.statusCode, equals(200));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isTrue);
        expect(body['state']['path'], isEmpty);
        expect(body['state']['isStarted'], isFalse);
        expect(body['state']['nextCheckpoint'], equals(1));
      });

      test('allows playing again after reset', () async {
        // Make a move - start at (0, -3)
        await http.post(
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'q': 0, 'r': -2}),
        );

        // Reset
        await http.post(Uri.parse('$baseUrl/api/game/reset'));

        // Play again - start at (0, -3)
        final response = await http.post(
          Uri.parse('$baseUrl/api/game/move'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'q': 0, 'r': -2}),
        );

        expect(response.statusCode, equals(200));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isTrue);
        expect(body['state']['path'], hasLength(1));
      });
    });

    group('POST /api/level/validate', () {
      test('validates solvable level successfully', () async {
        final levelJson = getTestLevel().toJson();

        final response = await http.post(
          Uri.parse('$baseUrl/api/level/validate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(levelJson),
        );

        expect(response.statusCode, equals(200));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['valid'], isTrue);
        expect(body['solvable'], isTrue);
        expect(body['solution'], isNotNull);
        expect(body['solution'], isNotEmpty);
        expect(body['levelId'], isNotNull);
      });

      test('validates unsolvable level correctly', () async {
        // Create a level with walls blocking all paths
        final cells = <(int, int), HexCell>{
          (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
          (1, 0): const HexCell(q: 1, r: 0),
          (0, 1): const HexCell(q: 0, r: 1),
          (1, 1): const HexCell(q: 1, r: 1, checkpoint: 2),
        };

        // Block all paths from (0,0)
        final walls = <HexEdge>{
          HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0),
          HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 0, cellR2: 1),
        };

        final unsolvableLevel = Level(
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        final response = await http.post(
          Uri.parse('$baseUrl/api/level/validate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(unsolvableLevel.toJson()),
        );

        expect(response.statusCode, equals(200));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['valid'], isTrue);
        expect(body['solvable'], isFalse);
        expect(body['solution'], isNull);
      });

      test('rejects invalid JSON', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/level/validate'),
          headers: {'Content-Type': 'application/json'},
          body: 'not valid json',
        );

        expect(response.statusCode, equals(400));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['valid'], isFalse);
        expect(body['error'], equals('invalid_json'));
      });

      test('rejects malformed level JSON', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/level/validate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'invalid': 'level'}),
        );

        expect(response.statusCode, equals(400));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['valid'], isFalse);
        expect(body['error'], equals('invalid_level_format'));
      });

      test('rejects empty body', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/level/validate'),
          headers: {'Content-Type': 'application/json'},
          body: '',
        );

        expect(response.statusCode, equals(400));

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['valid'], isFalse);
        expect(body['error'], equals('invalid_json'));
      });
    });
  });

  group('startServer helper', () {
    test('creates and starts server', () async {
      final engine = GameEngine(level: getTestLevel(), mode: GameMode.practice);
      final server = await startServer(8182, engine);

      expect(server.isRunning, isTrue);

      await server.stop();
      expect(server.isRunning, isFalse);
    });
  });
}
