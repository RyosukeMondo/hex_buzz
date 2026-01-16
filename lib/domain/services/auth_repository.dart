import '../models/auth_result.dart';
import '../models/user.dart';

/// Abstract interface for user authentication.
///
/// Provides methods for authentication, logout, and auth state monitoring.
/// Implementations can use different backends (Firebase, local storage, etc.)
/// while consumers depend only on this interface for dependency injection.
///
/// Primary authentication method is Google Sign-In for social/competitive features.
/// Legacy username/password and guest authentication are maintained for backward compatibility.
abstract class AuthRepository {
  /// Signs in with Google OAuth.
  ///
  /// Opens Google OAuth consent screen and authenticates the user.
  /// Returns [AuthResult.success] with the user if authentication succeeds.
  /// Returns [AuthResult.failure] with an error message if authentication fails
  /// (user cancelled, network error, etc.)
  Future<AuthResult> signInWithGoogle();

  /// Signs out the current user.
  ///
  /// After calling this method, [getCurrentUser] should return null
  /// and [authStateChanges] should emit null.
  Future<void> signOut();

  /// Gets the currently authenticated user, if any.
  ///
  /// Returns null if no user is logged in.
  Future<User?> getCurrentUser();

  /// A stream that emits the current user whenever auth state changes.
  ///
  /// Emits the current user when a user logs in,
  /// and emits null when the user logs out.
  Stream<User?> authStateChanges();

  // Legacy authentication methods (backward compatibility)

  /// Attempts to log in with the given credentials.
  ///
  /// Returns [AuthResult.success] with the user if credentials are valid.
  /// Returns [AuthResult.failure] with an error message if login fails
  /// (invalid credentials, user not found, etc.)
  Future<AuthResult> login(String username, String password);

  /// Registers a new user with the given credentials.
  ///
  /// Returns [AuthResult.success] with the newly created user if registration succeeds.
  /// Returns [AuthResult.failure] with an error message if registration fails
  /// (username taken, validation error, etc.)
  Future<AuthResult> register(String username, String password);

  /// Logs out the current user (alias for [signOut] for backward compatibility).
  ///
  /// After calling this method, [getCurrentUser] should return null
  /// and [authStateChanges] should emit null.
  Future<void> logout();

  /// Creates a guest user for local-only play.
  ///
  /// Guest users can play the game but their progress is only stored locally
  /// and not associated with a registered account.
  Future<AuthResult> loginAsGuest();
}
