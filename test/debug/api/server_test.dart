import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:honeycomb_one_pass/debug/api/server.dart';
import 'package:honeycomb_one_pass/domain/data/test_level.dart';
import 'package:honeycomb_one_pass/domain/models/game_mode.dart';
import 'package:honeycomb_one_pass/domain/services/game_engine.dart';

void main() {
  group('DebugApiServer', () {
    late GameEngine engine;
    late DebugApiServer server;
    const testPort = 8181;

    setUp(() async {
      engine = GameEngine(level: getTestLevel(), mode: GameMode.practice);
      server = DebugApiServer(engine: engine, port: testPort);
      await server.start();
    });

    tearDown(() async {
      await server.stop();
    });

    test('starts and stops correctly', () async {
      expect(server.isRunning, isTrue);
      await server.stop();
      expect(server.isRunning, isFalse);
    });

    test('health endpoint returns ok', () async {
      final response = await http.get(
        Uri.parse('http://localhost:$testPort/api/health'),
      );

      expect(response.statusCode, equals(200));
      expect(response.headers['content-type'], contains('application/json'));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['status'], equals('ok'));
      expect(body['timestamp'], isNotNull);
    });

    test('returns CORS headers', () async {
      final response = await http.get(
        Uri.parse('http://localhost:$testPort/api/health'),
      );

      expect(response.headers['access-control-allow-origin'], equals('*'));
    });

    test('handles OPTIONS preflight request', () async {
      final request = http.Request(
        'OPTIONS',
        Uri.parse('http://localhost:$testPort/api/health'),
      );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      expect(response.statusCode, equals(200));
      expect(
        response.headers['access-control-allow-methods'],
        contains('POST'),
      );
    });

    test('placeholder endpoints return 501', () async {
      final stateResponse = await http.get(
        Uri.parse('http://localhost:$testPort/api/game/state'),
      );
      expect(stateResponse.statusCode, equals(501));

      final body = jsonDecode(stateResponse.body) as Map<String, dynamic>;
      expect(body['error'], equals('not_implemented'));
    });

    test('rejects non-JSON content type on POST', () async {
      final response = await http.post(
        Uri.parse('http://localhost:$testPort/api/game/move'),
        headers: {'Content-Type': 'text/plain'},
        body: 'not json',
      );

      expect(response.statusCode, equals(415));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['error'], equals('invalid_content_type'));
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
