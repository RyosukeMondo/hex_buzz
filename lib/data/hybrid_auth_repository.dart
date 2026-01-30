import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/logging/diagnostic_logger.dart';
import '../core/logging/logger.dart';
import '../domain/models/auth_result.dart';
import '../domain/models/user.dart' as domain;
import '../domain/services/auth_repository.dart';
import '../domain/services/leaderboard_repository.dart';
import '../domain/services/progress_repository.dart';
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
  final ProgressRepository? _localProgress;
  final ProgressRepository? _firestoreProgress;
  final LeaderboardRepository? _leaderboard;
  final StreamController<domain.User?> _authStateController =
      StreamController<domain.User?>.broadcast();

  AuthRepository _activeRepo;
  domain.User? _currentUser;
  bool _initialized = false;

  HybridAuthRepository({
    required FirebaseAuthRepository firebaseRepo,
    required LocalGuestAuthRepository guestRepo,
    ProgressRepository? localProgress,
    ProgressRepository? firestoreProgress,
    LeaderboardRepository? leaderboard,
  }) : _firebaseRepo = firebaseRepo,
       _guestRepo = guestRepo,
       _localProgress = localProgress,
       _firestoreProgress = firestoreProgress,
       _leaderboard = leaderboard,
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
    DiagnosticLogger.logEvent(
      'hybrid_auth_initialization_started',
      level: LogLevel.debug,
    );

    // Check Firebase first (higher priority)
    final firebaseUser = await _firebaseRepo.getCurrentUser();
    if (firebaseUser != null) {
      DiagnosticLogger.logEvent(
        'firebase_user_found',
        data: {
          'userId': firebaseUser.id,
          'email': firebaseUser.email,
          'isGuest': false,
        },
        level: LogLevel.info,
      );
      _activeRepo = _firebaseRepo;
      _currentUser = firebaseUser;
      _authStateController.add(firebaseUser);
      return;
    }

    DiagnosticLogger.logEvent('checking_guest_auth', level: LogLevel.debug);

    // Check guest auth
    final guestUser = await _guestRepo.getCurrentUser();
    if (guestUser != null) {
      DiagnosticLogger.logEvent(
        'guest_user_found',
        data: {
          'userId': guestUser.id,
          'username': guestUser.username,
          'isGuest': true,
        },
        level: LogLevel.info,
      );
      _activeRepo = _guestRepo;
      _currentUser = guestUser;
      _authStateController.add(guestUser);
    } else {
      DiagnosticLogger.logEvent('no_user_found', level: LogLevel.info);
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
    DiagnosticLogger.logEvent(
      'hybrid_auth_get_current_user',
      data: {'initialized': _initialized},
      level: LogLevel.debug,
    );
    // Initialize on first call
    if (!_initialized) {
      DiagnosticLogger.logEvent(
        'hybrid_auth_first_call_initializing',
        level: LogLevel.debug,
      );
      await _initializeAuthState();
      _initialized = true;
      DiagnosticLogger.logEvent(
        'hybrid_auth_initialization_complete',
        level: LogLevel.info,
      );
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
  /// Copies local progress data to Firestore and submits scores to the leaderboard.
  /// This process is fault-tolerant - if migration fails, the local data is preserved
  /// and the user can still use their Firebase account.
  Future<void> _migrateGuestDataToFirebase(
    domain.User guestUser,
    domain.User firebaseUser,
  ) async {
    // Skip migration if repositories not provided
    if (_localProgress == null || _firestoreProgress == null) {
      DiagnosticLogger.logEvent(
        'migration_skipped_no_repositories',
        data: {'guestId': guestUser.id, 'firebaseId': firebaseUser.id},
        level: LogLevel.warn,
      );
      await _guestRepo.signOut();
      return;
    }

    try {
      DiagnosticLogger.logEvent(
        'migration_started',
        data: {'guestId': guestUser.id, 'firebaseId': firebaseUser.id},
        level: LogLevel.info,
      );

      // Load local guest progress
      final guestUserId = guestUser.isGuest ? 'guest' : guestUser.id;
      final localProgress = await _localProgress!.loadForUser(guestUserId);

      if (localProgress.levels.isEmpty) {
        DiagnosticLogger.logEvent(
          'migration_no_data',
          data: {'userId': guestUserId},
          level: LogLevel.info,
        );
        await _guestRepo.signOut();
        return;
      }

      DiagnosticLogger.logEvent(
        'migration_progress_loaded',
        data: {
          'userId': guestUserId,
          'levelsCount': localProgress.levels.length,
          'totalStars': localProgress.totalStars,
        },
        level: LogLevel.info,
      );

      // Migrate progress to Firestore
      await _firestoreProgress!.saveForUser(firebaseUser.id, localProgress);

      DiagnosticLogger.logEvent(
        'migration_progress_saved',
        data: {
          'firebaseId': firebaseUser.id,
          'levelsCount': localProgress.levels.length,
        },
        level: LogLevel.info,
      );

      // Submit total score to leaderboard if available
      if (_leaderboard != null && localProgress.totalStars > 0) {
        final submitted = await _leaderboard!.submitScore(
          userId: firebaseUser.id,
          stars: localProgress.totalStars,
        );

        DiagnosticLogger.logEvent(
          'migration_leaderboard_submitted',
          data: {
            'firebaseId': firebaseUser.id,
            'stars': localProgress.totalStars,
            'success': submitted,
          },
          level: submitted ? LogLevel.info : LogLevel.warn,
        );
      }

      // Clear local guest data after successful migration
      await _localProgress!.resetForUser(guestUserId);

      DiagnosticLogger.logEvent(
        'migration_completed',
        data: {
          'guestId': guestUser.id,
          'firebaseId': firebaseUser.id,
          'levelsMigrated': localProgress.levels.length,
          'totalStars': localProgress.totalStars,
        },
        level: LogLevel.info,
      );
    } catch (error, stackTrace) {
      DiagnosticLogger.logEvent(
        'migration_failed',
        data: {
          'guestId': guestUser.id,
          'firebaseId': firebaseUser.id,
          'error': error.toString(),
        },
        level: LogLevel.error,
      );

      final logger = LoggerFactory.create('hybrid_auth');
      logger.error('migration_failed', {
        'guestId': guestUser.id,
        'firebaseId': firebaseUser.id,
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
      });

      // Don't throw - allow user to continue even if migration fails
      // Local data remains as backup
    } finally {
      // Always clean up guest session
      await _guestRepo.signOut();
    }
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
