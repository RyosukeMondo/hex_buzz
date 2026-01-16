import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/user.dart';

void main() {
  group('User', () {
    test('creates basic user with required fields', () {
      final user = User(
        id: 'user123',
        username: 'testuser',
        createdAt: DateTime(2026, 1, 15),
      );

      expect(user.id, 'user123');
      expect(user.username, 'testuser');
      expect(user.createdAt, DateTime(2026, 1, 15));
      expect(user.isGuest, false);
      expect(user.totalStars, 0);
      expect(user.uid, null);
      expect(user.email, null);
      expect(user.rank, null);
    });

    test('creates user with social fields', () {
      final user = User(
        id: 'user123',
        username: 'testuser',
        createdAt: DateTime(2026, 1, 15),
        uid: 'firebase-uid-123',
        email: 'test@example.com',
        displayName: 'Test User',
        photoURL: 'https://example.com/photo.jpg',
        totalStars: 150,
        rank: 42,
        lastLoginAt: DateTime(2026, 1, 17),
      );

      expect(user.uid, 'firebase-uid-123');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.photoURL, 'https://example.com/photo.jpg');
      expect(user.totalStars, 150);
      expect(user.rank, 42);
      expect(user.lastLoginAt, DateTime(2026, 1, 17));
    });

    test('creates guest user', () {
      final guest = User.guest();

      expect(guest.id, 'guest');
      expect(guest.username, 'Guest');
      expect(guest.isGuest, true);
      expect(guest.totalStars, 0);
    });

    test('copyWith creates modified copy', () {
      final user = User(
        id: 'user123',
        username: 'testuser',
        createdAt: DateTime(2026, 1, 15),
        totalStars: 100,
      );

      final updated = user.copyWith(
        totalStars: 150,
        rank: 10,
        email: 'new@example.com',
      );

      expect(updated.id, 'user123');
      expect(updated.username, 'testuser');
      expect(updated.totalStars, 150);
      expect(updated.rank, 10);
      expect(updated.email, 'new@example.com');
    });

    test('copyWith preserves unmodified fields', () {
      final user = User(
        id: 'user123',
        username: 'testuser',
        createdAt: DateTime(2026, 1, 15),
        email: 'original@example.com',
        totalStars: 100,
      );

      final updated = user.copyWith(totalStars: 200);

      expect(updated.email, 'original@example.com');
      expect(updated.totalStars, 200);
    });

    group('JSON serialization', () {
      test('toJson includes all non-null fields', () {
        final user = User(
          id: 'user123',
          username: 'testuser',
          createdAt: DateTime(2026, 1, 15),
          uid: 'firebase-uid',
          email: 'test@example.com',
          displayName: 'Test User',
          photoURL: 'https://example.com/photo.jpg',
          totalStars: 150,
          rank: 42,
          lastLoginAt: DateTime(2026, 1, 17),
        );

        final json = user.toJson();

        expect(json['id'], 'user123');
        expect(json['username'], 'testuser');
        expect(json['createdAt'], '2026-01-15T00:00:00.000');
        expect(json['isGuest'], false);
        expect(json['uid'], 'firebase-uid');
        expect(json['email'], 'test@example.com');
        expect(json['displayName'], 'Test User');
        expect(json['photoURL'], 'https://example.com/photo.jpg');
        expect(json['totalStars'], 150);
        expect(json['rank'], 42);
        expect(json['lastLoginAt'], '2026-01-17T00:00:00.000');
      });

      test('toJson excludes null optional fields', () {
        final user = User(
          id: 'user123',
          username: 'testuser',
          createdAt: DateTime(2026, 1, 15),
        );

        final json = user.toJson();

        expect(json.containsKey('uid'), false);
        expect(json.containsKey('email'), false);
        expect(json.containsKey('displayName'), false);
        expect(json.containsKey('photoURL'), false);
        expect(json.containsKey('rank'), false);
        expect(json.containsKey('lastLoginAt'), false);
        expect(json['totalStars'], 0);
      });

      test('fromJson deserializes complete user', () {
        final json = {
          'id': 'user123',
          'username': 'testuser',
          'createdAt': '2026-01-15T00:00:00.000',
          'isGuest': false,
          'uid': 'firebase-uid',
          'email': 'test@example.com',
          'displayName': 'Test User',
          'photoURL': 'https://example.com/photo.jpg',
          'totalStars': 150,
          'rank': 42,
          'lastLoginAt': '2026-01-17T00:00:00.000',
        };

        final user = User.fromJson(json);

        expect(user.id, 'user123');
        expect(user.username, 'testuser');
        expect(user.createdAt, DateTime(2026, 1, 15));
        expect(user.isGuest, false);
        expect(user.uid, 'firebase-uid');
        expect(user.email, 'test@example.com');
        expect(user.displayName, 'Test User');
        expect(user.photoURL, 'https://example.com/photo.jpg');
        expect(user.totalStars, 150);
        expect(user.rank, 42);
        expect(user.lastLoginAt, DateTime(2026, 1, 17));
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'id': 'user123',
          'username': 'testuser',
          'createdAt': '2026-01-15T00:00:00.000',
        };

        final user = User.fromJson(json);

        expect(user.id, 'user123');
        expect(user.username, 'testuser');
        expect(user.isGuest, false);
        expect(user.uid, null);
        expect(user.email, null);
        expect(user.displayName, null);
        expect(user.photoURL, null);
        expect(user.totalStars, 0);
        expect(user.rank, null);
        expect(user.lastLoginAt, null);
      });

      test('JSON round-trip preserves all data', () {
        final original = User(
          id: 'user123',
          username: 'testuser',
          createdAt: DateTime(2026, 1, 15),
          uid: 'firebase-uid',
          email: 'test@example.com',
          displayName: 'Test User',
          photoURL: 'https://example.com/photo.jpg',
          totalStars: 150,
          rank: 42,
          lastLoginAt: DateTime(2026, 1, 17),
        );

        final json = original.toJson();
        final deserialized = User.fromJson(json);

        expect(deserialized, original);
      });
    });

    group('equality', () {
      test('identical users are equal', () {
        final user1 = User(
          id: 'user123',
          username: 'testuser',
          createdAt: DateTime(2026, 1, 15),
          totalStars: 100,
        );

        final user2 = User(
          id: 'user123',
          username: 'testuser',
          createdAt: DateTime(2026, 1, 15),
          totalStars: 100,
        );

        expect(user1, user2);
        expect(user1.hashCode, user2.hashCode);
      });

      test('users with different fields are not equal', () {
        final user1 = User(
          id: 'user123',
          username: 'testuser',
          createdAt: DateTime(2026, 1, 15),
          totalStars: 100,
        );

        final user2 = User(
          id: 'user123',
          username: 'testuser',
          createdAt: DateTime(2026, 1, 15),
          totalStars: 200,
        );

        expect(user1, isNot(user2));
      });

      test('users with different social fields are not equal', () {
        final user1 = User(
          id: 'user123',
          username: 'testuser',
          createdAt: DateTime(2026, 1, 15),
          email: 'test1@example.com',
        );

        final user2 = User(
          id: 'user123',
          username: 'testuser',
          createdAt: DateTime(2026, 1, 15),
          email: 'test2@example.com',
        );

        expect(user1, isNot(user2));
      });
    });

    test('toString includes relevant info', () {
      final user = User(
        id: 'user123',
        username: 'testuser',
        createdAt: DateTime(2026, 1, 15),
        isGuest: false,
      );

      final str = user.toString();
      expect(str, contains('user123'));
      expect(str, contains('testuser'));
      expect(str, contains('false'));
    });
  });
}
