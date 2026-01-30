# Track 6: TODO Resolution

**Status:** ready
**Priority:** medium
**Parent Spec:** `../spec.md`
**Effort:** Medium (4-6 hours)
**Risk:** Medium

## Objective

Complete all pending TODO items in the codebase: data migration logic and notification handling.

## Problem Statement

Several TODO comments indicate incomplete functionality:
1. **Guest → Firebase data migration** - Not implemented in `hybrid_auth_repository.dart`
2. **Notification navigation** - Not implemented in `main.dart`
3. **Notification UI display** - Not implemented in `main.dart`
4. **Other TODOs** - Various minor items

## Implementation Tasks

### Task 1: Audit All TODOs
```bash
grep -r "TODO" lib/ --include="*.dart" -n > todos_audit.txt
grep -r "FIXME" lib/ --include="*.dart" -n >> todos_audit.txt
grep -r "HACK" lib/ --include="*.dart" -n >> todos_audit.txt
```

Document all TODOs and categorize by priority.

### Task 2: Implement Guest → Firebase Migration

**Location:** `lib/data/hybrid_auth_repository.dart`

**Current State:**
```dart
// TODO: Implement data migration logic
// When user upgrades from guest to Firebase:
// 1. Copy local progress to Firestore
// 2. Migrate scores to leaderboard
// 3. Delete local data
```

**Implementation:**
```dart
class HybridAuthRepository implements AuthRepository {
  final FirebaseAuthRepository _firebaseRepo;
  final LocalGuestAuthRepository _localRepo;
  final LocalProgressRepository _localProgress;
  final FirestoreProgressRepository _firestoreProgress;
  final FirestoreLeaderboardRepository _leaderboard;

  // ... existing code

  Future<void> _migrateGuestData(User guestUser, User firebaseUser) async {
    try {
      Logger.info('migration_started', {
        'guestId': guestUser.id,
        'firebaseId': firebaseUser.id,
      });

      // 1. Load local progress
      final localProgress = await _localProgress.getProgress(guestUser.id);

      if (localProgress.isEmpty) {
        Logger.info('migration_no_data', {'userId': guestUser.id});
        return;
      }

      // 2. Migrate progress to Firestore
      for (final entry in localProgress.entries) {
        final levelId = entry.key;
        final progress = entry.value;

        await _firestoreProgress.saveProgress(
          firebaseUser.id,
          levelId,
          progress,
        );

        // 3. Submit scores to leaderboard if better than existing
        if (progress.stars > 0) {
          await _leaderboard.submitScore(
            userId: firebaseUser.id,
            levelId: levelId,
            stars: progress.stars,
            completionTimeMs: progress.timeMs,
          );
        }
      }

      // 4. Delete local data after successful migration
      await _localProgress.clearProgress(guestUser.id);
      await _localRepo.deleteUser(guestUser.id);

      Logger.info('migration_completed', {
        'guestId': guestUser.id,
        'firebaseId': firebaseUser.id,
        'levelsM migrated': localProgress.length,
      });

    } catch (error, stackTrace) {
      Logger.error('migration_failed', error, stackTrace, {
        'guestId': guestUser.id,
        'firebaseId': firebaseUser.id,
      });

      // Don't throw - allow user to continue even if migration fails
      // Data remains in local storage as backup
    }
  }

  @override
  Future<AuthResult> signIn() async {
    // Get current user (might be guest)
    final currentUser = _currentUser;

    // Attempt Firebase sign-in
    final result = await _firebaseRepo.signIn();

    if (result.isSuccess && currentUser?.isGuest == true) {
      // Migrate guest data to Firebase account
      await _migrateGuestData(currentUser!, result.user!);
    }

    return result;
  }
}
```

**Files to Create:**
- `lib/domain/repositories/progress_repository.dart` (interface for migration)
- `lib/data/firestore/firestore_progress_repository.dart` (Firestore implementation)

**Tests:**
```dart
// test/data/hybrid_auth_repository_test.dart
group('Guest to Firebase migration', () {
  test('migrates local progress to Firestore', () async {
    // Setup guest user with local progress
    final guestUser = User.guest(id: 'guest-123');
    await localProgress.saveProgress('guest-123', 'level-1', Progress(stars: 3));

    // Sign in with Firebase
    when(() => firebaseRepo.signIn()).thenAnswer(
      (_) async => AuthResult.success(firebaseUser),
    );

    await hybridRepo.signIn();

    // Verify migration
    verify(() => firestoreProgress.saveProgress(
      firebaseUser.id,
      'level-1',
      any(),
    )).called(1);

    verify(() => leaderboard.submitScore(
      userId: firebaseUser.id,
      levelId: 'level-1',
      stars: 3,
      completionTimeMs: any(named: 'completionTimeMs'),
    )).called(1);

    // Verify local data deleted
    final remaining = await localProgress.getProgress('guest-123');
    expect(remaining, isEmpty);
  });

  test('continues on migration failure', () async {
    when(() => firestoreProgress.saveProgress(any(), any(), any()))
        .thenThrow(Exception('Network error'));

    // Should not throw
    await hybridRepo.signIn();

    // User can still use app
    expect(hybridRepo.currentUser, isNotNull);
  });
});
```

### Task 3: Implement Notification Navigation

**Location:** `lib/main.dart`

**Current State:**
```dart
// TODO: Handle notification tap - navigate to appropriate screen
void _handleNotificationTap(RemoteMessage message) {
  // Implement navigation based on notification type
}
```

**Implementation:**
```dart
class MyApp extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupNotificationHandlers();
  }

  void _setupNotificationHandlers() {
    // Handle notification when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundNotification);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is opened from terminated state
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });
  }

  void _handleForegroundNotification(RemoteMessage message) {
    Logger.info('notification_received_foreground', {
      'type': message.data['type'],
      'title': message.notification?.title,
    });

    // Show in-app notification banner
    final context = _navigatorKey.currentContext;
    if (context != null && message.notification != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.notification!.title ?? '',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (message.notification!.body != null)
                Text(message.notification!.body!),
            ],
          ),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => _navigateFromNotification(message),
          ),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    Logger.info('notification_tapped', {
      'type': message.data['type'],
      'route': message.data['route'],
    });

    _navigateFromNotification(message);
  }

  void _navigateFromNotification(RemoteMessage message) {
    final type = message.data['type'] as String?;
    final route = message.data['route'] as String?;

    switch (type) {
      case 'daily_challenge':
        _navigatorKey.currentState?.pushNamed('/daily-challenge');
        break;

      case 'leaderboard_update':
        final rank = message.data['rank'] as String?;
        _navigatorKey.currentState?.pushNamed(
          '/leaderboard',
          arguments: {'highlightRank': rank},
        );
        break;

      case 'new_level':
        final levelId = message.data['levelId'] as String?;
        _navigatorKey.currentState?.pushNamed(
          '/game',
          arguments: {'levelId': levelId},
        );
        break;

      default:
        // Generic route from notification data
        if (route != null) {
          _navigatorKey.currentState?.pushNamed(route);
        } else {
          // Default to home screen
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      // ... rest of app config
      routes: {
        '/home': (_) => FrontScreen(),
        '/daily-challenge': (_) => DailyChallengeScreen(),
        '/leaderboard': (_) => LeaderboardScreen(),
        '/game': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          return GameScreen(levelId: args?['levelId']);
        },
      },
    );
  }
}
```

**Tests:**
```dart
// test/app/notification_navigation_test.dart
testWidgets('navigates to daily challenge on notification tap', (tester) async {
  await tester.pumpWidget(MyApp());

  final message = RemoteMessage(
    data: {
      'type': 'daily_challenge',
      'route': '/daily-challenge',
    },
  );

  // Simulate notification tap
  await FirebaseMessaging.instance.handleBackgroundMessage(message);
  await tester.pumpAndSettle();

  expect(find.byType(DailyChallengeScreen), findsOneWidget);
});

testWidgets('shows snackbar for foreground notification', (tester) async {
  await tester.pumpWidget(MyApp());

  final message = RemoteMessage(
    notification: RemoteNotification(
      title: 'New Challenge',
      body: 'Try today\'s puzzle',
    ),
    data: {'type': 'daily_challenge'},
  );

  // Simulate foreground notification
  await tester.pump();
  FirebaseMessaging.onMessage.add(message);
  await tester.pumpAndSettle();

  expect(find.byType(SnackBar), findsOneWidget);
  expect(find.text('New Challenge'), findsOneWidget);
});
```

### Task 4: Resolve Minor TODOs

For each remaining TODO:
1. Assess whether it's still relevant
2. If yes, implement or create issue
3. If no, remove the TODO comment
4. Document decision

**Common patterns:**
```dart
// ❌ TODO without context
// TODO: Fix this

// ✅ Convert to tracked issue
// See GitHub issue #123: Implement caching for leaderboard

// ✅ Or implement immediately if simple
// (No comment needed if implemented)
```

### Task 5: Create Migration UI

Add UI to inform users about migration:

```dart
class MigrationDialog extends StatelessWidget {
  final int levelsToMigrate;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Upgrade to Cloud Sync'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sign in to sync your progress across devices.'),
          SizedBox(height: 16),
          Text('Your local progress will be merged:'),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.stars, color: Colors.amber),
              SizedBox(width: 8),
              Text('$levelsToMigrate levels completed'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text('Cancel'),
        ),
        FilledButton(
          onPressed: onConfirm,
          child: Text('Sign In & Sync'),
        ),
      ],
    );
  }
}
```

### Task 6: Add Comprehensive Tests

Test all new functionality:
- Migration logic
- Notification navigation
- Error handling
- Edge cases

## Success Criteria

- [ ] All critical TODOs resolved
- [ ] Guest → Firebase migration implemented and tested
- [ ] Notification navigation implemented and tested
- [ ] Migration UI created
- [ ] All tests pass
- [ ] No remaining TODOs without GitHub issues
- [ ] Documentation updated

## Testing Strategy

### Unit Tests
- Test migration logic in isolation
- Test notification routing logic
- Test error scenarios

### Integration Tests
- Test full migration flow
- Test notification navigation flow
- Test with real Firebase (emulator)

### Manual Testing
- Test guest → Firebase upgrade manually
- Test notification taps manually
- Test migration with various data states

## Dependencies

- Firebase Messaging (existing)
- Firestore (existing)
- Local storage (existing)

## Completion Checklist

- [ ] Task 1: TODO audit completed
- [ ] Task 2: Guest → Firebase migration implemented
- [ ] Task 3: Notification navigation implemented
- [ ] Task 4: Minor TODOs resolved
- [ ] Task 5: Migration UI created
- [ ] Task 6: Tests added
- [ ] All tests pass
- [ ] Manual testing completed
- [ ] Code review completed
- [ ] Documentation updated

## Estimated Timeline

- TODO audit: 30 minutes
- Migration implementation: 2 hours
- Notification navigation: 1.5 hours
- Minor TODOs: 1 hour
- Migration UI: 30 minutes
- Tests: 2 hours
- Manual testing: 1 hour
- Review: 30 minutes

**Total: 4-6 hours**
