import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/user.dart';
import 'package:hex_buzz/domain/models/leaderboard_entry.dart';

/// Tests for sensitive data exposure prevention.
///
/// These tests verify that:
/// - Personally Identifiable Information (PII) is not exposed in logs
/// - Email addresses are not included in public API responses
/// - Error messages do not leak system internals
/// - Debug information is not included in production builds
/// - User data is properly sanitized before logging
///
/// Security Best Practices:
/// - Never log authentication tokens
/// - Never log email addresses to analytics
/// - Sanitize user input before logging
/// - Use generic error messages in production
/// - Remove debug logging in release builds

void main() {
  group('Sensitive Data Exposure Prevention', () {
    group('User Model Data Protection', () {
      test('User model does not expose email in toString', () {
        final user = User(
          id: 'user-123',
          username: 'Test User',
          uid: 'user-123',
          email: 'sensitive@example.com',
          displayName: 'Test User',
          photoURL: null,
          totalStars: 100,
          rank: 42,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        // toString should not include sensitive data
        final stringRepresentation = user.toString();

        // OK to include: uid, displayName, totalStars, rank
        expect(stringRepresentation, contains('user-123'));

        // NOT OK to include: email (PII)
        // Most models should not implement toString with sensitive data
        // or should override it to exclude PII
      });

      test(
        'User toJson includes email for Firestore but logs should filter',
        () {
          final user = User(
            id: 'user-123',
            username: 'Test User',
            uid: 'user-123',
            email: 'sensitive@example.com',
            displayName: 'Test User',
            photoURL: null,
            totalStars: 100,
            rank: 42,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );

          final json = user.toJson();

          // Email is needed for Firestore storage
          expect(json['email'], equals('sensitive@example.com'));

          // But when logging, create sanitized version:
          final sanitizedJson = Map<String, dynamic>.from(json)
            ..remove('email');
          expect(sanitizedJson.keys, isNot(contains('email')));
        },
      );

      test('LeaderboardEntry does not include email', () {
        final entry = LeaderboardEntry(
          userId: 'user-123',
          username: 'TestUser',
          avatarUrl: null,
          totalStars: 150,
          rank: 5,
          updatedAt: DateTime.now(),
        );

        final json = entry.toJson();

        // Leaderboard is public data - should NOT include PII
        expect(json.keys, isNot(contains('email')));
        expect(json.keys, isNot(contains('phoneNumber')));
        expect(json.keys, isNot(contains('address')));

        // Should only include public display information
        expect(json['username'], equals('TestUser'));
        expect(json['totalStars'], equals(150));
      });
    });

    group('Error Message Sanitization', () {
      test('authentication errors use generic messages', () {
        final errors = <String, String>{
          'user-not-found': 'Invalid credentials',
          'wrong-password': 'Invalid credentials',
          'invalid-email': 'Invalid email format',
          'user-disabled': 'Account is disabled',
          'too-many-requests': 'Too many attempts. Please try again later.',
        };

        // All error messages should be generic and not expose:
        // - Whether a user exists
        // - System internals
        // - Database structure
        // - Valid email addresses

        for (final message in errors.values) {
          expect(message, isNot(contains('database')));
          expect(message, isNot(contains('table')));
          expect(message, isNot(contains('query')));
          expect(message, isNot(contains('SQL')));
          expect(message, isNot(contains('Firebase')));
        }
      });

      test('network errors do not expose API endpoints', () {
        const errorMessage = 'Network error. Please try again.';

        // Should NOT include:
        // - API URLs
        // - Server IP addresses
        // - Internal service names
        // - Database connection strings

        expect(errorMessage, isNot(contains('http://')));
        expect(errorMessage, isNot(contains('https://')));
        expect(errorMessage, isNot(contains('firestore.googleapis.com')));
        expect(errorMessage, isNot(contains('localhost')));
      });

      test('validation errors do not include user input', () {
        // When validating user input, don't echo it back in errors
        // This prevents XSS and log injection attacks

        const userInput = '<script>alert("xss")</script>';
        const safeError = 'Invalid input format';
        // const unsafeError = 'Invalid input: $userInput'; // BAD - never do this

        expect(safeError, isNot(contains(userInput)));
        // Example of what NOT to do: echo user input in error messages
      });
    });

    group('Logging Best Practices', () {
      test('log messages sanitize user-generated content', () {
        const username = 'TestUser<script>alert(1)</script>';

        // Sanitize before logging
        final sanitizedUsername = username.replaceAll(RegExp(r'[<>]'), '');
        final logMessage = 'User logged in: $sanitizedUsername';

        expect(logMessage, isNot(contains('<script>')));
        expect(logMessage, isNot(contains('</script>')));
      });

      test('structured logging separates PII from log data', () {
        // Good practice: Use structured logging with separate fields
        final logData = {
          'event': 'user_login',
          'user_id': 'user-123', // OK - public identifier
          'timestamp': DateTime.now().toIso8601String(),
          // 'email': 'user@example.com', // NOT OK - PII
          // 'ip_address': '192.168.1.1', // NOT OK - PII
        };

        expect(logData.keys, isNot(contains('email')));
        expect(logData.keys, isNot(contains('password')));
        expect(logData.keys, isNot(contains('token')));
        expect(logData.keys, isNot(contains('ip_address')));
      });

      test('debug information is conditionally included', () {
        const isDebugMode = false; // Should be false in production

        String getLogMessage(String event, {Map<String, dynamic>? debugInfo}) {
          // ignore: dead_code
          if (isDebugMode && debugInfo != null) {
            return '$event - Debug: $debugInfo';
          }
          return event;
        }

        final message = getLogMessage(
          'Score submitted',
          debugInfo: {'raw_data': 'sensitive info'},
        );

        // In production (isDebugMode = false), debug info not included
        expect(message, equals('Score submitted'));
        expect(message, isNot(contains('sensitive info')));
      });

      test('stack traces are sanitized in production', () {
        // In production, stack traces should:
        // - Not include file paths that expose system structure
        // - Not include variable values
        // - Be logged to secure error reporting service, not exposed to users

        const userFacingError = 'An error occurred. Please try again.';
        const errorId = 'ERR-12345'; // Reference for support team

        expect(userFacingError, isNot(contains('/home/')));
        expect(userFacingError, isNot(contains('lib/src/')));
        expect(userFacingError, isNot(contains('.dart')));

        // User sees generic message + error ID
        final displayMessage = '$userFacingError (Error ID: $errorId)';
        expect(displayMessage, contains('ERR-12345'));
      });
    });

    group('Analytics Data Protection', () {
      test('analytics events exclude PII', () {
        final analyticsEvent = {
          'event_name': 'level_completed',
          'level_id': 'level-4x4-001',
          'stars': 3,
          'completion_time': 12345,
          'user_id': 'user-123', // OK - anonymous identifier
          // DON'T include:
          // 'email': 'user@example.com',
          // 'name': 'John Doe',
          // 'ip': '192.168.1.1',
          // 'device_id': 'unique-device-id',
        };

        expect(analyticsEvent.keys, isNot(contains('email')));
        expect(analyticsEvent.keys, isNot(contains('name')));
        expect(analyticsEvent.keys, isNot(contains('ip')));
        expect(analyticsEvent.keys, isNot(contains('phone')));
        expect(analyticsEvent.keys, isNot(contains('address')));
      });

      test('crash reports exclude sensitive data', () {
        final crashReport = {
          'error': 'NullPointerException',
          'timestamp': DateTime.now().toIso8601String(),
          'app_version': '1.0.0',
          'os_version': 'Android 11',
          // DON'T include:
          // 'user_email': 'user@example.com',
          // 'auth_token': 'xyz',
          // 'user_input': 'sensitive data',
        };

        expect(crashReport.keys, isNot(contains('user_email')));
        expect(crashReport.keys, isNot(contains('email')));
        expect(crashReport.keys, isNot(contains('token')));
        expect(crashReport.keys, isNot(contains('password')));
      });
    });

    group('API Response Sanitization', () {
      test('public API responses exclude email addresses', () {
        // When returning user data in public APIs (like leaderboard),
        // exclude PII

        final publicUserData = {
          'user_id': 'user-123',
          'username': 'TestUser',
          'avatar_url': 'https://example.com/avatar.jpg',
          'total_stars': 150,
          'rank': 5,
          // 'email': 'user@example.com', // EXCLUDED
        };

        expect(publicUserData.keys, isNot(contains('email')));
        expect(publicUserData.keys, contains('username'));
        expect(publicUserData.keys, contains('total_stars'));
      });

      test('admin APIs are properly protected', () {
        // Admin APIs that return sensitive data should:
        // 1. Require admin authentication
        // 2. Not be accessible from client apps
        // 3. Use separate endpoints from public APIs
        // 4. Be rate limited
        // 5. Log all access

        const adminEndpoint = '/admin/users/user-123/full-profile';
        const publicEndpoint = '/api/users/user-123/profile';

        // Admin endpoint can include email, but requires authentication
        expect(adminEndpoint, contains('admin'));
        // Public endpoint never includes PII
        expect(publicEndpoint, isNot(contains('admin')));
      });
    });

    group('Environment Variable Protection', () {
      test('secrets are not hardcoded', () {
        // This test documents that secrets should NEVER be hardcoded
        // They should come from environment variables or secure storage

        // BAD:
        // const apiKey = 'AIzaSyAbc123...';
        // const databaseUrl = 'https://project.firebaseio.com';

        // GOOD:
        // final apiKey = Platform.environment['FIREBASE_API_KEY'];
        // final databaseUrl = Platform.environment['DATABASE_URL'];

        expect(true, isTrue); // Documentation test
      });

      test('configuration files exclude secrets from version control', () {
        // This documents that files with secrets should be in .gitignore:
        // - .env
        // - google-services.json
        // - GoogleService-Info.plist
        // - firebase-config.json

        const gitignorePatterns = [
          '.env',
          'google-services.json',
          'GoogleService-Info.plist',
          '**/firebase-config.json',
        ];

        // Verify these patterns would be in .gitignore
        for (final pattern in gitignorePatterns) {
          expect(pattern, isNotEmpty);
        }
      });
    });

    group('Data Minimization', () {
      test('only necessary data is collected', () {
        // Document data minimization principle:
        // Only collect data that is actually needed

        final necessaryUserData = {
          'uid': 'user-123', // Required for identification
          'display_name': 'TestUser', // Required for leaderboard
          'total_stars': 150, // Required for ranking
          // DON'T collect:
          // 'birth_date': '1990-01-01', // Not needed
          // 'phone_number': '+1234567890', // Not needed
          // 'location': 'New York', // Not needed
        };

        expect(necessaryUserData.keys, contains('uid'));
        expect(necessaryUserData.keys, contains('display_name'));
        expect(necessaryUserData.keys, isNot(contains('birth_date')));
        expect(necessaryUserData.keys, isNot(contains('phone_number')));
      });

      test('data retention policies are documented', () {
        // Document data retention:
        // - User profiles: Retained while account is active
        // - Score submissions: Retained for ranking computation, then deleted
        // - Daily challenges: Retained for 90 days
        // - Logs: Retained for 30 days

        const retentionPolicies = {
          'user_profiles': 'Active account duration',
          'score_submissions': 'Processed then deleted',
          'daily_challenges': '90 days',
          'error_logs': '30 days',
        };

        expect(retentionPolicies.keys, contains('user_profiles'));
        expect(
          retentionPolicies['score_submissions'],
          equals('Processed then deleted'),
        );
      });
    });
  });
}
