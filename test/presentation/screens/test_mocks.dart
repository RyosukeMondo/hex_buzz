import 'package:hex_buzz/domain/models/auth_result.dart';
import 'package:hex_buzz/domain/models/level.dart';
import 'package:hex_buzz/domain/models/progress_state.dart';
import 'package:hex_buzz/domain/models/user.dart';
import 'package:hex_buzz/domain/services/auth_repository.dart';
import 'package:hex_buzz/domain/services/level_repository.dart';
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
