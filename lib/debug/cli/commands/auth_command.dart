import '../../../domain/models/auth_result.dart';
import '../../../domain/services/auth_repository.dart';
import '../cli_runner.dart';

/// CLI command for authentication operations.
///
/// Provides subcommands for login, logout, and viewing current user.
/// All output is JSON formatted for AI agent parsing.
class AuthCommand extends JsonCommand {
  final AuthRepository authRepository;

  @override
  final String name = 'auth';

  @override
  final String description = 'Manage authentication';

  AuthCommand(this.authRepository) {
    addSubcommand(_LoginCommand(authRepository));
    addSubcommand(_LogoutCommand(authRepository));
    addSubcommand(_WhoAmICommand(authRepository));
  }

  @override
  Future<Map<String, dynamic>> execute() async {
    // This is called when no subcommand is provided
    throw ArgumentError('A subcommand is required: login, logout, or whoami');
  }
}

/// Signs in with Google using an ID token.
class _LoginCommand extends JsonCommand {
  final AuthRepository authRepository;

  @override
  final String name = 'login';

  @override
  final String description = 'Sign in with Google';

  _LoginCommand(this.authRepository) {
    argParser.addOption(
      'token',
      abbr: 't',
      help: 'Google ID token for authentication',
      mandatory: true,
    );
  }

  @override
  Future<Map<String, dynamic>> execute() async {
    try {
      // Note: In a real implementation, you would need to handle custom token
      // authentication or use Firebase Admin SDK to create custom tokens.
      // For testing purposes, this performs standard Google Sign-In.
      final result = await authRepository.signInWithGoogle();

      return switch (result) {
        AuthSuccess(:final user) => {
          'success': true,
          'user': {
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
            'totalStars': user.totalStars,
            'rank': user.rank,
          },
          'message': 'Successfully signed in',
        },
        AuthFailure(:final error) => {
          'success': false,
          'error': error,
          'message': 'Sign in failed',
        },
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Unexpected error during sign in',
      };
    }
  }
}

/// Signs out the current user.
class _LogoutCommand extends JsonCommand {
  final AuthRepository authRepository;

  @override
  final String name = 'logout';

  @override
  final String description = 'Sign out current user';

  _LogoutCommand(this.authRepository);

  @override
  Future<Map<String, dynamic>> execute() async {
    try {
      await authRepository.signOut();
      return {'success': true, 'message': 'Successfully signed out'};
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to sign out',
      };
    }
  }
}

/// Gets information about the currently authenticated user.
class _WhoAmICommand extends JsonCommand {
  final AuthRepository authRepository;

  @override
  final String name = 'whoami';

  @override
  final String description = 'Get current user information';

  _WhoAmICommand(this.authRepository);

  @override
  Future<Map<String, dynamic>> execute() async {
    try {
      final user = await authRepository.getCurrentUser();

      if (user == null) {
        return {
          'success': true,
          'authenticated': false,
          'message': 'No user is currently signed in',
        };
      }

      return {
        'success': true,
        'authenticated': true,
        'user': {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'totalStars': user.totalStars,
          'rank': user.rank,
          'createdAt': user.createdAt.toIso8601String(),
          'lastLoginAt': user.lastLoginAt?.toIso8601String(),
        },
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to get current user',
      };
    }
  }
}
