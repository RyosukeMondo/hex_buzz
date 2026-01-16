import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/auth_result.dart';
import 'package:hex_buzz/domain/models/user.dart';

void main() {
  group('AuthResult', () {
    late User testUser;

    setUp(() {
      testUser = User(
        id: 'user123',
        username: 'testuser',
        createdAt: DateTime(2025, 1, 1),
        isGuest: false,
        uid: 'firebase-uid-123',
        email: 'test@example.com',
        displayName: 'Test User',
        photoURL: 'https://example.com/photo.jpg',
        totalStars: 100,
        rank: 5,
        lastLoginAt: DateTime(2025, 1, 17),
      );
    });

    group('AuthSuccess', () {
      test('creates instance with user', () {
        final success = AuthSuccess(testUser);

        expect(success.user, equals(testUser));
      });

      test('toJson includes success flag and user data', () {
        final success = AuthSuccess(testUser);
        final json = success.toJson();

        expect(json['success'], isTrue);
        expect(json['user'], isNotNull);
        expect(json['user']['id'], equals('user123'));
        expect(json['user']['username'], equals('testuser'));
      });

      test('equality works correctly', () {
        final success1 = AuthSuccess(testUser);
        final success2 = AuthSuccess(testUser);
        final differentUser = testUser.copyWith(id: 'different-id');
        final success3 = AuthSuccess(differentUser);

        expect(success1, equals(success2));
        expect(success1, isNot(equals(success3)));
      });

      test('hashCode is consistent', () {
        final success1 = AuthSuccess(testUser);
        final success2 = AuthSuccess(testUser);

        expect(success1.hashCode, equals(success2.hashCode));
      });

      test('toString includes user info', () {
        final success = AuthSuccess(testUser);
        final str = success.toString();

        expect(str, contains('AuthSuccess'));
        expect(str, contains('user:'));
      });
    });

    group('AuthFailure', () {
      test('creates instance with error message', () {
        final failure = AuthFailure('Invalid credentials');

        expect(failure.error, equals('Invalid credentials'));
      });

      test('toJson includes success flag and error message', () {
        final failure = AuthFailure('User not found');
        final json = failure.toJson();

        expect(json['success'], isFalse);
        expect(json['errorMessage'], equals('User not found'));
      });

      test('equality works correctly', () {
        final failure1 = AuthFailure('Error 1');
        final failure2 = AuthFailure('Error 1');
        final failure3 = AuthFailure('Error 2');

        expect(failure1, equals(failure2));
        expect(failure1, isNot(equals(failure3)));
      });

      test('hashCode is consistent', () {
        final failure1 = AuthFailure('Error');
        final failure2 = AuthFailure('Error');

        expect(failure1.hashCode, equals(failure2.hashCode));
      });

      test('toString includes error message', () {
        final failure = AuthFailure('Network error');
        final str = failure.toString();

        expect(str, contains('AuthFailure'));
        expect(str, contains('error:'));
        expect(str, contains('Network error'));
      });
    });

    group('JSON serialization', () {
      test('AuthSuccess round-trip serialization', () {
        final success = AuthSuccess(testUser);
        final json = success.toJson();
        final deserialized = AuthResult.fromJson(json);

        expect(deserialized, isA<AuthSuccess>());
        expect((deserialized as AuthSuccess).user.id, equals(testUser.id));
        expect(deserialized.user.username, equals(testUser.username));
      });

      test('AuthFailure round-trip serialization', () {
        final failure = AuthFailure('Test error');
        final json = failure.toJson();
        final deserialized = AuthResult.fromJson(json);

        expect(deserialized, isA<AuthFailure>());
        expect((deserialized as AuthFailure).error, equals('Test error'));
      });

      test('fromJson creates AuthSuccess when success is true', () {
        final json = {'success': true, 'user': testUser.toJson()};

        final result = AuthResult.fromJson(json);

        expect(result, isA<AuthSuccess>());
        expect((result as AuthSuccess).user.id, equals(testUser.id));
      });

      test('fromJson creates AuthFailure when success is false', () {
        final json = {
          'success': false,
          'errorMessage': 'Authentication failed',
        };

        final result = AuthResult.fromJson(json);

        expect(result, isA<AuthFailure>());
        expect((result as AuthFailure).error, equals('Authentication failed'));
      });
    });

    group('Pattern matching', () {
      test('can pattern match on AuthSuccess', () {
        final AuthResult result = AuthSuccess(testUser);
        String message = '';

        switch (result) {
          case AuthSuccess(:final user):
            message = 'Success: ${user.username}';
          case AuthFailure(:final error):
            message = 'Failure: $error';
        }

        expect(message, equals('Success: testuser'));
      });

      test('can pattern match on AuthFailure', () {
        final AuthResult result = AuthFailure('Network error');
        String message = '';

        switch (result) {
          case AuthSuccess(:final user):
            message = 'Success: ${user.username}';
          case AuthFailure(:final error):
            message = 'Failure: $error';
        }

        expect(message, equals('Failure: Network error'));
      });

      test('pattern matching is exhaustive', () {
        // This test verifies that the compiler enforces exhaustive checking
        // If AuthResult is properly sealed, removing a case would cause a compile error
        final AuthResult result = AuthSuccess(testUser);

        final handled = switch (result) {
          AuthSuccess() => 'success',
          AuthFailure() => 'failure',
        };

        expect(handled, isNotNull);
      });
    });
  });
}
