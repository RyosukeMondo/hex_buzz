import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SOLID Principles', () {
    group('Single Responsibility Principle', () {
      test('all files are under 500 lines', () {
        final files = _getDartFiles('lib');
        final violations = <String>[];

        for (final file in files) {
          final lines = _countLines(file);
          if (lines > 500) {
            violations.add('${file.path}: $lines lines (max 500)');
          }
        }

        expect(
          violations,
          isEmpty,
          reason: 'Files exceed 500 lines:\n${violations.join('\n')}',
        );
      });

      test('classes have max 10 dependencies', () {
        final files = _getDartFiles('lib');
        final violations = <String>[];

        for (final file in files) {
          final content = file.readAsStringSync();
          final dependencies = _countDependencies(content);
          if (dependencies > 10) {
            violations.add('${file.path}: $dependencies dependencies (max 10)');
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'Classes have too many dependencies:\n${violations.join('\n')}',
        );
      });
    });

    group('Open/Closed Principle', () {
      test('all repositories implement interfaces', () {
        final repoFiles = _getDartFiles(
          'lib/data',
        ).where((f) => f.path.endsWith('_repository.dart'));
        final violations = <String>[];

        for (final file in repoFiles) {
          final content = file.readAsStringSync();
          if (!content.contains('implements') &&
              !content.contains('abstract')) {
            violations.add('${file.path}: Does not implement an interface');
          }
        }

        expect(
          violations,
          isEmpty,
          reason: 'Repositories without interfaces:\n${violations.join('\n')}',
        );
      });

      test('no type-based switch statements', () {
        final files = _getDartFiles('lib');
        final violations = <String>[];

        for (final file in files) {
          final content = file.readAsStringSync();
          if (RegExp(r'if.*is\s+\w+.*else\s+if.*is\s+\w+').hasMatch(content)) {
            violations.add(
              '${file.path}: Uses type-based conditionals (use polymorphism)',
            );
          }
        }

        expect(
          violations,
          isEmpty,
          reason: 'Type-based conditionals found:\n${violations.join('\n')}',
        );
      });
    });

    group('Liskov Substitution Principle', () {
      test('no override methods throw UnimplementedError', () {
        final files = _getDartFiles('lib');
        final violations = <String>[];

        for (final file in files) {
          final content = file.readAsStringSync();
          if (content.contains('@override') &&
              content.contains('throw UnimplementedError')) {
            violations.add('${file.path}: Override throws UnimplementedError');
          }
        }

        expect(
          violations,
          isEmpty,
          reason: 'LSP violations found:\n${violations.join('\n')}',
        );
      });
    });

    group('Interface Segregation Principle', () {
      test('interfaces have max 15 methods', () {
        final files = _getDartFiles('lib/domain');
        final violations = <String>[];

        for (final file in files) {
          final content = file.readAsStringSync();
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

        expect(
          violations,
          isEmpty,
          reason: 'Fat interfaces found:\n${violations.join('\n')}',
        );
      });
    });

    group('Dependency Inversion Principle', () {
      test('presentation layer does not import Firebase directly', () {
        final presentationFiles = _getDartFiles('lib/presentation');
        final violations = <String>[];

        for (final file in presentationFiles) {
          final content = file.readAsStringSync();

          if (content.contains("import 'package:firebase_")) {
            violations.add('${file.path}: Imports Firebase directly');
          }
        }

        expect(
          violations,
          isEmpty,
          reason: 'Firebase imports in presentation:\n${violations.join('\n')}',
        );
      });

      test('presentation layer does not instantiate repositories', () {
        final presentationFiles = _getDartFiles('lib/presentation');
        final violations = <String>[];

        for (final file in presentationFiles) {
          final content = file.readAsStringSync();

          if (RegExp(r'Firebase\w+Repository\(\)').hasMatch(content)) {
            violations.add(
              '${file.path}: Instantiates Firebase repository directly',
            );
          }
        }

        expect(
          violations,
          isEmpty,
          reason: 'Direct repository instantiation:\n${violations.join('\n')}',
        );
      });
    });
  });

  group('Dependency Injection', () {
    test('no service locators used', () {
      final files = _getDartFiles('lib');
      final violations = <String>[];

      for (final file in files) {
        final content = file.readAsStringSync();

        if (content.contains('GetIt.I<') || content.contains('locator<')) {
          violations.add('${file.path}: Uses service locator pattern');
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Service locators found:\n${violations.join('\n')}',
      );
    });

    test('no singletons except Firebase.instance', () {
      final files = _getDartFiles('lib');
      final violations = <String>[];

      for (final file in files) {
        final content = file.readAsStringSync();

        if (RegExp(r'static final \w+ instance\s*=').hasMatch(content) &&
            !file.path.contains('firebase_options.dart')) {
          violations.add('${file.path}: Uses singleton pattern');
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Singletons found:\n${violations.join('\n')}',
      );
    });
  });

  group('SSOT (Single Source of Truth)', () {
    test('screens use ConsumerWidget, not StatefulWidget', () {
      final screenFiles = _getDartFiles('lib/presentation/screens');
      final violations = <String>[];

      for (final file in screenFiles) {
        final content = file.readAsStringSync();
        if (content.contains('extends StatefulWidget')) {
          violations.add(
            '${file.path}: Uses StatefulWidget (use ConsumerWidget)',
          );
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'StatefulWidget in screens:\n${violations.join('\n')}',
      );
    });
  });

  group('Code Complexity', () {
    test('functions are max 50 lines', () {
      final files = _getDartFiles('lib');
      final violations = <String>[];

      for (final file in files) {
        final content = file.readAsStringSync();
        final functions = _extractFunctions(content);

        for (final func in functions) {
          if (func.lines > 50) {
            violations.add(
              '${file.path}:${func.name}: ${func.lines} lines (max 50)',
            );
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Long functions found:\n${violations.join('\n')}',
      );
    });

    test('nesting depth is max 6 levels (12 spaces)', () {
      final files = _getDartFiles('lib');
      final violations = <String>[];

      for (final file in files) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final indent = line.length - line.trimLeft().length;

          // More than 6 levels of indentation (12 spaces)
          if (indent > 12 && line.trim().isNotEmpty) {
            violations.add(
              '${file.path}:${i + 1}: Deep nesting ($indent spaces)',
            );
            // Only report first 10 violations per file
            if (violations.where((v) => v.startsWith(file.path)).length >= 10) {
              break;
            }
          }
        }
      }

      expect(
        violations.length,
        lessThan(10),
        reason:
            'Deep nesting found (showing first 10):\n${violations.take(10).join('\n')}',
      );
    });
  });

  group('Component Design', () {
    test('widgets do not assume pre-loaded data', () {
      final widgetFiles = _getDartFiles('lib/presentation/widgets');
      final violations = <String>[];

      for (final file in widgetFiles) {
        final content = file.readAsStringSync();

        // Check for direct cache access without null safety
        if (RegExp(r'ref\.watch\(\w+\)\[\w+\](?!\?)').hasMatch(content)) {
          violations.add('${file.path}: Accesses cache without null safety');
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Unsafe cache access:\n${violations.join('\n')}',
      );
    });

    test('no dynamic with type checking', () {
      final files = _getDartFiles('lib');
      final violations = <String>[];

      for (final file in files) {
        final content = file.readAsStringSync();

        if (content.contains('dynamic ') &&
            RegExp(r'if.*is\s+\w+').hasMatch(content)) {
          violations.add('${file.path}: Uses dynamic with type checking');
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Dynamic type checking:\n${violations.join('\n')}',
      );
    });
  });
}

// ============================================================================
// Utilities
// ============================================================================

List<File> _getDartFiles(String path) {
  final dir = Directory(path);
  if (!dir.existsSync()) return [];

  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();
}

int _countLines(File file) {
  final content = file.readAsStringSync();
  return content.split('\n').where((line) {
    final trimmed = line.trim();
    return trimmed.isNotEmpty &&
        !trimmed.startsWith('//') &&
        !trimmed.startsWith('/*') &&
        !trimmed.startsWith('*');
  }).length;
}

int _countDependencies(String content) {
  final matches = RegExp(
    r'final\s+\w+Repository|final\s+\w+Service',
  ).allMatches(content);
  return matches.length;
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

class FunctionInfo {
  final String name;
  final int lines;

  FunctionInfo(this.name, this.lines);
}
