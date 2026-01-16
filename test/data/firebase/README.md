# Firebase Repository Integration Tests

This directory contains integration tests for Firebase repository implementations using mocked Firebase services.

## Overview

These tests verify the functionality of:
- **FirebaseAuthRepository**: Google OAuth authentication, user profile synchronization, and session management
- **FirebaseLeaderboardRepository**: Leaderboard operations, score submissions, and real-time updates
- **FirebaseDailyChallengeRepository**: Daily challenge retrieval, completion tracking, and leaderboards

## Test Strategy

The integration tests use:
- **fake_cloud_firestore**: In-memory Firestore implementation for testing Firestore operations
- **mocktail**: Mock library for Firebase Auth and Google Sign-In services
- **flutter_test**: Flutter's testing framework

This approach allows testing against real Firebase API behavior without requiring actual Firebase infrastructure or network calls.

## Running Tests

### Run All Firebase Repository Tests

```bash
flutter test test/data/firebase/
```

### Run Individual Test Suites

```bash
# Auth repository tests
flutter test test/data/firebase/firebase_auth_repository_test.dart

# Leaderboard repository tests
flutter test test/data/firebase/firebase_leaderboard_repository_test.dart

# Daily challenge repository tests
flutter test test/data/firebase/firebase_daily_challenge_repository_test.dart
```

### Run with Coverage

```bash
flutter test test/data/firebase/ --coverage
```

Coverage reports are generated in `coverage/lcov.info` and can be viewed using:

```bash
# Install lcov if not already installed
# Ubuntu/Debian: sudo apt-get install lcov
# macOS: brew install lcov

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html
```

## Test Results Summary

Current test coverage:
- **FirebaseAuthRepository**: 22 tests covering authentication, sign-out, user retrieval, and profile sync
- **FirebaseLeaderboardRepository**: 19 tests covering leaderboard queries, rankings, score submissions, and streams
- **FirebaseDailyChallengeRepository**: 16 tests covering challenge retrieval, completions, and leaderboards
- **Total**: 57 tests, all passing

## Firebase Emulator Setup (Optional)

While the current tests use mocked services, the project is configured to use Firebase Emulators for more comprehensive testing against real Firebase services.

### Prerequisites

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login
```

### Starting Emulators

```bash
# Start all emulators
firebase emulators:start

# Start specific emulators
firebase emulators:start --only auth,firestore,functions
```

### Emulator Configuration

The project is configured with the following emulator ports (see `firebase.json`):
- Auth: `localhost:9099`
- Firestore: `localhost:8080`
- Functions: `localhost:5001`
- Hosting: `localhost:5000`
- Emulator UI: `localhost:4000`

### Running Tests Against Emulators

To run tests against the Firebase Emulator Suite instead of mocks, you would need to:

1. Start the emulators: `firebase emulators:start`
2. Configure the Flutter app to connect to emulators (see environment configuration)
3. Run integration tests: `flutter test integration_test/`

## Test Coverage Requirements

According to the project guidelines (.claude/CLAUDE.md):
- Minimum 80% test coverage (90% for critical paths)
- Current Firebase repository tests meet this requirement

## CI/CD Integration

These tests are designed to run in CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Run Firebase Repository Tests
  run: flutter test test/data/firebase/ --coverage

- name: Upload Coverage
  uses: codecov/codecov-action@v3
  with:
    files: ./coverage/lcov.info
```

## Test Structure

Each test file follows this structure:

1. **Setup**: Create mock/fake instances
2. **Test Groups**: Organized by repository method
3. **Test Cases**: Cover happy paths, edge cases, and error scenarios
4. **Assertions**: Verify expected behavior and data integrity

## Key Test Scenarios

### Authentication Tests
- Successful Google Sign-In with new user creation
- Existing user updates on sign-in
- User cancellation handling
- Firebase Auth error mapping
- Sign-out functionality
- Auth state changes

### Leaderboard Tests
- Top player queries with sorting
- Pagination support
- User rank calculation
- Score submission (new and updates)
- Daily challenge leaderboards
- Real-time updates via streams

### Daily Challenge Tests
- Today's challenge retrieval
- Challenge completion submissions
- Score improvement logic
- Completion count tracking
- Leaderboard generation
- Missing data handling

## Troubleshooting

### Tests Failing Due to Missing Dependencies

```bash
flutter pub get
```

### fake_cloud_firestore Issues

The `fake_cloud_firestore` package has some limitations:
- Pagination with `startAfterDocument` may not fully match production behavior
- Some complex queries might need adjustment
- Server timestamps are simulated

### Mock Setup Issues

Ensure all fallback values are registered in `setUpAll`:

```dart
setUpAll(() {
  registerFallbackValue(FakeAuthCredential());
});
```

## Future Improvements

1. **End-to-End Tests**: Add integration_test suite for full user flows
2. **Emulator Tests**: Create tests that run against actual Firebase Emulators
3. **Performance Tests**: Add tests for query performance and optimization
4. **Load Tests**: Simulate concurrent user scenarios
5. **Security Rules Tests**: Test Firestore security rules with Firebase Emulator

## Related Documentation

- [Firebase Testing Documentation](https://firebase.google.com/docs/emulator-suite)
- [fake_cloud_firestore Package](https://pub.dev/packages/fake_cloud_firestore)
- [mocktail Package](https://pub.dev/packages/mocktail)
- Project architecture documentation: `docs/architecture.md`
- Social features specification: `.spec-workflow/specs/social-competitive-features/`
