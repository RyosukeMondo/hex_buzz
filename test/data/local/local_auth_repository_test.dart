import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/data/local/local_auth_repository.dart';
import 'package:hex_buzz/domain/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalAuthRepository', () {
    late SharedPreferences prefs;
    late LocalAuthRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = LocalAuthRepository(prefs);
    });

    tearDown(() {
      repository.dispose();
    });

    group('register', () {
      test('registers a new user successfully', () async {
        final result = await repository.register('testuser', 'password123');

        expect(result.success, isTrue);
        expect(result.user, isNotNull);
        expect(result.user!.username, 'testuser');
        expect(result.user!.isGuest, isFalse);
        expect(result.errorMessage, isNull);
      });

      test('sets current user after successful registration', () async {
        await repository.register('testuser', 'password123');

        final currentUser = await repository.getCurrentUser();

        expect(currentUser, isNotNull);
        expect(currentUser!.username, 'testuser');
      });

      test('emits user on auth state stream after registration', () async {
        User? emittedUser;
        final subscription = repository.authStateChanges().listen((user) {
          emittedUser = user;
        });

        await repository.register('testuser', 'password123');
        await Future.delayed(Duration.zero); // Let event propagate

        expect(emittedUser, isNotNull);
        expect(emittedUser!.username, 'testuser');

        await subscription.cancel();
      });

      test('fails when username already taken', () async {
        await repository.register('existinguser', 'password123');

        final result = await repository.register('existinguser', 'newpassword');

        expect(result.success, isFalse);
        expect(result.errorMessage, 'Username already taken');
        expect(result.user, isNull);
      });

      test('usernames are case-insensitive for uniqueness', () async {
        await repository.register('TestUser', 'password123');

        final result = await repository.register('testuser', 'password456');

        expect(result.success, isFalse);
        expect(result.errorMessage, 'Username already taken');
      });

      test('fails when username is too short', () async {
        final result = await repository.register('ab', 'password123');

        expect(result.success, isFalse);
        expect(result.errorMessage, 'Username must be at least 3 characters');
      });

      test('fails when password is too short', () async {
        final result = await repository.register('testuser', '12345');

        expect(result.success, isFalse);
        expect(result.errorMessage, 'Password must be at least 6 characters');
      });

      test('creates user with unique ID', () async {
        final result1 = await repository.register('user1', 'password123');
        await repository.logout();
        final result2 = await repository.register('user2', 'password456');

        expect(result1.user!.id, isNot(equals(result2.user!.id)));
      });

      test('preserves original username casing', () async {
        final result = await repository.register('TestUser', 'password123');

        expect(result.user!.username, 'TestUser');
      });
    });

    group('login', () {
      setUp(() async {
        await repository.register('testuser', 'password123');
        await repository.logout();
      });

      test('logs in existing user successfully', () async {
        final result = await repository.login('testuser', 'password123');

        expect(result.success, isTrue);
        expect(result.user, isNotNull);
        expect(result.user!.username, 'testuser');
      });

      test('sets current user after successful login', () async {
        await repository.login('testuser', 'password123');

        final currentUser = await repository.getCurrentUser();

        expect(currentUser, isNotNull);
        expect(currentUser!.username, 'testuser');
      });

      test('emits user on auth state stream after login', () async {
        User? emittedUser;
        final subscription = repository.authStateChanges().listen((user) {
          emittedUser = user;
        });

        await repository.login('testuser', 'password123');
        await Future.delayed(Duration.zero); // Let event propagate

        expect(emittedUser, isNotNull);
        expect(emittedUser!.username, 'testuser');

        await subscription.cancel();
      });

      test('fails with wrong password', () async {
        final result = await repository.login('testuser', 'wrongpassword');

        expect(result.success, isFalse);
        expect(result.errorMessage, 'Invalid password');
        expect(result.user, isNull);
      });

      test('fails when user not found', () async {
        final result = await repository.login('nonexistent', 'password123');

        expect(result.success, isFalse);
        expect(result.errorMessage, 'User not found');
      });

      test('login is case-insensitive for username', () async {
        final result = await repository.login('TESTUSER', 'password123');

        expect(result.success, isTrue);
        expect(result.user!.username, 'testuser');
      });
    });

    group('logout', () {
      setUp(() async {
        await repository.register('testuser', 'password123');
      });

      test('clears current user after logout', () async {
        await repository.logout();

        final currentUser = await repository.getCurrentUser();

        expect(currentUser, isNull);
      });

      test('emits null on auth state stream after logout', () async {
        User? emittedUser = User.guest(); // Start with non-null
        final subscription = repository.authStateChanges().listen((user) {
          emittedUser = user;
        });

        await repository.logout();
        await Future.delayed(Duration.zero); // Let event propagate

        expect(emittedUser, isNull);

        await subscription.cancel();
      });

      test('logout when not logged in does not throw', () async {
        await repository.logout();

        await expectLater(repository.logout(), completes);
      });
    });

    group('getCurrentUser', () {
      test('returns null when no user is logged in', () async {
        final user = await repository.getCurrentUser();

        expect(user, isNull);
      });

      test('returns current user after registration', () async {
        await repository.register('testuser', 'password123');

        final user = await repository.getCurrentUser();

        expect(user, isNotNull);
        expect(user!.username, 'testuser');
      });

      test('returns current user after login', () async {
        await repository.register('testuser', 'password123');
        await repository.logout();
        await repository.login('testuser', 'password123');

        final user = await repository.getCurrentUser();

        expect(user, isNotNull);
        expect(user!.username, 'testuser');
      });

      test('handles corrupted current user data gracefully', () async {
        await prefs.setString('auth_current_user', 'invalid json');

        final user = await repository.getCurrentUser();

        expect(user, isNull);
      });

      test('handles malformed current user JSON gracefully', () async {
        await prefs.setString('auth_current_user', '{"invalid": "structure"}');

        final user = await repository.getCurrentUser();

        expect(user, isNull);
      });
    });

    group('loginAsGuest', () {
      test('creates a guest user successfully', () async {
        final result = await repository.loginAsGuest();

        expect(result.success, isTrue);
        expect(result.user, isNotNull);
        expect(result.user!.isGuest, isTrue);
        expect(result.user!.username, 'Guest');
        expect(result.user!.id, 'guest');
      });

      test('sets current user after guest login', () async {
        await repository.loginAsGuest();

        final currentUser = await repository.getCurrentUser();

        expect(currentUser, isNotNull);
        expect(currentUser!.isGuest, isTrue);
      });

      test('emits guest user on auth state stream', () async {
        User? emittedUser;
        final subscription = repository.authStateChanges().listen((user) {
          emittedUser = user;
        });

        await repository.loginAsGuest();
        await Future.delayed(Duration.zero); // Let event propagate

        expect(emittedUser, isNotNull);
        expect(emittedUser!.isGuest, isTrue);

        await subscription.cancel();
      });
    });

    group('password security', () {
      test('password is not stored in plaintext', () async {
        await repository.register('testuser', 'mysecretpassword');

        final usersJson = prefs.getString('auth_users');

        expect(usersJson, isNotNull);
        expect(usersJson, isNot(contains('mysecretpassword')));
      });

      test('password hash is stored with salt', () async {
        await repository.register('testuser', 'password123');

        final usersJson = prefs.getString('auth_users');
        final users = jsonDecode(usersJson!) as Map<String, dynamic>;
        final userData = users['testuser'] as Map<String, dynamic>;

        expect(userData['salt'], isNotNull);
        expect(userData['salt'], isA<String>());
        expect((userData['salt'] as String).isNotEmpty, isTrue);
        expect(userData['passwordHash'], isNotNull);
        expect(userData['passwordHash'], isA<String>());
      });

      test(
        'same password produces different hashes due to unique salt',
        () async {
          await repository.register('user1', 'samepassword');
          await repository.logout();
          await repository.register('user2', 'samepassword');

          final usersJson = prefs.getString('auth_users');
          final users = jsonDecode(usersJson!) as Map<String, dynamic>;
          final user1Data = users['user1'] as Map<String, dynamic>;
          final user2Data = users['user2'] as Map<String, dynamic>;

          expect(
            user1Data['passwordHash'],
            isNot(equals(user2Data['passwordHash'])),
          );
        },
      );

      test('password hash is deterministic with same salt', () async {
        // Register and get the hash
        await repository.register('testuser', 'password123');
        await repository.logout();

        // Login should produce same hash comparison
        final result = await repository.login('testuser', 'password123');

        expect(result.success, isTrue);
      });
    });

    group('persistence', () {
      test('user data persists across repository instances', () async {
        await repository.register('persistuser', 'password123');
        await repository.logout();

        // Create a new repository instance
        final newRepository = LocalAuthRepository(prefs);

        final result = await newRepository.login('persistuser', 'password123');

        expect(result.success, isTrue);
        expect(result.user!.username, 'persistuser');

        newRepository.dispose();
      });

      test('current user persists across repository instances', () async {
        await repository.register('persistuser', 'password123');

        // Create a new repository instance
        final newRepository = LocalAuthRepository(prefs);

        final currentUser = await newRepository.getCurrentUser();

        expect(currentUser, isNotNull);
        expect(currentUser!.username, 'persistuser');

        newRepository.dispose();
      });

      test('handles corrupted users data gracefully', () async {
        await prefs.setString('auth_users', 'invalid json');

        final result = await repository.login('anyone', 'password123');

        expect(result.success, isFalse);
        expect(result.errorMessage, 'User not found');
      });
    });

    group('authStateChanges', () {
      test('stream is broadcast (multiple listeners)', () async {
        final stream = repository.authStateChanges();

        // Multiple listeners should work
        stream.listen((_) {});
        stream.listen((_) {});

        await repository.register('testuser', 'password123');

        // Should not throw
      });

      test('emits events in correct order', () async {
        final events = <User?>[];
        repository.authStateChanges().listen(events.add);

        await repository.register('testuser', 'password123');
        await repository.logout();
        await repository.loginAsGuest();

        await Future.delayed(Duration.zero); // Let events propagate

        expect(events.length, 3);
        expect(events[0]?.username, 'testuser');
        expect(events[1], isNull);
        expect(events[2]?.isGuest, isTrue);
      });
    });

    group('edge cases', () {
      test('handles empty username', () async {
        final result = await repository.register('', 'password123');

        expect(result.success, isFalse);
        expect(result.errorMessage, 'Username must be at least 3 characters');
      });

      test('handles empty password', () async {
        final result = await repository.register('testuser', '');

        expect(result.success, isFalse);
        expect(result.errorMessage, 'Password must be at least 6 characters');
      });

      test('handles special characters in username', () async {
        final result = await repository.register('user@name!', 'password123');

        expect(result.success, isTrue);
        expect(result.user!.username, 'user@name!');
      });

      test('handles special characters in password', () async {
        await repository.register('testuser', 'p@ss!w0rd#');
        await repository.logout();

        final result = await repository.login('testuser', 'p@ss!w0rd#');

        expect(result.success, isTrue);
      });

      test('handles unicode characters in password', () async {
        await repository.register('testuser', 'пароль123');
        await repository.logout();

        final result = await repository.login('testuser', 'пароль123');

        expect(result.success, isTrue);
      });

      test('handles very long username', () async {
        final longUsername = 'a' * 1000;

        final result = await repository.register(longUsername, 'password123');

        expect(result.success, isTrue);
        expect(result.user!.username, longUsername);
      });

      test('handles very long password', () async {
        final longPassword = 'a' * 1000;

        await repository.register('testuser', longPassword);
        await repository.logout();

        final result = await repository.login('testuser', longPassword);

        expect(result.success, isTrue);
      });
    });
  });
}
