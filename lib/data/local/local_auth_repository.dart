import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/auth_result.dart';
import '../../domain/models/user.dart';
import '../../domain/services/auth_repository.dart';

/// Local implementation of [AuthRepository] using SharedPreferences.
///
/// Stores user credentials and data locally on the device.
/// Passwords are hashed with SHA-256 and a random salt for security.
/// Supports guest user mode for local-only play without registration.
class LocalAuthRepository implements AuthRepository {
  static const String _usersKey = 'auth_users';
  static const String _currentUserKey = 'auth_current_user';
  static const int _saltLength = 32;

  final SharedPreferences _prefs;
  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  LocalAuthRepository(this._prefs);

  @override
  Future<AuthResult> login(String username, String password) async {
    final users = _loadUsers();
    final storedUser = users[username.toLowerCase()];

    if (storedUser == null) {
      return const AuthResult.failure('User not found');
    }

    final salt = storedUser['salt'] as String;
    final storedHash = storedUser['passwordHash'] as String;
    final inputHash = _hashPassword(password, salt);

    if (inputHash != storedHash) {
      return const AuthResult.failure('Invalid password');
    }

    final user = User.fromJson(storedUser['user'] as Map<String, dynamic>);
    await _setCurrentUser(user);

    return AuthResult.success(user);
  }

  @override
  Future<AuthResult> register(String username, String password) async {
    if (username.length < 3) {
      return const AuthResult.failure('Username must be at least 3 characters');
    }

    if (password.length < 6) {
      return const AuthResult.failure('Password must be at least 6 characters');
    }

    final users = _loadUsers();
    final normalizedUsername = username.toLowerCase();

    if (users.containsKey(normalizedUsername)) {
      return const AuthResult.failure('Username already taken');
    }

    final salt = _generateSalt();
    final passwordHash = _hashPassword(password, salt);

    final user = User(
      id: _generateUserId(),
      username: username,
      createdAt: DateTime.now(),
      isGuest: false,
    );

    users[normalizedUsername] = {
      'user': user.toJson(),
      'salt': salt,
      'passwordHash': passwordHash,
    };

    await _saveUsers(users);
    await _setCurrentUser(user);

    return AuthResult.success(user);
  }

  @override
  Future<void> logout() async {
    await _prefs.remove(_currentUserKey);
    _authStateController.add(null);
  }

  @override
  Future<User?> getCurrentUser() async {
    final userJson = _prefs.getString(_currentUserKey);
    if (userJson == null) {
      return null;
    }

    try {
      final json = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(json);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Stream<User?> authStateChanges() => _authStateController.stream;

  @override
  Future<AuthResult> loginAsGuest() async {
    final user = User.guest();
    await _setCurrentUser(user);
    return AuthResult.success(user);
  }

  Map<String, dynamic> _loadUsers() {
    final usersJson = _prefs.getString(_usersKey);
    if (usersJson == null) {
      return {};
    }

    try {
      return Map<String, dynamic>.from(
        jsonDecode(usersJson) as Map<String, dynamic>,
      );
    } on FormatException {
      return {};
    } on TypeError {
      return {};
    }
  }

  Future<void> _saveUsers(Map<String, dynamic> users) async {
    await _prefs.setString(_usersKey, jsonEncode(users));
  }

  Future<void> _setCurrentUser(User user) async {
    await _prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
    _authStateController.add(user);
  }

  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(
      _saltLength,
      (_) => random.nextInt(256),
    );
    return base64Encode(saltBytes);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt$password');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateUserId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// Disposes resources held by this repository.
  void dispose() {
    _authStateController.close();
  }
}
