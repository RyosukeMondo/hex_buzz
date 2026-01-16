import 'user.dart';

/// Type-safe authentication result for Firebase authentication operations.
///
/// This sealed class represents the result of authentication operations,
/// providing compile-time exhaustive pattern matching for success and failure cases.
sealed class AuthResult {
  const AuthResult();

  /// Serializes the auth result to JSON.
  Map<String, dynamic> toJson();

  /// Creates an AuthResult from JSON data.
  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final success = json['success'] as bool;
    if (success) {
      return AuthSuccess(User.fromJson(json['user'] as Map<String, dynamic>));
    } else {
      return AuthFailure(json['errorMessage'] as String);
    }
  }
}

/// Successful authentication result containing the authenticated user.
final class AuthSuccess extends AuthResult {
  /// The authenticated user data.
  final User user;

  const AuthSuccess(this.user);

  @override
  Map<String, dynamic> toJson() {
    return {'success': true, 'user': user.toJson()};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthSuccess &&
          runtimeType == other.runtimeType &&
          user == other.user;

  @override
  int get hashCode => user.hashCode;

  @override
  String toString() => 'AuthSuccess(user: $user)';
}

/// Failed authentication result containing an error message.
final class AuthFailure extends AuthResult {
  /// The error message describing the authentication failure.
  final String error;

  const AuthFailure(this.error);

  @override
  Map<String, dynamic> toJson() {
    return {'success': false, 'errorMessage': error};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthFailure &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'AuthFailure(error: $error)';
}
