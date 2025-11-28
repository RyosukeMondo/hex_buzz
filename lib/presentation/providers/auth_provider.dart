import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/auth_result.dart';
import '../../domain/models/user.dart';
import '../../domain/services/auth_repository.dart';

/// Provider for the auth repository (dependency injection point).
///
/// Override this provider in main.dart with a concrete implementation
/// (e.g., LocalAuthRepository).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError(
    'authRepositoryProvider must be overridden with a concrete implementation',
  );
});

/// AsyncNotifier for managing user authentication state.
///
/// Handles login, registration, logout, and guest mode.
/// Integrates with [AuthRepository] for authentication operations.
class AuthNotifier extends AsyncNotifier<User?> {
  late AuthRepository _repository;

  @override
  Future<User?> build() async {
    _repository = ref.watch(authRepositoryProvider);
    return _repository.getCurrentUser();
  }

  /// Attempts to log in with the given credentials.
  ///
  /// Returns [AuthResult] indicating success or failure.
  /// On success, updates state with the logged-in user.
  Future<AuthResult> login(String username, String password) async {
    state = const AsyncValue.loading();

    final result = await _repository.login(username, password);

    if (result.success && result.user != null) {
      state = AsyncValue.data(result.user);
    } else {
      // Restore to no user state on failure
      state = const AsyncValue.data(null);
    }

    return result;
  }

  /// Registers a new user with the given credentials.
  ///
  /// Returns [AuthResult] indicating success or failure.
  /// On success, updates state with the newly created user.
  Future<AuthResult> register(String username, String password) async {
    state = const AsyncValue.loading();

    final result = await _repository.register(username, password);

    if (result.success && result.user != null) {
      state = AsyncValue.data(result.user);
    } else {
      // Restore to no user state on failure
      state = const AsyncValue.data(null);
    }

    return result;
  }

  /// Logs out the current user.
  ///
  /// Clears the auth state and sets user to null.
  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _repository.logout();
    state = const AsyncValue.data(null);
  }

  /// Creates a guest session for local-only play.
  ///
  /// Guest users can play the game but their progress is only stored locally.
  Future<AuthResult> playAsGuest() async {
    state = const AsyncValue.loading();

    final result = await _repository.loginAsGuest();

    if (result.success && result.user != null) {
      state = AsyncValue.data(result.user);
    } else {
      // Restore to no user state on failure
      state = const AsyncValue.data(null);
    }

    return result;
  }
}

/// Provider for authentication state management.
final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);
