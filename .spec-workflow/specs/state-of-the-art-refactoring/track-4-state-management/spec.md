# Track 4: State Management Cleanup

**Status:** ready
**Priority:** high
**Parent Spec:** `../spec.md`
**Effort:** Small (2-3 hours)
**Risk:** Low

## Objective

Replace widget lifecycle antipattern (`didUpdateWidget`) with proper Riverpod patterns (`ref.listen`) for side effects.

## Problem Statement

Some screens use `didUpdateWidget()` to react to prop changes instead of using Riverpod's `ref.listen()`. This antipattern:
- Doesn't work with widget rebuilds from parent
- Creates subtle state management bugs
- Violates Riverpod best practices
- Makes code harder to test

**Reference:** `ARCHITECTURE_GUIDELINES.md` documents this issue

## Files to Refactor

Based on codebase analysis, files likely using `didUpdateWidget`:
1. `lib/presentation/screens/game_screen.dart`
2. `lib/presentation/screens/daily_challenge_screen.dart`
3. `lib/presentation/screens/level_select_screen.dart`
4. Other screens (to be identified during audit)

## Implementation Tasks

### Task 1: Audit Widget Lifecycle Usage
```bash
grep -r "didUpdateWidget" lib/presentation --include="*.dart"
grep -r "didChangeDependencies" lib/presentation --include="*.dart"
```

Document all instances and their purposes.

### Task 2: Understand Current Patterns

**Antipattern Example:**
```dart
class GameScreen extends StatefulWidget {
  final String levelId;
  const GameScreen({required this.levelId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void didUpdateWidget(GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ❌ ANTIPATTERN: Side effect in widget lifecycle
    if (widget.levelId != oldWidget.levelId) {
      _loadLevel(widget.levelId);
    }
  }

  void _loadLevel(String levelId) {
    // Load level logic
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

### Task 3: Convert to Riverpod Pattern

**Corrected Pattern:**
```dart
class GameScreen extends ConsumerWidget {
  final String levelId;
  const GameScreen({required this.levelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ CORRECT: Use ref.listen for side effects
    ref.listen<AsyncValue<Level>>(
      levelProvider(levelId),
      (previous, next) {
        next.whenData((level) {
          // Side effect: Show level loaded message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Level ${level.id} loaded')),
          );
        });
      },
    );

    final levelAsync = ref.watch(levelProvider(levelId));

    return levelAsync.when(
      data: (level) => GameBoard(level: level),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}
```

### Task 4: Pattern Variations

#### Pattern 1: Simple Property Change
```dart
// ❌ Before
@override
void didUpdateWidget(MyWidget oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (widget.userId != oldWidget.userId) {
    _fetchUserData(widget.userId);
  }
}

// ✅ After
@override
Widget build(BuildContext context, WidgetRef ref) {
  ref.listen(userIdProvider, (previous, next) {
    if (previous != next) {
      ref.read(userDataProvider(next).future);
    }
  });
  // ... rest of build
}
```

#### Pattern 2: Navigation Side Effect
```dart
// ❌ Before
@override
void didUpdateWidget(MyScreen oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (widget.shouldNavigate && !oldWidget.shouldNavigate) {
    Navigator.of(context).push(...);
  }
}

// ✅ After
@override
Widget build(BuildContext context, WidgetRef ref) {
  ref.listen(navigationProvider, (previous, next) {
    if (next.shouldNavigate) {
      Navigator.of(context).push(...);
    }
  });
  // ... rest of build
}
```

#### Pattern 3: Show Dialog/Snackbar
```dart
// ❌ Before
@override
void didUpdateWidget(MyScreen oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (widget.errorMessage != null && oldWidget.errorMessage == null) {
    _showErrorDialog(widget.errorMessage);
  }
}

// ✅ After
@override
Widget build(BuildContext context, WidgetRef ref) {
  ref.listen(errorProvider, (previous, next) {
    if (next != null) {
      showDialog(
        context: context,
        builder: (_) => ErrorDialog(message: next),
      );
    }
  });
  // ... rest of build
}
```

### Task 5: Convert StatefulWidget to ConsumerWidget

Many cases can be simplified by converting `StatefulWidget` to `ConsumerWidget`:

```dart
// ❌ Before: StatefulWidget with local state
class GameScreen extends StatefulWidget {
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _isLoading = false;

  @override
  void didUpdateWidget(GameScreen oldWidget) {
    // ... antipattern
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

// ✅ After: ConsumerWidget with provider state
class GameScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(gameLoadingProvider);

    ref.listen(gameLevelProvider, (previous, next) {
      // Side effects here
    });

    return Container();
  }
}
```

### Task 6: Handle Complex Cases

For widgets that genuinely need local state + side effects:

```dart
class GameScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Use ref.listen, not didUpdateWidget
    ref.listen(gameStateProvider, (previous, next) {
      if (next.isCompleted && previous?.isCompleted != true) {
        _controller.forward();
      }
    });

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### Task 7: Update Tests

Tests should verify side effects occur:

```dart
testWidgets('shows snackbar when level loads', (tester) async {
  final container = ProviderContainer(overrides: [
    levelProvider(testLevelId).overrideWith(
      (ref) => AsyncValue.data(testLevel),
    ),
  ]);

  await tester.pumpWidget(
    ProviderScope(
      parent: container,
      child: MaterialApp(
        home: GameScreen(levelId: testLevelId),
      ),
    ),
  );

  await tester.pump();

  expect(find.byType(SnackBar), findsOneWidget);
  expect(find.text('Level test-1 loaded'), findsOneWidget);
});
```

## Files to Refactor

### Priority 1: Critical Screens
1. **GameScreen** - Level loading, game state changes
2. **DailyChallengeScreen** - Challenge loading, completion
3. **LeaderboardScreen** - Leaderboard updates

### Priority 2: Other Screens
4. **LevelSelectScreen** - Level selection
5. **AuthScreen** - Auth state changes
6. **NotificationSettingsScreen** - Settings updates

### Priority 3: Complex Widgets
7. **CompletionOverlay** - Animation triggers
8. **HoverButton** - Hover state management

## Refactoring Checklist per File

For each file:
- [ ] Identify all `didUpdateWidget` usages
- [ ] Identify the side effects being triggered
- [ ] Convert side effects to `ref.listen`
- [ ] Convert `StatefulWidget` to `ConsumerWidget` if possible
- [ ] Update tests to verify side effects
- [ ] Verify UI behavior unchanged
- [ ] Run tests

## Success Criteria

- [ ] Zero `didUpdateWidget` usages in presentation layer (except where genuinely needed)
- [ ] Zero `didChangeDependencies` antipatterns
- [ ] All side effects use `ref.listen`
- [ ] All tests pass
- [ ] UI behavior unchanged
- [ ] Code follows Riverpod best practices

## Testing Strategy

### Unit Tests
- Test that side effects occur at the right time
- Test that side effects don't occur unnecessarily

### Integration Tests
- Test full user flows with side effects
- Verify navigation, dialogs, snackbars work correctly

### Manual Testing
- Test each refactored screen manually
- Verify no regressions in behavior

## Rollback Plan

If issues arise:
1. Revert specific file
2. Debug issue
3. Reapply refactoring with fix

## Dependencies

- `flutter_riverpod` (existing)
- `riverpod_test` (existing)

## Completion Checklist

- [ ] Task 1: Widget lifecycle audit completed
- [ ] Task 2: Current patterns documented
- [ ] Task 3: Conversion pattern established
- [ ] Task 4: All pattern variations handled
- [ ] Task 5: StatefulWidgets converted where appropriate
- [ ] Task 6: Complex cases handled
- [ ] Task 7: Tests updated
- [ ] All screens refactored
- [ ] All tests pass
- [ ] Manual testing completed
- [ ] Code review completed
- [ ] Documentation updated

## Estimated Timeline

- Audit: 30 minutes
- Pattern documentation: 30 minutes
- Refactor GameScreen: 30 minutes
- Refactor DailyChallengeScreen: 30 minutes
- Refactor LeaderboardScreen: 30 minutes
- Refactor other screens: 1 hour
- Update tests: 1 hour
- Manual testing: 30 minutes
- Review: 30 minutes

**Total: 2-3 hours**
