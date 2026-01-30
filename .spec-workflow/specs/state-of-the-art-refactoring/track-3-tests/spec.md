# Track 3: Test Coverage Enhancement

**Status:** ready
**Priority:** critical
**Parent Spec:** `../spec.md`
**Effort:** Large (8-12 hours)
**Risk:** Low

## Objective

Increase test coverage from ~75% to ≥80% overall and ≥90% for critical paths.

## Problem Statement

Current test coverage analysis:
- **Domain layer (core logic):** ~90% ✅
- **Data layer (repositories):** ~80% ✅
- **Presentation (UI):** ~70% ⚠️ (needs +10%)
- **Platform-specific:** ~60% ⚠️ (needs +20%)
- **Cloud Functions:** ~50% ⚠️ (needs +30%)

**Overall:** ~75% (needs +5% minimum)

## Coverage Gaps Analysis

### Priority 1: Critical Paths (Need 90%+)
1. **Game Engine** - Move validation logic
2. **Path Validator** - Path completion detection
3. **Star Calculator** - Score calculation
4. **Auth Flow** - Firebase + Google Sign-In
5. **Daily Challenge** - Challenge submission
6. **Leaderboard** - Score submission and ranking

### Priority 2: Presentation Layer (Need 80%+)
1. **Providers** - Missing edge cases
2. **Screens** - Widget interaction tests
3. **Complex Widgets** - Completion overlay, hover button

### Priority 3: Platform-Specific (Need 70%+)
1. **Windows** - Keyboard shortcuts
2. **Windows** - WNS notifications
3. **Windows** - Window configuration

### Priority 4: Cloud Functions (Need 70%+)
1. **Daily Challenge Generator** - Level generation
2. **Notification Sender** - FCM dispatch
3. **Diagnostics** - Test endpoints

## Implementation Tasks

### Task 1: Generate Coverage Report
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

Analyze gaps by file and identify:
- Uncovered lines
- Uncovered branches
- Uncovered functions

### Task 2: Critical Path Tests (Priority 1)

#### GameEngine Missing Coverage
```dart
group('GameEngine edge cases', () {
  test('handles invalid moves gracefully', () {
    final engine = GameEngine(level: testLevel);
    expect(() => engine.tryMove(invalidPosition), throwsA(isA<InvalidMoveException>()));
  });

  test('detects circular paths', () {
    final engine = GameEngine(level: testLevel);
    // Create circular path
    expect(engine.isPathValid(), isFalse);
  });

  test('validates checkpoint order', () {
    final engine = GameEngine(level: levelWithCheckpoints);
    // Skip checkpoint
    expect(engine.canMoveTo(afterCheckpoint), isFalse);
  });
});
```

#### PathValidator Missing Coverage
```dart
group('PathValidator edge cases', () {
  test('validates empty path', () {
    expect(PathValidator.validate([]), isFalse);
  });

  test('validates single-cell path', () {
    expect(PathValidator.validate([start]), isFalse);
  });

  test('detects disconnected paths', () {
    final path = [start, disconnected, end];
    expect(PathValidator.validate(path), isFalse);
  });
});
```

#### StarCalculator Missing Coverage
```dart
group('StarCalculator edge cases', () {
  test('handles perfect completion time', () {
    expect(StarCalculator.calculate(perfectTime, level), equals(3));
  });

  test('handles minimum completion time', () {
    expect(StarCalculator.calculate(minTime, level), equals(1));
  });

  test('handles overtime completion', () {
    expect(StarCalculator.calculate(overtime, level), equals(1));
  });
});
```

#### Auth Flow Missing Coverage
```dart
group('Auth flow edge cases', () {
  test('handles sign-in cancellation', () async {
    when(() => mockAuth.signIn()).thenAnswer((_) async => AuthResult.cancelled());
    final result = await repository.signIn();
    expect(result.isCancelled, isTrue);
  });

  test('handles network errors during sign-in', () async {
    when(() => mockAuth.signIn()).thenThrow(NetworkException());
    expect(() => repository.signIn(), throwsA(isA<NetworkException>()));
  });

  test('handles expired tokens', () async {
    when(() => mockAuth.refreshToken()).thenThrow(TokenExpiredException());
    expect(() => repository.refreshToken(), throwsA(isA<TokenExpiredException>()));
  });
});
```

### Task 3: Presentation Layer Tests (Priority 2)

#### Provider Error States
```dart
group('Auth provider error states', () {
  testWidgets('displays error message on sign-in failure', (tester) async {
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(mockRepo),
    ]);

    when(() => mockRepo.signIn()).thenThrow(AuthException('Failed'));

    await tester.pumpWidget(ProviderScope(
      parent: container,
      child: AuthScreen(),
    ));

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Failed'), findsOneWidget);
  });
});
```

#### Screen Interaction Tests
```dart
group('Game screen interactions', () {
  testWidgets('undo button disables when no moves', (tester) async {
    await tester.pumpWidget(GameScreen(level: testLevel));
    expect(tester.widget<Button>(find.byKey(undoKey)).enabled, isFalse);
  });

  testWidgets('undo button enables after move', (tester) async {
    await tester.pumpWidget(GameScreen(level: testLevel));
    await tester.tap(find.byType(HexGridWidget));
    await tester.pump();
    expect(tester.widget<Button>(find.byKey(undoKey)).enabled, isTrue);
  });
});
```

#### Widget Tests
```dart
group('Completion overlay tests', () {
  testWidgets('displays correct star count', (tester) async {
    await tester.pumpWidget(CompletionOverlay(stars: 3));
    expect(find.byIcon(Icons.star), findsNWidgets(3));
  });

  testWidgets('animates entrance', (tester) async {
    await tester.pumpWidget(CompletionOverlay(stars: 2));
    expect(find.byType(FadeTransition), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('calls onContinue callback', (tester) async {
    var called = false;
    await tester.pumpWidget(CompletionOverlay(
      stars: 3,
      onContinue: () => called = true,
    ));
    await tester.tap(find.text('Continue'));
    expect(called, isTrue);
  });
});
```

### Task 4: Platform-Specific Tests (Priority 3)

#### Windows Keyboard Shortcuts
```dart
group('Windows keyboard shortcuts', () {
  testWidgets('Ctrl+Z triggers undo', (tester) async {
    await tester.pumpWidget(WindowsKeyboardShortcuts(
      child: GameScreen(),
    ));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);

    // Verify undo was triggered
    verify(() => mockGameProvider.undo()).called(1);
  });
});
```

#### Windows Notifications
```dart
group('WNS notifications', () {
  test('formats notification correctly', () {
    final notification = WNSNotification(
      title: 'Test',
      body: 'Message',
    );

    final xml = notification.toXml();
    expect(xml, contains('<toast>'));
    expect(xml, contains('Test'));
  });

  test('handles notification failure gracefully', () async {
    when(() => mockWns.send(any())).thenThrow(WnsException());
    expect(() => service.sendNotification(notification), returnsNormally);
  });
});
```

### Task 5: Cloud Functions Tests (Priority 4)

#### Daily Challenge Generator Tests
```typescript
describe('generateDailyChallenge', () => {
  it('creates challenge for current date', async () => {
    await generateDailyChallenge();
    const challenge = await db.collection('dailyChallenges').doc(today).get();
    expect(challenge.exists).toBe(true);
  });

  it('does not overwrite existing challenge', async () => {
    await db.collection('dailyChallenges').doc(today).set({ level: existingLevel });
    await generateDailyChallenge();
    const challenge = await db.collection('dailyChallenges').doc(today).get();
    expect(challenge.data()?.level).toEqual(existingLevel);
  });

  it('handles generation errors gracefully', async () => {
    jest.spyOn(levelGenerator, 'generate').mockImplementation(() => {
      throw new Error('Generation failed');
    });

    await expect(generateDailyChallenge()).rejects.toThrow('Generation failed');
  });
});
```

#### Notification Sender Tests
```typescript
describe('sendDailyChallengeNotification', () => {
  it('sends notifications to all users', async () => {
    await db.collection('users').doc('user1').set({ fcmToken: 'token1' });
    await db.collection('users').doc('user2').set({ fcmToken: 'token2' });

    await sendDailyChallengeNotification('2026-01-30');

    expect(mockFcm.send).toHaveBeenCalledTimes(2);
  });

  it('skips users without FCM tokens', async () => {
    await db.collection('users').doc('user1').set({});
    await sendDailyChallengeNotification('2026-01-30');

    expect(mockFcm.send).not.toHaveBeenCalled();
  });

  it('handles FCM errors gracefully', async () => {
    mockFcm.send.mockRejectedValue(new Error('FCM error'));
    await expect(sendDailyChallengeNotification('2026-01-30')).resolves.not.toThrow();
  });
});
```

### Task 6: Add Missing Test Infrastructure

#### Test Utilities
```dart
// test/helpers/test_data.dart
class TestData {
  static Level createTestLevel({int size = 5}) { ... }
  static GameState createTestGameState() { ... }
  static User createTestUser() { ... }
}

// test/helpers/pump_app.dart
extension PumpApp on WidgetTester {
  Future<void> pumpApp(Widget widget) async {
    await pumpWidget(MaterialApp(home: widget));
  }
}
```

#### Mock Builders
```dart
// test/mocks/mock_builders.dart
class MockBuilder {
  static MockAuthRepository mockAuthRepository() {
    final mock = MockAuthRepository();
    when(() => mock.signIn()).thenAnswer((_) async => AuthResult.success(user));
    return mock;
  }

  static MockGameProvider mockGameProvider() {
    final mock = MockGameProvider();
    when(() => mock.state).thenReturn(testGameState);
    return mock;
  }
}
```

### Task 7: Coverage Enforcement

Add coverage checking to CI:
```yaml
# .github/workflows/test.yml
- name: Check coverage
  run: |
    flutter test --coverage
    dart pub global activate coverage
    dart pub global run coverage:format_coverage \
      --lcov --in=coverage --out=coverage/lcov.info --report-on=lib

    # Fail if coverage < 80%
    lcov --summary coverage/lcov.info | grep "lines....: 8[0-9]\|9[0-9]"
```

## Success Criteria

- [ ] Overall coverage: ≥80%
- [ ] Critical paths coverage: ≥90%
- [ ] Presentation layer coverage: ≥80%
- [ ] Platform-specific coverage: ≥70%
- [ ] Cloud Functions coverage: ≥70%
- [ ] All existing tests still pass
- [ ] Coverage gates enforced in CI/CD
- [ ] Coverage reports generated and tracked

## Testing Strategy

### Phase 1: Measure Baseline
- Generate current coverage report
- Identify gaps by file
- Prioritize based on criticality

### Phase 2: Fill Gaps
- Add tests for critical paths first
- Add tests for presentation layer
- Add tests for platform-specific code
- Add tests for cloud functions

### Phase 3: Verify
- Re-run coverage report
- Verify targets met
- Add coverage gates to CI

## Dependencies

- `coverage` package for Dart
- `jest` for TypeScript (Cloud Functions)
- `lcov` for coverage reporting
- CI/CD infrastructure

## Completion Checklist

- [ ] Task 1: Coverage report generated
- [ ] Task 2: Critical path tests added (90%+ coverage)
- [ ] Task 3: Presentation layer tests added (80%+ coverage)
- [ ] Task 4: Platform-specific tests added (70%+ coverage)
- [ ] Task 5: Cloud Functions tests added (70%+ coverage)
- [ ] Task 6: Test infrastructure enhanced
- [ ] Task 7: Coverage enforcement added to CI
- [ ] Overall coverage ≥80%
- [ ] All tests pass
- [ ] Code review completed
- [ ] Documentation updated

## Estimated Timeline

- Coverage analysis: 1 hour
- Critical path tests: 3 hours
- Presentation layer tests: 2 hours
- Platform-specific tests: 2 hours
- Cloud Functions tests: 2 hours
- Test infrastructure: 1 hour
- CI integration: 1 hour
- Review and fixes: 2 hours

**Total: 8-12 hours**
