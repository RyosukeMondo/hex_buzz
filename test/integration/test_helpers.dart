// Shared test helpers for integration tests.
//
// Contains mock repositories and utility functions for E2E testing.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/auth_result.dart';
import 'package:hex_buzz/domain/models/hex_cell.dart';
import 'package:hex_buzz/domain/models/level.dart';
import 'package:hex_buzz/domain/models/progress_state.dart';
import 'package:hex_buzz/domain/models/user.dart';
import 'package:hex_buzz/domain/services/auth_repository.dart';
import 'package:hex_buzz/domain/services/level_repository.dart';
import 'package:hex_buzz/domain/services/progress_repository.dart';
import 'package:hex_buzz/main.dart';
import 'package:hex_buzz/presentation/providers/auth_provider.dart';
import 'package:hex_buzz/presentation/providers/game_provider.dart';
import 'package:hex_buzz/presentation/providers/progress_provider.dart';
import 'package:hex_buzz/presentation/screens/auth/auth_screen.dart';
import 'package:hex_buzz/presentation/screens/front/front_screen.dart';
import 'package:hex_buzz/presentation/screens/game/game_screen.dart';
import 'package:hex_buzz/presentation/screens/level_select/level_select_screen.dart';
import 'package:hex_buzz/presentation/theme/honey_theme.dart';

/// Mock auth repository that supports registration, login, logout, and guest mode.
class MockAuthRepository implements AuthRepository {
  final Map<String, _StoredUser> _users = {};
  User? _currentUser;
  final _authController = StreamController<User?>.broadcast();

  @override
  Future<User?> getCurrentUser() async => _currentUser;

  @override
  Future<AuthResult> register(String username, String password) async {
    if (username.length < 3) {
      return const AuthFailure('Username must be at least 3 characters');
    }
    if (password.length < 6) {
      return const AuthFailure('Password must be at least 6 characters');
    }
    if (_users.containsKey(username.toLowerCase())) {
      return const AuthFailure('Username already taken');
    }

    final user = User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      username: username,
      createdAt: DateTime.now(),
      isGuest: false,
    );

    _users[username.toLowerCase()] = _StoredUser(
      user: user,
      password: password,
    );
    _currentUser = user;
    _authController.add(user);
    return AuthSuccess(user);
  }

  @override
  Future<AuthResult> login(String username, String password) async {
    final stored = _users[username.toLowerCase()];
    if (stored == null) return const AuthFailure('User not found');
    if (stored.password != password) {
      return const AuthFailure('Invalid password');
    }

    _currentUser = stored.user;
    _authController.add(stored.user);
    return AuthSuccess(stored.user);
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    // Mock Google Sign-In for testing
    final user = User(
      id: 'google_${DateTime.now().millisecondsSinceEpoch}',
      username: 'TestUser',
      createdAt: DateTime.now(),
      isGuest: false,
    );
    _currentUser = user;
    _authController.add(user);
    return AuthSuccess(user);
  }

  @override
  Future<void> signOut() async {
    await logout();
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _authController.add(null);
  }

  @override
  Future<AuthResult> loginAsGuest() async {
    final guestUser = User.guest();
    _currentUser = guestUser;
    _authController.add(guestUser);
    return AuthSuccess(guestUser);
  }

  @override
  Stream<User?> authStateChanges() => _authController.stream;

  void dispose() => _authController.close();
}

class _StoredUser {
  final User user;
  final String password;
  _StoredUser({required this.user, required this.password});
}

/// In-memory progress repository for E2E testing.
class MockProgressRepository implements ProgressRepository {
  final Map<String, ProgressState> _userProgress = {};
  int saveCount = 0;

  @override
  Future<ProgressState> loadForUser(String userId) async {
    return _userProgress[userId] ?? const ProgressState.empty();
  }

  @override
  Future<void> saveForUser(String userId, ProgressState state) async {
    _userProgress[userId] = state;
    saveCount++;
  }

  @override
  Future<void> resetForUser(String userId) async {
    _userProgress.remove(userId);
  }

  ProgressState getStateForUser(String userId) {
    return _userProgress[userId] ?? const ProgressState.empty();
  }
}

/// Test level repository with simple, solvable levels.
class MockLevelRepository extends LevelRepository {
  final List<Level> _levels;
  MockLevelRepository(this._levels);

  @override
  bool get isLoaded => true;

  @override
  int get totalLevelCount => _levels.length;

  @override
  Future<void> load() async {}

  @override
  Level? getLevelByIndex(int index) {
    if (index < 0 || index >= _levels.length) return null;
    return _levels[index];
  }

  @override
  Level? getRandomLevel(int size) => _levels.firstOrNull;
}

/// Creates a simple 2-cell level that can be solved in one move.
Level createSimpleLevel({required String id}) {
  final cells = <(int, int), HexCell>{
    (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
    (1, 0): const HexCell(q: 1, r: 0, checkpoint: 2),
  };
  return Level(id: id, size: 2, cells: cells, walls: {}, checkpointCount: 2);
}

/// Creates a 3-cell level requiring 2 moves.
Level createThreeCellLevel({required String id}) {
  final cells = <(int, int), HexCell>{
    (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
    (1, 0): const HexCell(q: 1, r: 0),
    (2, 0): const HexCell(q: 2, r: 0, checkpoint: 2),
  };
  return Level(id: id, size: 3, cells: cells, walls: {}, checkpointCount: 2);
}

/// Creates the full app with mock dependencies starting from FrontScreen.
Widget createFullApp({
  required MockAuthRepository authRepo,
  required MockProgressRepository progressRepo,
  required MockLevelRepository levelRepo,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepo),
      progressRepositoryProvider.overrideWithValue(progressRepo),
      levelRepositoryProvider.overrideWithValue(levelRepo),
    ],
    child: MaterialApp(
      title: 'HexBuzz',
      theme: HoneyTheme.lightTheme,
      initialRoute: AppRoutes.front,
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        final path = uri.path;

        Widget page;
        switch (path) {
          case AppRoutes.front:
            page = const FrontScreen();
          case AppRoutes.auth:
            page = const AuthScreen();
          case AppRoutes.levels:
            page = const LevelSelectScreen();
          case AppRoutes.game:
            final levelIndex = settings.arguments as int?;
            page = GameScreen(levelIndex: levelIndex);
          default:
            page = const FrontScreen();
        }

        return MaterialPageRoute(builder: (_) => page, settings: settings);
      },
    ),
  );
}

/// Helper to pump multiple times without waiting for animations to settle.
Future<void> pumpFrames(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Waits for Riverpod async providers to initialize.
Future<void> waitForProviders(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
