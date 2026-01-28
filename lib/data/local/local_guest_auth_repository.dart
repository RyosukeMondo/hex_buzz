import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/auth_result.dart';
import '../../domain/models/user.dart' as domain;
import '../../domain/services/auth_repository.dart';

/// Local-only authentication repository for guest users.
///
/// Stores guest user data in SharedPreferences. Guest users can play
/// immediately without Firebase, and their progress is stored locally only.
class LocalGuestAuthRepository implements AuthRepository {
  static const String _guestIdKey = 'guest_user_id';
  static const String _guestNameKey = 'guest_display_name';
  static const String _guestCreatedKey = 'guest_created_at';

  final SharedPreferences _prefs;
  final Uuid _uuid;
  final StreamController<domain.User?> _authStateController =
      StreamController<domain.User?>.broadcast();

  LocalGuestAuthRepository({required SharedPreferences prefs, Uuid? uuid})
    : _prefs = prefs,
      _uuid = uuid ?? const Uuid() {
    // Initialize with current guest user if exists
    _loadCurrentGuest().then((user) {
      if (user != null) {
        _authStateController.add(user);
      }
    });
  }

  @override
  Future<AuthResult> loginAsGuest() async {
    try {
      // Check for existing guest
      final existingUser = await _loadCurrentGuest();
      if (existingUser != null) {
        _authStateController.add(existingUser);
        return AuthSuccess(existingUser);
      }

      // Create new guest
      final guestId = _uuid.v4();
      final displayName = _generateGuestName();
      final now = DateTime.now();

      await _prefs.setString(_guestIdKey, guestId);
      await _prefs.setString(_guestNameKey, displayName);
      await _prefs.setString(_guestCreatedKey, now.toIso8601String());

      final user = domain.User(
        id: guestId,
        username: displayName,
        createdAt: now,
        isGuest: true,
        displayName: displayName,
      );

      _authStateController.add(user);
      return AuthSuccess(user);
    } catch (e) {
      return AuthFailure('Failed to create guest session: ${e.toString()}');
    }
  }

  @override
  Future<domain.User?> getCurrentUser() async {
    return await _loadCurrentGuest();
  }

  @override
  Future<void> signOut() async {
    await _prefs.remove(_guestIdKey);
    await _prefs.remove(_guestNameKey);
    await _prefs.remove(_guestCreatedKey);
    _authStateController.add(null);
  }

  @override
  Future<void> logout() async {
    await signOut();
  }

  @override
  Stream<domain.User?> authStateChanges() => _authStateController.stream;

  /// Loads the current guest user from SharedPreferences.
  Future<domain.User?> _loadCurrentGuest() async {
    final guestId = _prefs.getString(_guestIdKey);
    if (guestId == null) return null;

    final displayName = _prefs.getString(_guestNameKey) ?? _generateGuestName();
    final createdAtStr = _prefs.getString(_guestCreatedKey);
    final createdAt = createdAtStr != null
        ? DateTime.parse(createdAtStr)
        : DateTime.now();

    return domain.User(
      id: guestId,
      username: displayName,
      createdAt: createdAt,
      isGuest: true,
      displayName: displayName,
    );
  }

  /// Generates a random guest display name.
  String _generateGuestName() {
    final random = (DateTime.now().millisecondsSinceEpoch % 10000)
        .toString()
        .padLeft(4, '0');
    return 'Guest_$random';
  }

  // Not supported for guest users - return failures

  @override
  Future<AuthResult> signInWithGoogle() async {
    return const AuthFailure(
      'Google Sign-In not available for guest users. Please use the hybrid auth repository.',
    );
  }

  @override
  Future<AuthResult> login(String username, String password) async {
    return const AuthFailure(
      'Username/password login not supported for guest users.',
    );
  }

  @override
  Future<AuthResult> register(String username, String password) async {
    return const AuthFailure('Registration not supported for guest users.');
  }

  /// Disposes resources held by this repository.
  void dispose() {
    _authStateController.close();
  }
}
