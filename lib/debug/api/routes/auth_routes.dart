import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../domain/models/auth_result.dart';
import '../../../domain/services/auth_repository.dart';

/// REST API routes for authentication.
///
/// Provides endpoints for AI agents to interact with authentication:
/// - POST /api/auth/google - Sign in with Google (accepts ID token)
/// - POST /api/auth/logout - Sign out current user
/// - GET /api/auth/me - Get current authenticated user
///
/// Uses AuthRepository for authentication operations.
class AuthRoutes {
  final AuthRepository repository;

  AuthRoutes({required this.repository});

  /// Creates a router with all auth routes.
  Router get router {
    final router = Router();

    router.post('/google', _handleGoogleSignIn);
    router.post('/logout', _handleLogout);
    router.get('/me', _handleGetCurrentUser);

    return router;
  }

  /// POST /api/auth/google
  ///
  /// Sign in with Google OAuth.
  /// Request body: {"idToken": string} (optional, for headless auth)
  /// Response: {"success": bool, "user": User?, "error"?: string}
  Future<Response> _handleGoogleSignIn(Request request) async {
    // For API/CLI usage, we simply trigger the Google sign-in flow
    // The idToken parameter is optional for future headless authentication
    final result = await repository.signInWithGoogle();

    if (result is AuthSuccess) {
      final user = result.user;
      return _jsonResponse({
        'success': true,
        'user': {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'totalStars': user.totalStars,
          'rank': user.rank,
          'createdAt': user.createdAt.toIso8601String(),
          if (user.lastLoginAt != null)
            'lastLoginAt': user.lastLoginAt!.toIso8601String(),
        },
      });
    } else {
      final failure = result as AuthFailure;
      return _errorResponse('auth_failed', failure.error);
    }
  }

  /// POST /api/auth/logout
  ///
  /// Sign out the current user.
  /// Response: {"success": bool}
  Future<Response> _handleLogout(Request request) async {
    try {
      await repository.signOut();
      return _jsonResponse({'success': true});
    } catch (e) {
      return _errorResponse('logout_failed', e.toString());
    }
  }

  /// GET /api/auth/me
  ///
  /// Get the currently authenticated user.
  /// Response: {"user": User?} (null if not authenticated)
  Future<Response> _handleGetCurrentUser(Request request) async {
    try {
      final user = await repository.getCurrentUser();

      if (user == null) {
        return _jsonResponse({'user': null});
      }

      return _jsonResponse({
        'user': {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'totalStars': user.totalStars,
          'rank': user.rank,
          'createdAt': user.createdAt.toIso8601String(),
          if (user.lastLoginAt != null)
            'lastLoginAt': user.lastLoginAt!.toIso8601String(),
        },
      });
    } catch (e) {
      return _errorResponse('get_user_failed', e.toString());
    }
  }

  /// Creates an error response with consistent format.
  static Response _errorResponse(String error, String message) {
    return _jsonResponse({
      'success': false,
      'error': error,
      'message': message,
    }, statusCode: 400);
  }

  /// Creates a JSON response with proper content type.
  static Response _jsonResponse(
    Map<String, dynamic> data, {
    int statusCode = 200,
  }) {
    return Response(
      statusCode,
      body: jsonEncode(data),
      headers: {'content-type': 'application/json'},
    );
  }
}
