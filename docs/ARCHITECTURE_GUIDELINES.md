# Architecture Guidelines

## Table of Contents

1. [SOLID Principles](#solid-principles)
2. [Dependency Injection](#dependency-injection)
3. [Single Source of Truth (SSOT)](#single-source-of-truth-ssot)
4. [Code Simplicity (KISS)](#code-simplicity-kiss)
5. [Single Level of Abstraction (SLAP)](#single-level-of-abstraction-slap)
6. [Self-Sufficient Components](#self-sufficient-components)
7. [Proper Abstractions](#proper-abstractions)
8. [Enforcement](#enforcement)
9. [Examples from Codebase](#examples-from-codebase)

---

## SOLID Principles

### Single Responsibility Principle (SRP)

**Definition:** Each class should have exactly one reason to change.

**Guidelines:**
- Maximum 500 lines per file
- Maximum 10 dependencies per class
- Each class should have a single, clear purpose

**Good Example:**
```dart
// ✅ GameEngine only handles game logic
class GameEngine {
  bool canMove(HexCoordinate from, HexCoordinate to) { ... }
  List<HexCoordinate> getValidMoves(HexCoordinate from) { ... }
  bool isCompleted() { ... }
}

// ✅ StarCalculator only calculates star ratings
class StarCalculator {
  int calculateStars(int moves, int optimalMoves) { ... }
}
```

**Bad Example:**
```dart
// ❌ GameProvider doing too much
class GameProvider {
  // Game state management
  void makeMove() { ... }

  // Network requests (should be in repository)
  Future<void> saveToFirebase() { ... }

  // Local storage (should be in repository)
  Future<void> saveLocally() { ... }

  // UI logic (should be in screen)
  void showDialog() { ... }
}
```

---

### Open/Closed Principle (OCP)

**Definition:** Software entities should be open for extension but closed for modification.

**Guidelines:**
- Use interfaces for all repositories
- New behavior via new classes, not modified existing code
- Avoid switch statements on types

**Good Example:**
```dart
// ✅ Open for extension
abstract class AuthRepository {
  Future<AuthResult> signIn();
  Future<void> signOut();
  Stream<User?> get authStateChanges;
}

class FirebaseAuthRepository implements AuthRepository { ... }
class LocalAuthRepository implements AuthRepository { ... }
class HybridAuthRepository implements AuthRepository { ... }

// Can add new implementations without changing existing code
```

**Bad Example:**
```dart
// ❌ Requires modification to extend
class AuthService {
  Future<User> signIn(String provider) {
    if (provider == 'firebase') {
      return _signInWithFirebase();
    } else if (provider == 'local') {
      return _signInLocally();
    }
    // Need to modify this method to add new providers
  }
}
```

---

### Liskov Substitution Principle (LSP)

**Definition:** Derived classes must be substitutable for their base classes without breaking behavior.

**Guidelines:**
- All implementations must respect interface contracts
- No `throw UnimplementedError` in override methods
- Consistent behavior across implementations

**Good Example:**
```dart
// ✅ All implementations respect the contract
abstract class LeaderboardRepository {
  Future<List<LeaderboardEntry>> getTopScores(int limit);
}

class FirebaseLeaderboardRepository implements LeaderboardRepository {
  @override
  Future<List<LeaderboardEntry>> getTopScores(int limit) async {
    // Returns top scores from Firebase
    return _fetchFromFirebase(limit);
  }
}

class LocalLeaderboardRepository implements LeaderboardRepository {
  @override
  Future<List<LeaderboardEntry>> getTopScores(int limit) async {
    // Returns top scores from local storage
    return _fetchFromLocal(limit);
  }
}
```

**Bad Example:**
```dart
// ❌ Breaks contract
class MockLeaderboardRepository implements LeaderboardRepository {
  @override
  Future<List<LeaderboardEntry>> getTopScores(int limit) async {
    throw UnimplementedError('Not implemented in mock');
  }
}
```

---

### Interface Segregation Principle (ISP)

**Definition:** Clients should not depend on interfaces they don't use.

**Guidelines:**
- Maximum 15 methods per interface
- Split large interfaces into smaller, focused ones
- Compose interfaces when needed

**Good Example:**
```dart
// ✅ Segregated interfaces
abstract class UserReader {
  Future<User> getUser(String id);
}

abstract class UserWriter {
  Future<void> saveUser(User user);
  Future<void> deleteUser(String id);
}

// Clients depend only on what they need
class UserProfile {
  final UserReader _reader;
  UserProfile(this._reader);
}

class UserSettings {
  final UserWriter _writer;
  UserSettings(this._writer);
}
```

**Bad Example:**
```dart
// ❌ Fat interface
abstract class UserRepository {
  Future<User> getUser(String id);
  Future<void> saveUser(User user);
  Future<void> deleteUser(String id);
  Future<void> exportData();        // Not all clients need this
  Future<void> importData();        // Not all clients need this
  Future<void> generateReport();    // Not all clients need this
  Future<void> sendEmail();         // Not all clients need this
  Future<void> syncToCloud();       // Not all clients need this
}
```

---

### Dependency Inversion Principle (DIP)

**Definition:** High-level modules should depend on abstractions, not implementations.

**Guidelines:**
- Depend on interfaces, not concrete classes
- All dependencies injected via constructor
- No direct instantiation of dependencies

**Good Example:**
```dart
// ✅ Depends on abstraction
class GameProvider extends StateNotifier<GameState> {
  final LevelRepository _levelRepository;
  final ProgressRepository _progressRepository;

  GameProvider({
    required LevelRepository levelRepository,
    required ProgressRepository progressRepository,
  })  : _levelRepository = levelRepository,
        _progressRepository = progressRepository,
        super(GameState.initial());
}

// Riverpod provider with DI
final gameProvider = StateNotifierProvider<GameProvider, GameState>((ref) {
  return GameProvider(
    levelRepository: ref.watch(levelRepositoryProvider),
    progressRepository: ref.watch(progressRepositoryProvider),
  );
});
```

**Bad Example:**
```dart
// ❌ Depends on concrete implementation
class GameProvider extends StateNotifier<GameState> {
  final FirebaseLevelRepository _levelRepository;

  GameProvider()
    : _levelRepository = FirebaseLevelRepository(), // Direct instantiation
      super(GameState.initial());
}
```

---

## Dependency Injection

### Riverpod Providers

**All dependencies are injected via Riverpod providers.**

**Pattern:**
```dart
// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

// Service provider with dependencies
final gameEngineProvider = Provider<GameEngine>((ref) {
  return GameEngine();
});

// State provider with dependencies
final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier(
    gameEngine: ref.watch(gameEngineProvider),
    levelRepository: ref.watch(levelRepositoryProvider),
    progressRepository: ref.watch(progressRepositoryProvider),
  );
});
```

### Anti-Patterns to Avoid

**No Service Locators:**
```dart
// ❌ BAD
final repository = GetIt.I<AuthRepository>();
final repository = locator<AuthRepository>();
```

**No Singletons (except Firebase.instance):**
```dart
// ❌ BAD
class AuthService {
  static final instance = AuthService._();
  AuthService._();
}
```

**No Direct Firebase Access in Presentation:**
```dart
// ❌ BAD (in presentation layer)
import 'package:firebase_auth/firebase_auth.dart';

final user = FirebaseAuth.instance.currentUser;
```

---

## Single Source of Truth (SSOT)

**All state flows from providers to UI. No duplicate state.**

### Good Pattern

```dart
// ✅ Single source of truth
class GameScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);

    return GameBoard(
      level: gameState.level,
      path: gameState.currentPath,
    );
  }
}
```

### Bad Pattern

```dart
// ❌ Duplicate state
class GameScreen extends StatefulWidget {
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Level? _localLevel; // ❌ Duplicates provider state
  List<HexCoordinate> _localPath; // ❌ Duplicates provider state

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerState = ref.watch(gameProvider);
    // Now we have two sources of truth!
  }
}
```

### Use ConsumerWidget, Not StatefulWidget

```dart
// ✅ GOOD
class GameScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    return Scaffold(body: GameBoard(state: state));
  }
}

// ❌ BAD
class GameScreen extends StatefulWidget {
  // Creates local state that duplicates provider state
}
```

---

## Code Simplicity (KISS)

**Keep It Simple, Stupid - Avoid unnecessary complexity.**

### Guidelines

- Maximum 6 levels of indentation (12 spaces)
- Extract nested logic into helper methods
- Use guard clauses to reduce nesting
- Prefer early returns

### Good Example

```dart
// ✅ Simple, flat structure
Future<void> submitScore(int score) async {
  // Guard clauses
  if (score <= 0) return;

  final user = await _auth.currentUser();
  if (user == null) return;

  final token = _generateToken(user.id);
  await _repository.submitScore(user.id, score, token);
}

String _generateToken(String userId) {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return sha256.convert(utf8.encode('$userId$timestamp')).toString();
}
```

### Bad Example

```dart
// ❌ Deeply nested
Future<void> submitScore(int score) async {
  if (score > 0) {
    final user = await _auth.currentUser();
    if (user != null) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final hash = sha256.convert(utf8.encode('${user.id}$timestamp')).toString();
      if (hash.isNotEmpty) {
        try {
          await _repository.submitScore(user.id, score, hash);
        } catch (e) {
          // Deep nesting makes error handling complex
        }
      }
    }
  }
}
```

---

## Single Level of Abstraction (SLAP)

**Functions should operate at a single level of abstraction.**

### Guidelines

- Maximum 50 lines per function
- Extract low-level details into helper methods
- Each function should read like a recipe

### Good Example

```dart
// ✅ Single abstraction level
Future<void> completeLevel() async {
  final user = await _getCurrentUser();
  final stars = _calculateStars();
  final progress = _createProgress(stars);

  await _saveProgress(progress);
  await _updateLeaderboard(user, stars);
  _showCompletionOverlay();
}

// Low-level details extracted
int _calculateStars() {
  return StarCalculator.calculate(
    moves: currentPath.length,
    optimal: level.optimalMoves,
  );
}

LevelProgress _createProgress(int stars) {
  return LevelProgress(
    levelId: level.id,
    stars: stars,
    completedAt: DateTime.now(),
  );
}
```

### Bad Example

```dart
// ❌ Mixed abstraction levels
Future<void> completeLevel() async {
  // High level
  final user = await _auth.currentUser();

  // Low level (should be extracted)
  final moveDiff = currentPath.length - level.optimalMoves;
  int stars;
  if (moveDiff <= 0) {
    stars = 3;
  } else if (moveDiff <= 5) {
    stars = 2;
  } else {
    stars = 1;
  }

  // High level
  await _repository.saveProgress(LevelProgress(
    levelId: level.id,
    stars: stars,
    // Low level details mixed in
    completedAt: DateTime.now(),
    timestamp: DateTime.now().millisecondsSinceEpoch,
  ));
}
```

---

## Self-Sufficient Components

**Components should query what they need, not assume pre-loaded data.**

### Good Example

```dart
// ✅ Self-sufficient - queries its own data
class UserProfile extends ConsumerWidget {
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider(userId));

    return userAsync.when(
      data: (user) => Text(user.name),
      loading: () => CircularProgressIndicator(),
      error: (error, _) => Text('Error: $error'),
    );
  }
}
```

### Bad Example

```dart
// ❌ Assumes data is pre-loaded
class UserProfile extends ConsumerWidget {
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Assumes user is already in cache
    final user = ref.watch(userCacheProvider)[userId];

    // Will crash if user is null
    return Text(user.name);
  }
}
```

---

## Proper Abstractions

**Use proper architectural patterns, not type checking.**

### Good Example

```dart
// ✅ Proper abstraction
abstract class GameInput {
  HexCoordinate? getTargetCell(HexGridLayout layout);
}

class MouseInput implements GameInput {
  final Offset position;

  @override
  HexCoordinate? getTargetCell(HexGridLayout layout) {
    return layout.pixelToHex(position);
  }
}

class TouchInput implements GameInput {
  final Offset position;

  @override
  HexCoordinate? getTargetCell(HexGridLayout layout) {
    return layout.pixelToHex(position);
  }
}

class GameEngine {
  void processInput(GameInput input) {
    final cell = input.getTargetCell(_layout);
    if (cell != null) {
      _handleCellSelection(cell);
    }
  }
}
```

### Bad Example

```dart
// ❌ Type checking multiple input types
class GameEngine {
  void processInput(dynamic input) {
    if (input is MouseInput) {
      _handleMouseInput(input);
    } else if (input is TouchInput) {
      _handleTouchInput(input);
    } else if (input is KeyboardInput) {
      _handleKeyboardInput(input);
    }
    // Need to modify this method for new input types
  }
}
```

---

## Enforcement

Architecture principles are enforced through:

### 1. Automated Tests

```bash
# Run architecture tests
dart test test/architecture/solid_test.dart
```

Tests validate:
- File size limits (500 lines)
- Function size limits (50 lines)
- Dependency injection patterns
- SOLID principle compliance
- Interface usage
- No service locators
- No singletons

### 2. Validation Script

```bash
# Run full architecture validation
dart scripts/architecture_validation.dart
```

Generates comprehensive report:
- SOLID principles compliance
- Dependency injection validation
- Code complexity metrics
- Component design validation
- Detailed violation list

### 3. Pre-commit Hook

```bash
# Runs automatically before commits
dart scripts/pre_commit.dart
```

Checks:
- Code formatting
- Linting
- Architecture tests
- Unit tests
- Code coverage

### 4. Code Metrics

Maximum limits:
- **500 lines** per file
- **50 lines** per function
- **10 dependencies** per class
- **15 methods** per interface
- **6 levels** of nesting (12 spaces)

### 5. Code Review Guidelines

Review checklist:
- [ ] Dependencies injected via constructor
- [ ] No direct Firebase access in presentation
- [ ] Repositories implement interfaces
- [ ] No StatefulWidget in screens
- [ ] Functions under 50 lines
- [ ] No deep nesting (>6 levels)
- [ ] Proper error handling
- [ ] Tests for new features

---

## Examples from Codebase

### Repository Pattern

```dart
// Interface in domain layer
abstract class AuthRepository {
  Future<AuthResult> signIn();
  Future<void> signOut();
  Stream<User?> get authStateChanges;
}

// Implementation in data layer
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Future<AuthResult> signIn() async {
    // Firebase implementation
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(_mapFirebaseUser);
  }
}
```

### Provider Pattern with DI

```dart
// Providers in presentation layer
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    authRepository: ref.watch(authRepositoryProvider),
  );
});

// Notifier with injected dependencies
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const AuthState.initial());

  Future<void> signIn() async {
    state = const AuthState.loading();
    try {
      final result = await _authRepository.signIn();
      state = AuthState.authenticated(result.user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
}
```

### Screen Pattern

```dart
// ConsumerWidget for SSOT
class GameScreen extends ConsumerWidget {
  final String levelId;

  const GameScreen({required this.levelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Single source of truth from provider
    final gameState = ref.watch(gameProvider);

    return Scaffold(
      body: gameState.when(
        data: (state) => GameBoard(
          level: state.level,
          currentPath: state.currentPath,
          onCellTap: (coord) => ref.read(gameProvider.notifier).makeMove(coord),
        ),
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(error: error),
      ),
    );
  }
}
```

### Domain Service Pattern

```dart
// Pure business logic, no dependencies
class GameEngine {
  bool canMove(
    HexCoordinate from,
    HexCoordinate to,
    List<HexCoordinate> path,
    Level level,
  ) {
    // Validate move
    if (!_isAdjacent(from, to)) return false;
    if (path.contains(to)) return false;
    if (_hasWallBetween(from, to, level)) return false;

    return true;
  }

  bool _isAdjacent(HexCoordinate from, HexCoordinate to) {
    final neighbors = from.getNeighbors();
    return neighbors.contains(to);
  }

  bool _hasWallBetween(HexCoordinate from, HexCoordinate to, Level level) {
    return level.walls.any((wall) =>
      (wall.from == from && wall.to == to) ||
      (wall.from == to && wall.to == from)
    );
  }
}
```

---

## Summary

### Core Principles

1. **SOLID** - Maintainable, extensible code
2. **DI** - All dependencies injected, no service locators
3. **SSOT** - Single source of truth via providers
4. **KISS** - Keep it simple, avoid deep nesting
5. **SLAP** - Single level of abstraction per function
6. **Self-Sufficient** - Components query their needs
7. **Proper Abstractions** - Use polymorphism, not type checking

### Metrics

- Max 500 lines per file
- Max 50 lines per function
- Max 10 dependencies per class
- Max 15 methods per interface
- Max 6 levels of nesting

### Enforcement

- Automated tests
- Validation scripts
- Pre-commit hooks
- Code review checklist
- CI/CD pipeline checks

---

**Last Updated:** 2026-01-30
**Version:** 1.0
**Status:** Active
