# Track 1: Logging Infrastructure Overhaul

**Status:** ready
**Priority:** high
**Parent Spec:** `../spec.md`
**Effort:** Small (2-4 hours)
**Risk:** Low

## Objective

Replace all debug `print()` statements with structured logging using `DiagnosticLogger` for enhanced debuggability and production observability.

## Problem Statement

10 files contain debug `print()` statements that:
- Don't follow structured logging format
- Can't be filtered by log level
- Don't capture context (timestamps, correlation IDs)
- Don't integrate with production monitoring
- Are difficult to disable in production

## Files to Modify

Based on codebase analysis, files with `print()` statements:

1. `lib/data/firebase/firebase_auth_repository.dart`
2. `lib/data/hybrid_auth_repository.dart`
3. `lib/presentation/providers/auth_provider.dart`
4. `lib/presentation/providers/game_provider.dart`
5. `lib/presentation/providers/daily_challenge_provider.dart`
6. `lib/presentation/providers/leaderboard_provider.dart`
7. `lib/debug/api/server.dart`
8. `lib/debug/cli/cli_runner.dart`
9. `lib/main.dart`
10. Additional files discovered during grep

## Implementation Tasks

### Task 1: Audit Print Statements
```bash
grep -r "print(" lib/ --include="*.dart" > print_audit.txt
```

### Task 2: Import DiagnosticLogger
For each file:
```dart
import 'package:hex_buzz/core/logging/diagnostic_logger.dart';
```

### Task 3: Replace Print Statements

**Pattern 1: Simple Messages**
```dart
// ❌ Before
print('Starting authentication');

// ✅ After
DiagnosticLogger.logEvent('authentication_started', level: LogLevel.info);
```

**Pattern 2: Variable Interpolation**
```dart
// ❌ Before
print('User logged in: $userId');

// ✅ After
DiagnosticLogger.logEvent(
  'user_logged_in',
  data: {'userId': userId},
  level: LogLevel.info,
);
```

**Pattern 3: Error Logging**
```dart
// ❌ Before
print('Error: $error');

// ✅ After
DiagnosticLogger.logError(
  'operation_failed',
  error: error,
  stackTrace: stackTrace,
  data: {'context': 'authentication'},
);
```

**Pattern 4: Debug-Only Logging**
```dart
// ❌ Before
if (kDebugMode) {
  print('Debug info: $info');
}

// ✅ After
DiagnosticLogger.logEvent(
  'debug_info',
  data: {'info': info},
  level: LogLevel.debug,
);
```

### Task 4: Add Context to Log Events

Enhance logging with context:
```dart
DiagnosticLogger.logEvent(
  'game_move_attempted',
  data: {
    'userId': userId,
    'levelId': levelId,
    'position': position.toString(),
    'isValid': isValid,
    'timestamp': DateTime.now().toIso8601String(),
  },
  level: LogLevel.info,
);
```

### Task 5: Configure Log Levels

Ensure log levels are properly configured:
- `LogLevel.debug`: Development/diagnostic info
- `LogLevel.info`: Normal operational events
- `LogLevel.warning`: Unusual but handled situations
- `LogLevel.error`: Error conditions requiring attention

### Task 6: Verify DiagnosticLogger Implementation

Check if `DiagnosticLogger` exists and has the required API:
```dart
class DiagnosticLogger {
  static void logEvent(
    String event,
    {Map<String, dynamic>? data,
    LogLevel level = LogLevel.info}
  );

  static void logError(
    String event,
    {required Object error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data}
  );
}
```

If not implemented, create it first.

### Task 7: Add Tests

For each modified file, verify logging:
```dart
test('logs authentication events', () {
  // Setup logger mock
  final mockLogger = MockDiagnosticLogger();

  // Execute operation
  repository.signIn();

  // Verify logging
  verify(() => mockLogger.logEvent(
    'authentication_started',
    level: LogLevel.info,
  )).called(1);
});
```

## Specific File Changes

### 1. `lib/data/firebase/firebase_auth_repository.dart`
Replace Firebase auth print statements with structured logging for:
- Sign-in attempts
- Sign-in success/failure
- Sign-out events
- Token refresh events

### 2. `lib/data/hybrid_auth_repository.dart`
Replace auth delegation print statements with structured logging for:
- Repository selection logic
- Fallback scenarios
- Migration triggers

### 3. `lib/presentation/providers/auth_provider.dart`
Replace state change print statements with structured logging for:
- Auth state changes
- User info updates
- Sign-in/out user actions

### 4. `lib/presentation/providers/game_provider.dart`
Replace game state print statements with structured logging for:
- Game initialization
- Move attempts
- Level completion
- Score calculations

### 5. `lib/presentation/providers/daily_challenge_provider.dart`
Replace daily challenge print statements with structured logging for:
- Challenge loading
- Challenge completion
- Leaderboard submission

### 6. `lib/presentation/providers/leaderboard_provider.dart`
Replace leaderboard print statements with structured logging for:
- Leaderboard fetching
- Rank calculations
- Update events

### 7. `lib/debug/api/server.dart`
Replace HTTP server print statements with structured logging for:
- Server startup
- Request handling
- Errors

### 8. `lib/debug/cli/cli_runner.dart`
Replace CLI print statements with structured logging for:
- Command execution
- CLI errors

**Note:** CLI output to user should remain as `stdout.writeln()`, only internal diagnostics should use logger.

### 9. `lib/main.dart`
Replace main app print statements with structured logging for:
- App initialization
- Firebase configuration
- Window configuration (Windows)

## Success Criteria

- [ ] Zero `print(` statements in `lib/` directory (excluding user-facing output)
- [ ] All logging uses `DiagnosticLogger` API
- [ ] All log events have meaningful event names (snake_case)
- [ ] All log events include relevant context data
- [ ] All log events have appropriate log levels
- [ ] All modified code has corresponding test coverage
- [ ] Existing tests still pass

## Testing Strategy

### Unit Tests
```dart
// Test logging behavior
test('logs error when authentication fails', () {
  final logs = <LogEvent>[];
  DiagnosticLogger.configure(sink: logs.add);

  expect(
    () => repository.signInWithInvalidCredentials(),
    throwsA(isA<AuthException>()),
  );

  expect(logs, contains(
    predicate<LogEvent>((e) =>
      e.event == 'authentication_failed' &&
      e.level == LogLevel.error
    ),
  ));
});
```

### Integration Tests
```dart
// Verify logs appear in integration test flows
integration_test('daily challenge flow logs events', () {
  await tester.pumpWidget(MyApp());

  // Trigger daily challenge flow
  await tester.tap(find.text('Daily Challenge'));
  await tester.pumpAndSettle();

  // Verify logging
  expect(DiagnosticLogger.events, contains(
    predicate((e) => e.event == 'daily_challenge_loaded'),
  ));
});
```

## Rollback Plan

If structured logging causes issues:
1. Revert commit
2. Investigate DiagnosticLogger implementation
3. Fix issues
4. Reapply changes

## Dependencies

- `DiagnosticLogger` implementation (create if doesn't exist)
- `LogLevel` enum (create if doesn't exist)
- Test infrastructure for logging verification

## Completion Checklist

- [ ] Task 1: Print statement audit completed
- [ ] Task 2: DiagnosticLogger imported in all files
- [ ] Task 3: All print statements replaced
- [ ] Task 4: Context data added to all log events
- [ ] Task 5: Log levels configured appropriately
- [ ] Task 6: DiagnosticLogger implementation verified/created
- [ ] Task 7: Tests added for logging behavior
- [ ] All existing tests pass
- [ ] Code review completed
- [ ] Documentation updated

## Estimated Timeline

- Audit: 30 minutes
- DiagnosticLogger implementation (if needed): 1 hour
- Replace print statements: 1-2 hours
- Add tests: 1 hour
- Review and fixes: 30 minutes

**Total: 2-4 hours**
