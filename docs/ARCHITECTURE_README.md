# Architecture Documentation

**Complete architecture validation and documentation system for Hex Buzz**

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Documentation Index](#documentation-index)
4. [Validation Tools](#validation-tools)
5. [Current Status](#current-status)
6. [For Developers](#for-developers)
7. [For Reviewers](#for-reviewers)
8. [For Maintainers](#for-maintainers)

---

## Overview

The Hex Buzz project includes a comprehensive architecture validation system that ensures code quality, maintainability, and adherence to best practices.

### Key Features

- ✅ **Automated validation** - Scripts check 11 architectural principles
- ✅ **Enforced tests** - Automated tests prevent regressions
- ✅ **Comprehensive docs** - Guidelines, examples, and quick references
- ✅ **Detailed reports** - Auto-generated validation reports
- ✅ **CI/CD ready** - Integrates with build pipeline

### Architecture Score: 93% ✅

The codebase demonstrates excellent architectural foundations and is production ready.

---

## Quick Start

### Run Validation

```bash
# Full architecture validation
dart scripts/architecture_validation.dart

# Architecture tests only
flutter test test/architecture/

# All tests including architecture
flutter test
```

### Read Documentation

Start with these files based on your needs:

- **New to project?** → [ARCHITECTURE_SUMMARY.md](#architecture-summary)
- **Need quick reference?** → [ARCHITECTURE_QUICK_REFERENCE.md](#quick-reference)
- **Want detailed guidelines?** → [ARCHITECTURE_GUIDELINES.md](#guidelines)
- **Need validation help?** → [ARCHITECTURE_VALIDATION.md](#validation-guide)
- **Want current analysis?** → [ARCHITECTURE_ANALYSIS.md](#analysis)

---

## Documentation Index

### 1. Architecture Summary

**File:** [ARCHITECTURE_SUMMARY.md](./ARCHITECTURE_SUMMARY.md)

**Purpose:** Quick overview of architecture quality

**Contents:**
- Overall score and status
- Validation results summary
- Key metrics
- Priority actions
- Quick dos and don'ts

**When to use:** First time setup, status checks, executive summary

---

### 2. Quick Reference

**File:** [ARCHITECTURE_QUICK_REFERENCE.md](./ARCHITECTURE_QUICK_REFERENCE.md)

**Purpose:** Developer cheat sheet for daily use

**Contents:**
- Quick validation commands
- Code limits
- SOLID quick checks
- Common patterns
- Common anti-patterns
- Quick fixes

**When to use:** During development, code reviews, quick lookups

---

### 3. Architecture Guidelines

**File:** [ARCHITECTURE_GUIDELINES.md](./ARCHITECTURE_GUIDELINES.md)

**Purpose:** Complete architectural principles guide

**Contents:**
- Detailed SOLID principles with examples
- Dependency injection patterns
- State management guidelines
- Code quality standards
- Real examples from codebase
- Enforcement mechanisms
- Best practices

**When to use:** Learning the patterns, making architectural decisions, training

---

### 4. Architecture Validation Guide

**File:** [ARCHITECTURE_VALIDATION.md](./ARCHITECTURE_VALIDATION.md)

**Purpose:** Complete guide to the validation system

**Contents:**
- System components
- How to run validations
- Understanding results
- Known acceptable violations
- Fixing common violations
- Integration with workflow
- Customization guide
- Troubleshooting

**When to use:** Setting up validation, troubleshooting failures, customizing checks

---

### 5. Architecture Analysis

**File:** [ARCHITECTURE_ANALYSIS.md](./ARCHITECTURE_ANALYSIS.md)

**Purpose:** Detailed current state analysis

**Contents:**
- Executive summary
- Detailed validation results per principle
- Compliance scores
- Codebase statistics
- Dependency graphs
- Priority-ranked recommendations
- Testing strategy

**When to use:** Understanding current state, planning improvements, audits

---

### 6. Validation Report (Auto-generated)

**File:** [architecture_validation_report.md](./architecture_validation_report.md)

**Purpose:** Auto-generated validation results

**Contents:**
- SOLID principles status
- Dependency injection status
- Code quality metrics
- Complete violation list
- Generated timestamp

**When to use:** After running validation script, CI/CD reports

---

## Validation Tools

### 1. Validation Script

**Location:** `scripts/architecture_validation.dart`

**Purpose:** Automated validation of 11 architectural principles

**Usage:**
```bash
dart scripts/architecture_validation.dart
```

**Output:**
- Console summary with pass/fail status
- Detailed violation list
- Auto-generated markdown report
- Exit code (0 = pass, 1 = fail)

**Validates:**
- ✅ SOLID principles (SRP, OCP, LSP, ISP, DIP)
- ✅ Dependency injection patterns
- ✅ Single source of truth (SSOT)
- ✅ Code simplicity (KISS)
- ✅ Single level of abstraction (SLAP)
- ✅ Self-sufficient components
- ✅ Proper abstractions

---

### 2. Architecture Tests

**Location:** `test/architecture/solid_test.dart`

**Purpose:** Automated tests enforcing architectural patterns

**Usage:**
```bash
# Run architecture tests
flutter test test/architecture/

# Run specific test
flutter test test/architecture/solid_test.dart
```

**Tests:**
- File size limits (500 lines)
- Function size limits (50 lines)
- Dependency injection compliance
- Repository interfaces
- No StatefulWidget in screens
- Component self-sufficiency
- Proper abstractions

**Integration:**
- Runs with `flutter test`
- Fails build if violations found
- Provides clear error messages
- Lists all violations

---

## Current Status

### Overall Score: 93% ✅

**Status:** Production Ready

### Passing (7/11)
- ✅ Single Responsibility Principle - 100%
- ✅ Open/Closed Principle - 100%
- ✅ Interface Segregation Principle - 100%
- ✅ Dependency Inversion Principle - 100%
- ✅ Dependency Injection - 100%
- ✅ Single Source of Truth - 100%
- ✅ Self-Sufficient Components - 100%

### Needs Attention (4/11)
- ⚠️ Liskov Substitution - 96% (4 acceptable framework violations)
- ⚠️ KISS - 65% (mostly Flutter widget tree nesting)
- ⚠️ SLAP - 92% (8 long functions)
- ⚠️ Proper Abstractions - 98% (2 minor violations)

### Key Metrics
- Total Files: 120+
- Average File Size: ~150 lines
- Files > 500 lines: 0 ✅
- Service Locators: 0 ✅
- Singletons: 0 ✅ (except Firebase.instance)
- Test Coverage: 80%+ ✅

---

## For Developers

### Daily Development

1. **Before Committing**
   ```bash
   dart scripts/architecture_validation.dart
   flutter test
   ```

2. **During Development**
   - Keep [Quick Reference](./ARCHITECTURE_QUICK_REFERENCE.md) handy
   - Check file size limits (500 lines)
   - Check function size limits (50 lines)
   - Use ConsumerWidget for screens
   - Inject all dependencies

3. **Common Patterns**
   ```dart
   // ✅ Good: ConsumerWidget with DI
   class MyScreen extends ConsumerWidget {
     Widget build(BuildContext context, WidgetRef ref) {
       final state = ref.watch(myProvider);
       return MyView(state: state);
     }
   }
   ```

4. **Avoid Anti-Patterns**
   ```dart
   // ❌ Bad: StatefulWidget, service locator, singleton
   class MyScreen extends StatefulWidget { }
   final repo = GetIt.I<Repository>();
   static final instance = MyClass._();
   ```

---

## For Reviewers

### Code Review Checklist

- [ ] Architecture validation passes
- [ ] No new violations introduced
- [ ] Dependencies injected via Riverpod
- [ ] Screens use ConsumerWidget
- [ ] Functions under 50 lines
- [ ] Files under 500 lines
- [ ] Tests included
- [ ] Documentation updated if needed

### Review Process

1. **Check Validation Report**
   ```bash
   dart scripts/architecture_validation.dart
   ```

2. **Review Patterns**
   - Dependency injection used?
   - Proper layer separation?
   - Interfaces used for repositories?
   - SOLID principles followed?

3. **Check Test Coverage**
   ```bash
   flutter test --coverage
   ```

---

## For Maintainers

### Regular Maintenance

1. **Weekly Validation**
   ```bash
   dart scripts/architecture_validation.dart
   ```
   - Check for new violations
   - Track metrics over time
   - Update documentation if needed

2. **Monthly Review**
   - Review [Architecture Analysis](./ARCHITECTURE_ANALYSIS.md)
   - Update priorities
   - Plan refactoring if needed
   - Update guidelines based on lessons learned

3. **Quarterly Audit**
   - Full architecture review
   - Update documentation
   - Refine validation rules
   - Team training if needed

### Updating Validation

#### Adjust Limits

Edit `scripts/architecture_validation.dart`:

```dart
// Change limits
if (lines > 500) { }     // File size limit
if (func.lines > 50) { } // Function size limit
if (indent > 12) { }     // Nesting limit
```

#### Add New Validators

```dart
class CustomValidator implements Validator {
  @override
  String get name => 'Custom Validation';

  @override
  Future<ValidationResult> validate() async {
    // Your validation logic
    return ValidationResult(name, violations);
  }
}
```

#### Update Documentation

When architecture patterns change:

1. Update [Guidelines](./ARCHITECTURE_GUIDELINES.md)
2. Update [Analysis](./ARCHITECTURE_ANALYSIS.md)
3. Update [Quick Reference](./ARCHITECTURE_QUICK_REFERENCE.md)
4. Run validation and commit report

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Architecture Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2

      - name: Install dependencies
        run: flutter pub get

      - name: Architecture Validation
        run: dart scripts/architecture_validation.dart

      - name: Architecture Tests
        run: flutter test test/architecture/

      - name: All Tests
        run: flutter test --coverage

      - name: Upload Report
        uses: actions/upload-artifact@v2
        with:
          name: architecture-report
          path: docs/architecture_validation_report.md
```

---

## Troubleshooting

### Common Issues

**Issue:** Tests fail locally but pass in CI

**Solution:**
```bash
flutter clean
flutter pub get
flutter test
```

**Issue:** Too many widget nesting violations

**Solution:** These are mostly acceptable Flutter patterns. Extract complex widgets:
```dart
Widget _buildComplexSection() {
  return Container(...);
}
```

**Issue:** LSP violations in providers

**Solution:** These are acceptable Riverpod StateNotifier patterns. Document as known exceptions.

---

## Getting Help

1. **Read Documentation** - Check relevant guide above
2. **Check Examples** - Look at existing code patterns
3. **Review Guidelines** - Consult [Architecture Guidelines](./ARCHITECTURE_GUIDELINES.md)
4. **Ask in Code Review** - Discuss with team
5. **Update Documentation** - Improve docs when you find gaps

---

## Contributing

### Adding Documentation

1. Create new doc following existing format
2. Add to this index
3. Cross-reference from other docs
4. Update quick reference if applicable

### Improving Validation

1. Test changes locally
2. Update validation script
3. Run full test suite
4. Update documentation
5. Submit PR with rationale

### Reporting Issues

Include in issue:
- Which validation/test failed
- Error message
- File and line number
- Expected vs actual behavior
- Suggested fix if applicable

---

## Version History

### v1.0 (2026-01-30)
- Initial architecture validation system
- 11 automated validators
- Complete documentation suite
- Architecture tests
- Integration with workflow

---

## Resources

### External Resources
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [Riverpod Documentation](https://riverpod.dev/)
- [Flutter Best Practices](https://flutter.dev/docs/development/best-practices)

### Internal Resources
- Architecture Guidelines
- Architecture Analysis
- Quick Reference
- Validation Guide

---

## Quick Links

| Document | Purpose | When to Use |
|----------|---------|-------------|
| [Summary](./ARCHITECTURE_SUMMARY.md) | Overview | Status checks |
| [Quick Reference](./ARCHITECTURE_QUICK_REFERENCE.md) | Cheat sheet | Daily development |
| [Guidelines](./ARCHITECTURE_GUIDELINES.md) | Complete guide | Learning, decisions |
| [Validation](./ARCHITECTURE_VALIDATION.md) | System guide | Setup, troubleshooting |
| [Analysis](./ARCHITECTURE_ANALYSIS.md) | Current state | Planning, audits |
| [Report](./architecture_validation_report.md) | Latest results | After validation |

---

**Last Updated:** 2026-01-30
**System Version:** 1.0
**Status:** Active
