# Architecture Quick Reference

**Quick guide for maintaining architectural quality in Hex Buzz**

---

## Run Validations

```bash
# Full validation
dart scripts/architecture_validation.dart

# Architecture tests
flutter test test/architecture/

# All tests
flutter test
```

---

## Code Limits

| Metric | Limit | Check |
|--------|-------|-------|
| Lines per file | 500 | Split into multiple files |
| Lines per function | 50 | Extract helper methods |
| Dependencies per class | 10 | Reduce coupling |
| Methods per interface | 15 | Segregate interfaces |
| Nesting levels | 6 (12 spaces) | Use guard clauses |

---

## SOLID Quick Check

### ✅ Single Responsibility
```dart
// One class, one purpose
class GameEngine {
  // Only game logic, nothing else
}
```

### ✅ Open/Closed
```dart
// Use interfaces
abstract class Repository { }
class FirebaseRepository implements Repository { }
class LocalRepository implements Repository { }
```

### ✅ Liskov Substitution
```dart
// All implementations work the same
final repos = [FirebaseRepo(), LocalRepo()];
for (final repo in repos) {
  await repo.getData(); // All work consistently
}
```

### ✅ Interface Segregation
```dart
// Small, focused interfaces
abstract class Reader {
  Future<Data> read();
}
abstract class Writer {
  Future<void> write(Data data);
}
```

### ✅ Dependency Inversion
```dart
// Depend on interfaces
class Provider {
  final Repository _repo; // Interface, not concrete class
  Provider(this._repo);
}
```

---

## Common Patterns

### ✅ Dependency Injection (Riverpod)

```dart
// Repository provider
final repoProvider = Provider<Repository>((ref) {
  return FirebaseRepository();
});

// State provider with DI
final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier(
    repository: ref.watch(repoProvider),
  );
});
```

### ✅ Screen Pattern (ConsumerWidget)

```dart
class GameScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    return GameBoard(state: state);
  }
}
```

### ✅ Self-Sufficient Component

```dart
class UserProfile extends ConsumerWidget {
  final String userId;

  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider(userId));
    return userAsync.when(
      data: (user) => Text(user.name),
      loading: () => LoadingIndicator(),
      error: (e, _) => ErrorView(e),
    );
  }
}
```

### ✅ Keep Functions Small

```dart
Future<void> submitScore() async {
  if (!_validate()) return;

  final token = await _generateToken();
  await _sendToServer(token);
  _updateUI();
}

// Extract helpers
Future<String> _generateToken() async { ... }
```

---

## Common Anti-Patterns

### ❌ Service Locator

```dart
// DON'T DO THIS
final repo = GetIt.I<Repository>();
final repo = locator<Repository>();
```

### ❌ Singleton

```dart
// DON'T DO THIS
class Service {
  static final instance = Service._();
  Service._();
}
```

### ❌ Direct Firebase in Presentation

```dart
// DON'T DO THIS
import 'package:firebase_auth/firebase_auth.dart';

class Screen extends Widget {
  final user = FirebaseAuth.instance.currentUser;
}
```

### ❌ StatefulWidget in Screens

```dart
// DON'T DO THIS
class GameScreen extends StatefulWidget {
  State<GameScreen> createState() => _GameScreenState();
}

// USE INSTEAD
class GameScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) { ... }
}
```

### ❌ Dynamic Type Checking

```dart
// DON'T DO THIS
void handle(dynamic input) {
  if (input is TypeA) { ... }
  else if (input is TypeB) { ... }
}

// USE INSTEAD
abstract class Input {
  void handle();
}
class TypeA implements Input { ... }
class TypeB implements Input { ... }
```

---

## Fixing Violations

### File Too Large

```dart
// Split into multiple focused files
game_provider.dart        // State management
game_engine.dart         // Game logic
game_repository.dart     // Data access
```

### Function Too Long

```dart
// Extract helper methods
Future<void> complexOperation() async {
  await _step1();
  await _step2();
  await _step3();
}

Future<void> _step1() async { ... }
Future<void> _step2() async { ... }
```

### Deep Nesting

```dart
// Use guard clauses
Future<void> process() async {
  if (!isValid) return;  // Early return
  if (user == null) return;  // Early return

  // Main logic at top level
  await doWork();
}
```

---

## Pre-Commit Checklist

- [ ] Run `dart scripts/architecture_validation.dart`
- [ ] Run `flutter test`
- [ ] No new violations introduced
- [ ] All dependencies injected
- [ ] No StatefulWidget in screens
- [ ] Functions under 50 lines
- [ ] Files under 500 lines

---

## Resources

- [ARCHITECTURE_GUIDELINES.md](./ARCHITECTURE_GUIDELINES.md) - Full guidelines
- [ARCHITECTURE_ANALYSIS.md](./ARCHITECTURE_ANALYSIS.md) - Current state
- [ARCHITECTURE_VALIDATION.md](./ARCHITECTURE_VALIDATION.md) - Validation guide

---

## Quick Fixes

### "File too large" violation
→ Split into multiple files

### "Function too long" violation
→ Extract helper methods

### "Direct Firebase import" violation
→ Use repository interface

### "StatefulWidget in screen" violation
→ Use ConsumerWidget

### "Deep nesting" violation
→ Use guard clauses, extract methods

---

**Keep this handy during development!**

Last Updated: 2026-01-30
