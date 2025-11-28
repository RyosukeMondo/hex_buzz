import 'user.dart';

/// Represents the result of an authentication operation.
///
/// Contains success status, the authenticated user (if successful),
/// and an error message (if unsuccessful).
class AuthResult {
  final bool success;
  final User? user;
  final String? errorMessage;

  const AuthResult({required this.success, this.user, this.errorMessage});

  /// Creates a successful authentication result.
  const AuthResult.success(User this.user)
    : success = true,
      errorMessage = null;

  /// Creates a failed authentication result with an error message.
  const AuthResult.failure(String this.errorMessage)
    : success = false,
      user = null;

  /// Creates a copy with optional updated fields.
  AuthResult copyWith({
    bool? success,
    User? user,
    String? errorMessage,
    bool clearUser = false,
    bool clearErrorMessage = false,
  }) {
    return AuthResult(
      success: success ?? this.success,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  /// Serializes the auth result to JSON.
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (user != null) 'user': user!.toJson(),
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  /// Creates an AuthResult from JSON data.
  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      success: json['success'] as bool,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthResult &&
        other.success == success &&
        other.user == user &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(success, user, errorMessage);

  @override
  String toString() {
    if (success) {
      return 'AuthResult.success(user: $user)';
    }
    return 'AuthResult.failure(errorMessage: $errorMessage)';
  }
}
