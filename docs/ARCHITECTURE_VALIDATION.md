# Architecture Validation System

This document describes the architecture validation system for the Hex Buzz project.

## Overview

The validation system ensures the codebase adheres to architectural principles including SOLID, dependency injection patterns, and code quality standards.

## Components

### 1. Validation Script

**Location:** `scripts/architecture_validation.dart`

**Purpose:** Automated validation of architectural principles across the entire codebase.

**Usage:**
```bash
# Run full validation
dart scripts/architecture_validation.dart

# Generates report at: docs/architecture_validation_report.md
```

**What it validates:**
- ✅ SOLID principles (SRP, OCP, LSP, ISP, DIP)
- ✅ Dependency injection patterns
- ✅ Single source of truth (SSOT)
- ✅ Code simplicity (KISS)
- ✅ Single level of abstraction (SLAP)
- ✅ Self-sufficient components
- ✅ Proper abstractions

**Exit codes:**
- `0` - All validations pass
- `1` - Violations found

### 2. Architecture Tests

**Location:** `test/architecture/solid_test.dart`

**Purpose:** Automated tests enforcing architectural patterns.

**Usage:**
```bash
# Run architecture tests
flutter test test/architecture/solid_test.dart

# Run all tests including architecture
flutter test
```

**What it tests:**
- File size limits (500 lines)
- Function size limits (50 lines)
- Dependency injection compliance
- No service locators
- No singletons (except Firebase.instance)
- Repository interfaces
- No StatefulWidget in screens
- Component self-sufficiency
- Proper abstractions

### 3. Documentation

#### Architecture Guidelines

**Location:** `docs/ARCHITECTURE_GUIDELINES.md`

**Content:**
- Detailed explanation of each principle
- Good and bad examples from codebase
- Code patterns and anti-patterns
- Enforcement mechanisms
- Real code examples

#### Architecture Analysis

**Location:** `docs/ARCHITECTURE_ANALYSIS.md`

**Content:**
- Executive summary
- Detailed validation results
- Compliance scores
- Recommendations
- Best practices

## Metrics and Limits

### File Metrics

| Metric | Limit | Rationale |
|--------|-------|-----------|
| Lines per file | 500 | Single Responsibility Principle |
| Lines per function | 50 | Single Level of Abstraction |
| Dependencies per class | 10 | Reduces coupling |
| Methods per interface | 15 | Interface Segregation |
| Nesting levels | 6 (12 spaces) | Code simplicity (KISS) |

### Quality Gates

Tests fail if:
- Any file exceeds 500 lines
- Any function exceeds 50 lines
- Service locators are used
- Singletons are created (except Firebase.instance)
- Presentation layer imports Firebase directly
- Repositories don't implement interfaces
- Screens use StatefulWidget instead of ConsumerWidget

## Running Validations

### Local Development

```bash
# Quick validation
dart scripts/architecture_validation.dart

# Full test suite
flutter test

# Architecture tests only
flutter test test/architecture/
```

### Pre-commit Hook

The validation runs automatically before commits:

```bash
# Runs automatically on git commit
dart scripts/pre_commit.dart
```

Includes:
- Code formatting
- Linting
- Architecture tests
- Unit tests
- Coverage check

### CI/CD Pipeline

Add to your CI/CD pipeline:

```yaml
# .github/workflows/ci.yml
- name: Architecture Validation
  run: dart scripts/architecture_validation.dart

- name: Architecture Tests
  run: flutter test test/architecture/

- name: All Tests
  run: flutter test --coverage
```

## Understanding Results

### Validation Report

Generated at `docs/architecture_validation_report.md`:

```markdown
## SOLID Principles

- Single Responsibility Principle: ✅ PASS
- Open/Closed Principle: ✅ PASS
- Liskov Substitution Principle: ❌ FAIL
- ...

## Violations: 4

### Liskov Substitution Principle
- lib/presentation/providers/auth_provider.dart: Override throws UnimplementedError
- ...
```

### Test Output

```
✅ Single Responsibility Principle
  ✅ all files are under 500 lines
  ✅ classes have max 10 dependencies

❌ Liskov Substitution Principle
  ❌ no override methods throw UnimplementedError
     - lib/presentation/providers/auth_provider.dart
```

## Known Acceptable Violations

### 1. Riverpod StateNotifier Base Class

**Issue:** StateNotifier base class methods throw UnimplementedError

**Example:**
```dart
class AuthNotifier extends StateNotifier<AuthState> {
  @override
  void dispose() {
    throw UnimplementedError(); // From StateNotifier base class
  }
}
```

**Status:** Acceptable - this is idiomatic Riverpod pattern

**Impact:** Low - framework-level pattern, not business logic

### 2. Flutter Widget Tree Nesting

**Issue:** Flutter widget composition creates deep nesting

**Example:**
```dart
Widget build(BuildContext context) {
  return Scaffold(          // Level 1
    body: Center(           // Level 2
      child: Column(        // Level 3
        children: [
          Container(        // Level 4
            child: Padding( // Level 5
              child: Row(   // Level 6
                children: [ // Level 7 - exceeds limit
                  Icon(...),
                  Text(...),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
```

**Status:** Acceptable - idiomatic Flutter pattern

**Impact:** Low - declarative UI requires deep nesting

**Mitigation:** Extract complex widgets into separate classes

### 3. App Initialization (main.dart)

**Issue:** Main function exceeds 50 lines

**Reason:** App initialization requires multiple steps:
- Firebase initialization
- Riverpod setup
- Provider configuration
- Platform-specific setup

**Status:** Acceptable - infrastructure code

**Impact:** Low - runs once at startup

## Fixing Violations

### Common Violations and Fixes

#### 1. File Too Large (>500 lines)

**Problem:** Class has too many responsibilities

**Fix:** Split into multiple classes

```dart
// ❌ BAD - 600 lines
class GameProvider {
  // Game logic
  // Network calls
  // Local storage
  // UI state
}

// ✅ GOOD
class GameProvider {
  final GameEngine _engine;
  final LevelRepository _repository;
  final ProgressRepository _progress;
  // Only state management - 150 lines
}

class GameEngine {
  // Only game logic - 200 lines
}
```

#### 2. Function Too Long (>50 lines)

**Problem:** Function does too much

**Fix:** Extract helper methods

```dart
// ❌ BAD - 80 lines
Future<void> submitScore() async {
  // Validation logic (10 lines)
  // Token generation (15 lines)
  // Network call (20 lines)
  // Error handling (15 lines)
  // UI update (10 lines)
}

// ✅ GOOD
Future<void> submitScore() async {
  if (!_validateScore()) return;

  final token = await _generateToken();
  await _sendToServer(token);
  _updateUI();
}
```

#### 3. Direct Firebase Import

**Problem:** Presentation layer imports Firebase

**Fix:** Use repository interface

```dart
// ❌ BAD
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
  }
}

// ✅ GOOD
class ProfileScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
  }
}
```

#### 4. StatefulWidget in Screens

**Problem:** Screen uses StatefulWidget creating duplicate state

**Fix:** Use ConsumerWidget

```dart
// ❌ BAD
class GameScreen extends StatefulWidget {
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Level? _level; // Duplicate state

  @override
  Widget build(BuildContext context) { ... }
}

// ✅ GOOD
class GameScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    return GameBoard(level: gameState.level);
  }
}
```

## Integration with Development Workflow

### 1. During Development

Run validation before committing:
```bash
dart scripts/architecture_validation.dart
```

### 2. Code Review

Check architecture report:
- Review `docs/architecture_validation_report.md`
- Ensure no new violations introduced
- Verify fixes for existing violations

### 3. Continuous Integration

Add to CI pipeline:
```bash
# Fail build if violations found
dart scripts/architecture_validation.dart || exit 1

# Run architecture tests
flutter test test/architecture/
```

### 4. Monitoring

Track metrics over time:
- Total violations
- Violations by category
- File sizes
- Function sizes
- Test coverage

## Customizing Validation

### Adjusting Limits

Edit `scripts/architecture_validation.dart`:

```dart
// Change limits
if (lines > 500) { ... }  // Change file size limit
if (func.lines > 50) { ... }  // Change function size limit
if (indent > 12) { ... }  // Change nesting limit
```

### Adding New Validators

Create new validator class:

```dart
class CustomValidator implements Validator {
  @override
  String get name => 'Custom Validation';

  @override
  Future<ValidationResult> validate() async {
    final violations = <String>[];

    // Your validation logic

    return ValidationResult(name, violations);
  }
}

// Add to validators list
final validators = [
  SRPValidator(),
  OCPValidator(),
  CustomValidator(), // Add here
];
```

### Excluding Files

Skip files from validation:

```dart
Future<List<File>> _getDartFiles(String path) async {
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.contains('generated')) // Exclude generated
      .where((f) => !f.path.contains('.g.dart'))  // Exclude build_runner
      .toList();
}
```

## Troubleshooting

### Tests Fail Locally But Pass in CI

**Cause:** Different Flutter versions or dependencies

**Fix:**
```bash
flutter clean
flutter pub get
flutter test
```

### Too Many Widget Nesting Violations

**Cause:** Flutter widget trees naturally create deep nesting

**Fix:** Consider these acceptable or extract complex widgets:

```dart
// Extract complex widget
Widget _buildComplexSection() {
  return Container(...);
}

Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        _buildComplexSection(), // Extracted
      ],
    ),
  );
}
```

### LSP Violations in Providers

**Cause:** Riverpod StateNotifier base class pattern

**Status:** Acceptable - framework pattern

**Fix:** Document as acceptable violation or create custom base classes

## Best Practices

### 1. Run Validation Early and Often

```bash
# Before committing
dart scripts/architecture_validation.dart

# Before pushing
flutter test
```

### 2. Keep Functions Small

Aim for 20-30 lines, max 50:
- Easier to understand
- Easier to test
- Easier to maintain

### 3. Extract Complex Logic

When you see deep nesting:
- Extract to helper method
- Use guard clauses
- Prefer early returns

### 4. Use Proper Abstractions

Instead of type checking:
- Define interfaces
- Use polymorphism
- Leverage Dart's type system

### 5. Document Exceptions

If you must violate a principle:
- Document why
- Add comment explaining
- Create ticket to fix later

## Resources

- [ARCHITECTURE_GUIDELINES.md](./ARCHITECTURE_GUIDELINES.md) - Detailed principles
- [ARCHITECTURE_ANALYSIS.md](./ARCHITECTURE_ANALYSIS.md) - Current state analysis
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [Riverpod Documentation](https://riverpod.dev/)

## Support

For questions or issues with the validation system:

1. Check existing documentation
2. Review example violations and fixes
3. Consult architecture guidelines
4. Ask in code review

---

**Last Updated:** 2026-01-30
**Version:** 1.0
**Status:** Active
