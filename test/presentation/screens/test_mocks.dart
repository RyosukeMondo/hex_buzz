import 'dart:async';

import 'package:hex_buzz/domain/models/auth_result.dart';
import 'package:hex_buzz/domain/models/daily_challenge.dart';
import 'package:hex_buzz/domain/models/daily_challenge_completion.dart';
import 'package:hex_buzz/domain/models/leaderboard_entry.dart';
import 'package:hex_buzz/domain/models/level.dart';
import 'package:hex_buzz/domain/models/progress_state.dart';
import 'package:hex_buzz/domain/models/user.dart';
import 'package:hex_buzz/domain/services/auth_repository.dart';
import 'package:hex_buzz/domain/services/daily_challenge_repository.dart';
import 'package:hex_buzz/domain/services/level_repository.dart';
import 'package:hex_buzz/domain/services/notification_service.dart';
import 'package:hex_buzz/domain/services/progress_repository.dart';

/// Mock auth repository for testing that returns a guest user.
class MockAuthRepository implements AuthRepository {
  final User _guestUser = User.guest();

  @override
  Future<User?> getCurrentUser() async => _guestUser;

  @override
  Future<AuthResult> login(String username, String password) async {
    return AuthSuccess(_guestUser);
  }

  @override
  Future<AuthResult> register(String username, String password) async {
    return AuthSuccess(_guestUser);
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    return AuthSuccess(_guestUser);
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> logout() async {}

  @override
  Future<AuthResult> loginAsGuest() async {
    return AuthSuccess(_guestUser);
  }

  @override
  Stream<User?> authStateChanges() {
    return Stream.value(_guestUser);
  }
}

/// Mock progress repository for testing.
class MockProgressRepository implements ProgressRepository {
  final Map<String, ProgressState> _userProgress = {};

  MockProgressRepository([ProgressState? initialState]) {
    if (initialState != null) {
      _userProgress['guest'] = initialState;
    }
  }

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

/// Mock level repository for testing.
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

/// Mock daily challenge repository for testing.
class MockDailyChallengeRepository implements DailyChallengeRepository {
  @override
  Future<DailyChallenge?> getTodaysChallenge() async => null;

  @override
  Future<bool> submitChallengeCompletion({
    required String userId,
    required int stars,
    required int completionTimeMs,
  }) async => false;

  @override
  Future<List<LeaderboardEntry>> getChallengeLeaderboard({
    required DateTime date,
    int limit = 100,
  }) async => [];

  @override
  Future<bool> hasCompletedToday(String userId) async => false;

  @override
  Future<DailyChallengeCompletion?> getCompletion({
    required String userId,
    required String dateId,
  }) async => null;
}

/// Mock notification service for testing.
class MockNotificationService implements NotificationService {
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Future<bool> initialize() async => true;

  @override
  Future<String?> getDeviceToken() async => 'mock-token';

  @override
  Future<bool> subscribeToTopic(String topic) async => true;

  @override
  Future<bool> unsubscribeFromTopic(String topic) async => true;

  @override
  Stream<Map<String, dynamic>> get onMessageReceived => _controller.stream;

  @override
  Future<bool> requestPermission() async => true;
}
