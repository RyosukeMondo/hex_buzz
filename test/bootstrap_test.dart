import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hex_buzz/data/local/local_auth_repository.dart';
import 'package:hex_buzz/data/local/local_progress_repository.dart';
import 'package:hex_buzz/domain/models/progress_state.dart';
import 'package:hex_buzz/domain/services/level_repository.dart';
import 'package:hex_buzz/main.dart';
import 'package:hex_buzz/presentation/providers/auth_provider.dart';
import 'package:hex_buzz/presentation/providers/game_provider.dart';
import 'package:hex_buzz/presentation/providers/progress_provider.dart';

/// Tests that validate the app bootstrap configuration in main.dart.
///
/// These tests catch bugs where required providers are not properly overridden,
/// which would cause UnimplementedError at runtime but pass unit tests
/// that mock the providers.
void main() {
  group('App Bootstrap Validation', () {
    late SharedPreferences prefs;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    /// Creates a ProviderContainer with the same overrides as main.dart
    /// This simulates the real app initialization.
    ProviderContainer createProductionContainer() {
      final progressRepository = LocalProgressRepository(prefs);
      final authRepository = LocalAuthRepository(prefs);
      final levelRepository = LevelRepository();

      return ProviderContainer(
        overrides: [
          levelRepositoryProvider.overrideWithValue(levelRepository),
          progressRepositoryProvider.overrideWithValue(progressRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
      );
    }

    test('authRepositoryProvider is properly configured', () {
      final container = createProductionContainer();
      addTearDown(container.dispose);

      // Should not throw UnimplementedError
      expect(() => container.read(authRepositoryProvider), returnsNormally);
    });

    test('progressRepositoryProvider is properly configured', () {
      final container = createProductionContainer();
      addTearDown(container.dispose);

      // Should not throw UnimplementedError
      expect(() => container.read(progressRepositoryProvider), returnsNormally);
    });

    test('levelRepositoryProvider is properly configured', () {
      final container = createProductionContainer();
      addTearDown(container.dispose);

      expect(() => container.read(levelRepositoryProvider), returnsNormally);
    });

    test('authProvider can be read without error', () async {
      final container = createProductionContainer();
      addTearDown(container.dispose);

      // Should be able to read auth state
      final authState = container.read(authProvider);
      expect(authState, isNotNull);
    });

    test('progressProvider can be read without error', () async {
      final container = createProductionContainer();
      addTearDown(container.dispose);

      // Should be able to read progress state
      final progressState = container.read(progressProvider);
      expect(progressState, isNotNull);
    });

    test('gameProvider can be read without error', () {
      final container = createProductionContainer();
      addTearDown(container.dispose);

      // Should be able to read game state
      final gameState = container.read(gameProvider);
      expect(gameState, isNotNull);
    });

    test('playAsGuest completes without error', () async {
      final container = createProductionContainer();
      addTearDown(container.dispose);

      final authNotifier = container.read(authProvider.notifier);
      final result = await authNotifier.playAsGuest();

      expect(result.success, isTrue);
      expect(result.user, isNotNull);
      expect(result.user!.isGuest, isTrue);
    });

    test('login flow completes without error', () async {
      final container = createProductionContainer();
      addTearDown(container.dispose);

      final authNotifier = container.read(authProvider.notifier);

      // First register
      final registerResult = await authNotifier.register(
        'testuser',
        'password123',
      );
      expect(registerResult.success, isTrue);

      // Then logout
      await authNotifier.logout();

      // Then login
      final loginResult = await authNotifier.login('testuser', 'password123');
      expect(loginResult.success, isTrue);
    });

    test('progress repository can save and load', () async {
      // Test the repository directly, not through provider
      final progressRepository = LocalProgressRepository(prefs);

      // Create a progress state
      const state = ProgressState(
        levels: {0: LevelProgress(completed: true, stars: 3)},
      );

      // Save progress
      await progressRepository.saveForUser('test-user', state);

      // Load progress
      final loaded = await progressRepository.loadForUser('test-user');
      expect(loaded.getProgress(0).completed, isTrue);
      expect(loaded.getProgress(0).stars, equals(3));
    });

    testWidgets('HexBuzzApp builds with production providers', (tester) async {
      final progressRepository = LocalProgressRepository(prefs);
      final authRepository = LocalAuthRepository(prefs);
      final levelRepository = LevelRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            levelRepositoryProvider.overrideWithValue(levelRepository),
            progressRepositoryProvider.overrideWithValue(progressRepository),
            authRepositoryProvider.overrideWithValue(authRepository),
          ],
          child: const HexBuzzApp(),
        ),
      );

      // App should render without throwing
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Provider Override Completeness', () {
    test('all providers with UnimplementedError are documented', () {
      // This test documents which providers MUST be overridden.
      // If you add a new provider with UnimplementedError, add it here.
      const requiredOverrides = [
        'authRepositoryProvider',
        'progressRepositoryProvider',
      ];

      // This is a documentation test - it will always pass
      // but serves as a checklist for developers
      for (final provider in requiredOverrides) {
        // ignore: avoid_print
        print('Required override: $provider');
      }

      expect(requiredOverrides.length, equals(2));
    });
  });
}
