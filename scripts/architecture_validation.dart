#!/usr/bin/env dart
// Architecture Validation Script
// Validates SOLID principles, DI patterns, and architectural guidelines

import 'dart:io';

void main() async {
  print('🏗️  Architecture Validation\n');

  final validators = [
    SRPValidator(),
    OCPValidator(),
    LSPValidator(),
    ISPValidator(),
    DIPValidator(),
    DIValidator(),
    SSOTValidator(),
    KISSValidator(),
    SLAPValidator(),
    SelfSufficientValidator(),
    AbstractionValidator(),
  ];

  final results = <ValidationResult>[];

  for (final validator in validators) {
    print('Running ${validator.name}...');
    final result = await validator.validate();
    results.add(result);
    _printResult(result);
    print('');
  }

  _printSummary(results);
  _generateReport(results);

  // Exit with error if any violations found
  final totalViolations = results.fold<int>(
    0,
    (sum, r) => sum + r.violations.length,
  );
  exit(totalViolations > 0 ? 1 : 0);
}

void _printResult(ValidationResult result) {
  if (result.passed) {
    print('✅ ${result.name}: PASS');
  } else {
    print('❌ ${result.name}: FAIL (${result.violations.length} violations)');
    for (final violation in result.violations) {
      print('   - $violation');
    }
  }
}

void _printSummary(List<ValidationResult> results) {
  print('=' * 80);
  print('SUMMARY');
  print('=' * 80);

  final passed = results.where((r) => r.passed).length;
  final failed = results.length - passed;
  final totalViolations = results.fold<int>(
    0,
    (sum, r) => sum + r.violations.length,
  );

  print('Tests: ${results.length}');
  print('Passed: $passed ✅');
  print('Failed: $failed ❌');
  print('Violations: $totalViolations');
  print('');

  if (totalViolations == 0) {
    print('🎉 All architecture validations passed!');
  } else {
    print('⚠️  Architecture violations found. Please fix before committing.');
  }
}

void _generateReport(List<ValidationResult> results) {
  final report = StringBuffer();
  report.writeln('# Architecture Validation Report');
  report.writeln('');
  report.writeln('Generated: ${DateTime.now()}');
  report.writeln('');

  // SOLID Principles
  report.writeln('## SOLID Principles');
  report.writeln('');
  _addSectionResults(report, results, [
    'Single Responsibility Principle',
    'Open/Closed Principle',
    'Liskov Substitution Principle',
    'Interface Segregation Principle',
    'Dependency Inversion Principle',
  ]);

  // Dependency Injection
  report.writeln('## Dependency Injection');
  report.writeln('');
  _addSectionResults(report, results, ['Dependency Injection']);

  // Code Quality
  report.writeln('## Code Quality');
  report.writeln('');
  _addSectionResults(report, results, ['SSOT', 'KISS', 'SLAP']);

  // Component Design
  report.writeln('## Component Design');
  report.writeln('');
  _addSectionResults(report, results, [
    'Self-Sufficient Components',
    'Proper Abstractions',
  ]);

  // Violations
  final totalViolations = results.fold<int>(
    0,
    (sum, r) => sum + r.violations.length,
  );
  report.writeln('## Violations: $totalViolations');
  report.writeln('');

  for (final result in results.where((r) => !r.passed)) {
    report.writeln('### ${result.name}');
    for (final violation in result.violations) {
      report.writeln('- $violation');
    }
    report.writeln('');
  }

  // Write report
  final reportFile = File('docs/architecture_validation_report.md');
  reportFile.parent.createSync(recursive: true);
  reportFile.writeAsStringSync(report.toString());
  print('📄 Report generated: ${reportFile.path}');
}

void _addSectionResults(
  StringBuffer report,
  List<ValidationResult> results,
  List<String> names,
) {
  for (final name in names) {
    final result = results.firstWhere((r) => r.name == name);
    final status = result.passed ? '✅ PASS' : '❌ FAIL';
    report.writeln('- $name: $status');
  }
  report.writeln('');
}

// ============================================================================
// Validators
// ============================================================================

abstract class Validator {
  String get name;
  Future<ValidationResult> validate();
}

class ValidationResult {
  final String name;
  final List<String> violations;

  ValidationResult(this.name, this.violations);

  bool get passed => violations.isEmpty;
}

// ============================================================================
// SRP Validator
// ============================================================================

class SRPValidator implements Validator {
  @override
  String get name => 'Single Responsibility Principle';

  @override
  Future<ValidationResult> validate() async {
    final violations = <String>[];

    // Check for large files (potential SRP violations)
    final files = await _getDartFiles('lib');
    for (final file in files) {
      final lines = await _countLines(file);
      if (lines > 500) {
        violations.add('${file.path}: $lines lines (max 500)');
      }
    }

    // Check for classes with too many dependencies
    for (final file in files) {
      final content = await file.readAsString();
      final dependencies = _countDependencies(content);
      if (dependencies > 10) {
        violations.add('${file.path}: $dependencies dependencies (max 10)');
      }
    }

    return ValidationResult(name, violations);
  }

  int _countDependencies(String content) {
    final matches = RegExp(
      r'final\s+\w+Repository|final\s+\w+Service',
    ).allMatches(content);
    return matches.length;
  }
}

// ============================================================================
// OCP Validator
// ============================================================================

class OCPValidator implements Validator {
  @override
  String get name => 'Open/Closed Principle';

  @override
  Future<ValidationResult> validate() async {
    final violations = <String>[];

    // Check that repositories use interfaces
    final repoFiles = await _getDartFiles('lib/data');
    for (final file in repoFiles) {
      if (!file.path.endsWith('_repository.dart')) continue;

      final content = await file.readAsString();
      if (!content.contains('implements') && !content.contains('abstract')) {
        violations.add(
          '${file.path}: Repository does not implement an interface',
        );
      }
    }

    // Check for type-based switch statements (OCP violation)
    final allFiles = await _getDartFiles('lib');
    for (final file in allFiles) {
      final content = await file.readAsString();
      if (RegExp(r'if.*is\s+\w+.*else\s+if.*is\s+\w+').hasMatch(content)) {
        violations.add(
          '${file.path}: Contains type-based conditionals (use polymorphism)',
        );
      }
    }

    return ValidationResult(name, violations);
  }
}

// ============================================================================
// LSP Validator
// ============================================================================

class LSPValidator implements Validator {
  @override
  String get name => 'Liskov Substitution Principle';

  @override
  Future<ValidationResult> validate() async {
    final violations = <String>[];

    // Check for override methods that throw NotImplementedError
    final files = await _getDartFiles('lib');
    for (final file in files) {
      final content = await file.readAsString();
      if (content.contains('@override') &&
          content.contains('throw UnimplementedError')) {
        violations.add(
          '${file.path}: Override throws UnimplementedError (LSP violation)',
        );
      }
    }

    return ValidationResult(name, violations);
  }
}

// ============================================================================
// ISP Validator
// ============================================================================

class ISPValidator implements Validator {
  @override
  String get name => 'Interface Segregation Principle';

  @override
  Future<ValidationResult> validate() async {
    final violations = <String>[];

    // Check for fat interfaces (many methods)
    final files = await _getDartFiles('lib/domain');
    for (final file in files) {
      final content = await file.readAsString();
      if (content.contains('abstract class')) {
        final methods = RegExp(
          r'^\s+Future<|^\s+\w+\s+\w+\(',
          multiLine: true,
        ).allMatches(content).length;
        if (methods > 15) {
          violations.add(
            '${file.path}: Interface has $methods methods (max 15)',
          );
        }
      }
    }

    return ValidationResult(name, violations);
  }
}

// ============================================================================
// DIP Validator
// ============================================================================

class DIPValidator implements Validator {
  @override
  String get name => 'Dependency Inversion Principle';

  @override
  Future<ValidationResult> validate() async {
    final violations = <String>[];

    // Check presentation layer doesn't depend on concrete implementations
    final presentationFiles = await _getDartFiles('lib/presentation');
    for (final file in presentationFiles) {
      final content = await file.readAsString();

      // Check for Firebase imports
      if (content.contains("import 'package:firebase_")) {
        violations.add(
          '${file.path}: Imports Firebase directly (use repository)',
        );
      }

      // Check for direct instantiation of repositories
      if (RegExp(r'Firebase\w+Repository\(\)').hasMatch(content)) {
        violations.add(
          '${file.path}: Instantiates Firebase repository directly',
        );
      }
    }

    return ValidationResult(name, violations);
  }
}

// ============================================================================
// DI Validator
// ============================================================================

class DIValidator implements Validator {
  @override
  String get name => 'Dependency Injection';

  @override
  Future<ValidationResult> validate() async {
    final violations = <String>[];

    final files = await _getDartFiles('lib');
    for (final file in files) {
      final content = await file.readAsString();

      // Check for service locators
      if (content.contains('GetIt.I<') || content.contains('locator<')) {
        violations.add('${file.path}: Uses service locator pattern');
      }

      // Check for singletons (except Firebase.instance)
      if (RegExp(r'static final \w+ instance\s*=').hasMatch(content) &&
          !file.path.contains('firebase_options.dart')) {
        violations.add('${file.path}: Uses singleton pattern');
      }
    }

    return ValidationResult(name, violations);
  }
}

// ============================================================================
// SSOT Validator
// ============================================================================

class SSOTValidator implements Validator {
  @override
  String get name => 'SSOT';

  @override
  Future<ValidationResult> validate() async {
    final violations = <String>[];

    // Check for StatefulWidget in presentation layer (should use ConsumerWidget)
    final screenFiles = await _getDartFiles('lib/presentation/screens');
    for (final file in screenFiles) {
      final content = await file.readAsString();
      if (content.contains('extends StatefulWidget')) {
        violations.add(
          '${file.path}: Uses StatefulWidget (use ConsumerWidget for SSOT)',
        );
      }
    }

    return ValidationResult(name, violations);
  }
}

// ============================================================================
// KISS Validator
// ============================================================================

class KISSValidator implements Validator {
  @override
  String get name => 'KISS';

  @override
  Future<ValidationResult> validate() async {
    final violations = <String>[];

    // Check for deeply nested code
    final files = await _getDartFiles('lib');
    for (final file in files) {
      final content = await file.readAsString();
      final lines = content.split('\n');

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final indent = line.length - line.trimLeft().length;

        // More than 6 levels of indentation (12 spaces)
        if (indent > 12 && line.trim().isNotEmpty) {
          violations.add(
            '${file.path}:${i + 1}: Deep nesting ($indent spaces)',
          );
        }
      }
    }

    return ValidationResult(name, violations);
  }
}

// ============================================================================
// SLAP Validator
// ============================================================================

class SLAPValidator implements Validator {
  @override
  String get name => 'SLAP';

  @override
  Future<ValidationResult> validate() async {
    final violations = <String>[];

    // Check for long functions (> 50 lines)
    final files = await _getDartFiles('lib');
    for (final file in files) {
      final content = await file.readAsString();
      final functions = _extractFunctions(content);

      for (final func in functions) {
        if (func.lines > 50) {
          violations.add(
            '${file.path}:${func.name}: ${func.lines} lines (max 50)',
          );
        }
      }
    }

    return ValidationResult(name, violations);
  }

  List<FunctionInfo> _extractFunctions(String content) {
    final functions = <FunctionInfo>[];
    final lines = content.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Match function declarations
      if (RegExp(r'^(Future<\w+>|void|bool|\w+)\s+\w+\(').hasMatch(line)) {
        final name = RegExp(r'\s+(\w+)\(').firstMatch(line)?.group(1) ?? '';
        var lineCount = 1;
        var braceCount = line.split('{').length - line.split('}').length;

        for (var j = i + 1; j < lines.length && braceCount > 0; j++) {
          lineCount++;
          final nextLine = lines[j];
          braceCount += nextLine.split('{').length - nextLine.split('}').length;
        }

        functions.add(FunctionInfo(name, lineCount));
      }
    }

    return functions;
  }
}

class FunctionInfo {
  final String name;
  final int lines;

  FunctionInfo(this.name, this.lines);
}

// ============================================================================
// Self-Sufficient Validator
// ============================================================================

class SelfSufficientValidator implements Validator {
  @override
  String get name => 'Self-Sufficient Components';

  @override
  Future<ValidationResult> validate() async {
    final violations = <String>[];

    // Check for widgets that assume pre-loaded data
    final widgetFiles = await _getDartFiles('lib/presentation/widgets');
    for (final file in widgetFiles) {
      final content = await file.readAsString();

      // Check for direct cache access without null safety
      if (RegExp(r'ref\.watch\(\w+\)\[\w+\](?!\?)').hasMatch(content)) {
        violations.add('${file.path}: Accesses cache without null safety');
      }
    }

    return ValidationResult(name, violations);
  }
}

// ============================================================================
// Abstraction Validator
// ============================================================================

class AbstractionValidator implements Validator {
  @override
  String get name => 'Proper Abstractions';

  @override
  Future<ValidationResult> validate() async {
    final violations = <String>[];

    // Check for functions accepting dynamic with type checking
    final files = await _getDartFiles('lib');
    for (final file in files) {
      final content = await file.readAsString();

      // Check for dynamic parameters with type checks
      if (content.contains('dynamic ') &&
          RegExp(r'if.*is\s+\w+').hasMatch(content)) {
        violations.add(
          '${file.path}: Uses dynamic with type checking (use proper abstraction)',
        );
      }
    }

    return ValidationResult(name, violations);
  }
}

// ============================================================================
// Utilities
// ============================================================================

Future<List<File>> _getDartFiles(String path) async {
  final dir = Directory(path);
  if (!await dir.exists()) return [];

  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();
}

Future<int> _countLines(File file) async {
  final content = await file.readAsString();
  return content.split('\n').where((line) {
    final trimmed = line.trim();
    return trimmed.isNotEmpty &&
        !trimmed.startsWith('//') &&
        !trimmed.startsWith('/*') &&
        !trimmed.startsWith('*');
  }).length;
}
