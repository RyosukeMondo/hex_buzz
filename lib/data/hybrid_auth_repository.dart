import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/models/auth_result.dart';
import '../domain/models/user.dart' as domain;
import '../domain/services/auth_repository.dart';
import 'firebase/firebase_auth_repository.dart';
import 'local/local_guest_auth_repository.dart';

/// Hybrid authentication repository that supports both Firebase and guest authentication.
///
/// Delegates authentication requests to the appropriate repository:
/// - Guest login: LocalGuestAuthRepository
/// - Google Sign-In: FirebaseAuthRepository
/// - Session management: Checks both repositories
///
/// Also handles migration of guest data to Firebase when a guest upgrades to a Firebase account.
class HybridAuthRepository implements AuthRepository {
  final FirebaseAuthRepository _firebaseRepo;
  final LocalGuestAuthRepository _guestRepo;
  final StreamController<domain.User?> _authStateController =
      StreamController<domain.User?>.broadcast();

  AuthRepository _activeRepo;
  domain.User? _currentUser;
  bool _initialized = false;

  HybridAuthRepository({
    required FirebaseAuthRepository firebaseRepo,
    required LocalGuestAuthRepository guestRepo,
  }) : _firebaseRepo = firebaseRepo,
       _guestRepo = guestRepo,
       _activeRepo = guestRepo {
    // Listen to auth state changes from both repositories
    _firebaseRepo.authStateChanges().listen((user) {
      if (user != null) {
        _activeRepo = _firebaseRepo;
        _currentUser = user;
        _authStateController.add(user);
      } else if (_currentUser != null && !(_currentUser?.isGuest ?? false)) {
        // Firebase user signed out
        _currentUser = null;
        _authStateController.add(null);
      }
    });

    _guestRepo.authStateChanges().listen((user) {
      // Only emit guest user if no Firebase user is active
      if (_currentUser == null || (_currentUser?.isGuest ?? false)) {
        if (user != null) {
          _activeRepo = _guestRepo;
        }
        _currentUser = user;
        _authStateController.add(user);
      }
    });
  }

  Future<void> _initializeAuthState() async {
    print('[HybridAuth] Initializing auth state...');

    // Check Firebase first (higher priority)
    final firebaseUser = await _firebaseRepo.getCurrentUser();
    if (firebaseUser != null) {
      print('[HybridAuth] ✓ Firebase user found: ${firebaseUser.email}');
      _activeRepo = _firebaseRepo;
      _currentUser = firebaseUser;
      _authStateController.add(firebaseUser);
      return;
    }

    print('[HybridAuth] No Firebase user, checking guest...');

    // Check guest auth
    final guestUser = await _guestRepo.getCurrentUser();
    if (guestUser != null) {
      print('[HybridAuth] ✓ Guest user found: ${guestUser.username}');
      _activeRepo = _guestRepo;
      _currentUser = guestUser;
      _authStateController.add(guestUser);
    } else {
      print('[HybridAuth] No user found');
    }
  }

  @override
  Future<AuthResult> loginAsGuest() async {
    _activeRepo = _guestRepo;
    final result = await _guestRepo.loginAsGuest();
    if (result is AuthSuccess) {
      _currentUser = result.user;
      _authStateController.add(result.user);
    }
    return result;
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    // Get guest data for potential migration
    final guestUser = await _guestRepo.getCurrentUser();

    // Switch to Firebase repo
    _activeRepo = _firebaseRepo;
    final result = await _firebaseRepo.signInWithGoogle();

    if (result is AuthSuccess) {
      _currentUser = result.user;
      _authStateController.add(result.user);

      // If there was guest data, migrate it
      if (guestUser != null) {
        await _migrateGuestDataToFirebase(guestUser, result.user);
      }
    }

    return result;
  }

  @override
  Future<domain.User?> getCurrentUser() async {
    print('[HybridAuth] getCurrentUser() called, _initialized=$_initialized');
    // Initialize on first call
    if (!_initialized) {
      print('[HybridAuth] First call, initializing...');
      await _initializeAuthState();
      _initialized = true;
      print('[HybridAuth] Initialization complete');
    }

    if (_currentUser != null) {
      return _currentUser;
    }

    // Check Firebase first
    final firebaseUser = await _firebaseRepo.getCurrentUser();
    if (firebaseUser != null) {
      _activeRepo = _firebaseRepo;
      _currentUser = firebaseUser;
      _authStateController.add(firebaseUser);
      return firebaseUser;
    }

    // Check guest
    final guestUser = await _guestRepo.getCurrentUser();
    if (guestUser != null) {
      _activeRepo = _guestRepo;
      _currentUser = guestUser;
      _authStateController.add(guestUser);
      return guestUser;
    }

    return null;
  }

  @override
  Future<void> signOut() async {
    await _activeRepo.signOut();
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<void> logout() async {
    await signOut();
  }

  @override
  Stream<domain.User?> authStateChanges() => _authStateController.stream;

  /// Migrates guest data to Firebase when a guest upgrades to a Firebase account.
  ///
  /// TODO: Implement data migration logic:
  /// - Copy progress from SharedPreferences to Firestore
  /// - Copy level completion data
  /// - Copy statistics
  /// - Clean up local guest data
  Future<void> _migrateGuestDataToFirebase(
    domain.User guestUser,
    domain.User firebaseUser,
  ) async {
    // TODO: Implement data migration
    // For now, just clean up guest session
    await _guestRepo.signOut();
  }

  // Legacy methods - delegate to active repo

  @override
  Future<AuthResult> login(String username, String password) async {
    return await _activeRepo.login(username, password);
  }

  @override
  Future<AuthResult> register(String username, String password) async {
    return await _activeRepo.register(username, password);
  }

  /// Disposes resources held by this repository.
  void dispose() {
    _authStateController.close();
    _firebaseRepo.dispose();
    _guestRepo.dispose();
  }
}
