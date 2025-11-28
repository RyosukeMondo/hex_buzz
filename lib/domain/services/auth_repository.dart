import '../models/auth_result.dart';
import '../models/user.dart';

/// Abstract interface for user authentication.
///
/// Provides methods for login, registration, logout, and auth state monitoring.
/// Implementations can use different backends (local storage, Firebase, etc.)
/// while consumers depend only on this interface for dependency injection.
abstract class AuthRepository {
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

  /// Logs out the current user.
  ///
  /// After calling this method, [getCurrentUser] should return null
  /// and [authStateChanges] should emit null.
  Future<void> logout();

  /// Gets the currently authenticated user, if any.
  ///
  /// Returns null if no user is logged in.
  Future<User?> getCurrentUser();

  /// A stream that emits the current user whenever auth state changes.
  ///
  /// Emits the current user when a user logs in or registers,
  /// and emits null when the user logs out.
  Stream<User?> authStateChanges();

  /// Creates a guest user for local-only play.
  ///
  /// Guest users can play the game but their progress is only stored locally
  /// and not associated with a registered account.
  Future<AuthResult> loginAsGuest();
}
