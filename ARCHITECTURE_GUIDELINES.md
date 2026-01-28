# Architecture Guidelines - Preventing State Management Bugs

## The Bug We Fixed

**Problem**: Game completion triggered internally but submission logic relied on `didUpdateWidget()`, which only fires when the parent widget rebuilds. Result: submission never happened.

**Root Cause**: Mixing widget lifecycle methods with business logic that depends on internal state changes.

---

## ✅ Best Practices to Prevent Similar Bugs

### 1. **NEVER Use Widget Lifecycle for Business Logic**

❌ **BAD** - Relying on `didUpdateWidget`:
```dart
@override
void didUpdateWidget(MyWidget oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (gameState.isComplete && !submitted) {
    submitScore(); // May never be called!
  }
}
```

✅ **GOOD** - Use `ref.listen` for state changes:
```dart
@override
Widget build(BuildContext context) {
  ref.listen(gameProvider, (previous, next) {
    if (!previous?.isComplete && next.isComplete) {
      submitScore(); // Always called when state changes
    }
  });
  return ...;
}
```

### 2. **Use Side Effects Properly**

✅ **Pattern**: Separate state changes from side effects
```dart
// In Notifier
void completeGame() {
  state = state.copyWith(isComplete: true);
  // Emit event for side effects
  _eventController.add(GameCompletedEvent(state));
}

// In UI
ref.listen(gameEventsProvider, (event) {
  if (event is GameCompletedEvent) {
    submitScore(event.state);
  }
});
```

### 3. **Single Source of Truth**

❌ **BAD** - Multiple flags tracking same state:
```dart
bool scoreSubmitted = false;  // Widget state
bool _hasSubmitted = false;   // Component state
// Risk: Can get out of sync!
```

✅ **GOOD** - One authoritative source:
```dart
// In state class
class GameState {
  final bool isComplete;
  final bool scoreSubmitted;
  // State machine: not-started → playing → complete → submitted
}
```

### 4. **Explicit Event Handling**

✅ Create explicit event streams:
```dart
class GameNotifier extends StateNotifier<GameState> {
  final _eventsController = StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get events => _eventsController.stream;

  void completeLevel() {
    state = state.copyWith(isComplete: true);
    _eventsController.add(LevelCompletedEvent(state));
  }
}
```

### 5. **Repository Pattern for All Data Operations**

✅ All submissions go through repositories:
```dart
// UI never calls Firestore directly
await ref.read(dailyChallengeRepositoryProvider)
  .submitCompletion(userId: user.id, stars: 3, time: 1000);
```

### 6. **State Machines for Complex Flows**

✅ Use explicit state transitions:
```dart
enum GamePhase {
  notStarted,
  playing,
  completed,
  submitting,
  submitted,
  submitFailed,
}

// Illegal state transitions become compiler errors
void submitScore() {
  if (state.phase != GamePhase.completed) {
    throw StateError('Cannot submit from ${state.phase}');
  }
  state = state.copyWith(phase: GamePhase.submitting);
  // ...
}
```

---

## 🧪 Testing Strategy

### Required Tests to Prevent This Bug:

#### 1. Integration Test
```dart
testWidgets('Completing daily challenge submits score', (tester) async {
  // Given: User is authenticated and playing daily challenge
  await tester.pumpWidget(createApp());
  await tester.tap(find.text('Daily Challenge'));
  await tester.pumpAndSettle();

  // When: User completes the challenge
  await completeChallenge(tester);
  await tester.pumpAndSettle();

  // Then: Score should be submitted to Firestore
  final completions = await getFirestoreCompletions(todayDate);
  expect(completions, hasLength(1));
  expect(completions.first.userId, currentUser.id);
});
```

#### 2. State Change Test
```dart
test('Game completion triggers submission event', () {
  final notifier = GameNotifier();
  final events = <GameEvent>[];
  notifier.events.listen(events.add);

  notifier.completeLevel();

  expect(events, contains(isA<LevelCompletedEvent>()));
});
```

#### 3. Listener Test
```dart
testWidgets('ref.listen triggers on state change', (tester) async {
  var submitCalled = false;

  await tester.pumpWidget(
    ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          ref.listen(gameProvider, (prev, next) {
            if (next.isComplete) submitCalled = true;
          });
          return Container();
        },
      ),
    ),
  );

  // Trigger completion
  container.read(gameProvider.notifier).completeGame();
  await tester.pump();

  expect(submitCalled, isTrue);
});
```

---

## 📋 Code Review Checklist

Before merging, verify:

- [ ] No business logic in `initState`, `didUpdateWidget`, or `dispose`
- [ ] All state-dependent side effects use `ref.listen()` or event streams
- [ ] State changes are atomic (no multi-step state updates)
- [ ] Critical flows have integration tests
- [ ] State transitions are explicit and documented
- [ ] No duplicate sources of truth for the same data
- [ ] All async operations have error handling
- [ ] Side effects are logged for debugging

---

## 🔍 Debugging Tools

### Add Logging Middleware
```dart
class LoggingNotifier<T> extends Notifier<T> {
  @override
  T build() {
    ref.listenSelf((previous, next) {
      print('State changed: $previous → $next');
    });
    return buildInitial();
  }

  T buildInitial(); // Implement in subclass
}
```

### State Inspector
```dart
// Add to every critical notifier
void _logStateChange(String method, T oldState, T newState) {
  print('[$method] State transition:');
  print('  From: ${oldState.toJson()}');
  print('  To:   ${newState.toJson()}');
}
```

---

## 🎯 Key Principle

**"State changes should always trigger their side effects, regardless of how the UI is built"**

If submission depends on game completion, listen to the game state, not the widget lifecycle.

---

## 🚫 Anti-Patterns to Avoid

1. **Lifecycle-dependent logic**: `didUpdateWidget`, `initState` for business logic
2. **Implicit dependencies**: Expecting widget rebuilds to trigger logic
3. **Manual flag management**: Tracking "already done" with booleans
4. **Silent failures**: Side effects that can fail without notification
5. **Scattered state**: Same logical state stored in multiple places

---

## ✅ Recommended Patterns

1. **Reactive listeners**: `ref.listen()` for all side effects
2. **Event streams**: Explicit events for cross-cutting concerns
3. **State machines**: Explicit phases/states with transitions
4. **Repository pattern**: All data operations through repositories
5. **Integration tests**: Test complete user flows end-to-end

---

## 📚 Further Reading

- [Riverpod Best Practices](https://riverpod.dev/docs/concepts/reading)
- [State Management Patterns](https://flutter.dev/docs/development/data-and-backend/state-mgmt/options)
- [Testing Flutter Apps](https://flutter.dev/docs/testing)

---

**Last Updated**: 2026-01-28
**Author**: Based on bug fix in daily challenge submission flow
