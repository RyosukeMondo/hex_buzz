import 'dart:io';

/// Pre-commit hook script for code quality enforcement.
///
/// Checks:
/// - File size ≤ 500 lines of code (excluding comments and blank lines)
/// - Function size ≤ 50 lines of code
void main(List<String> args) {
  final exitCode = runChecks();
  exit(exitCode);
}

int runChecks() {
  final libDir = Directory('lib');
  final testDir = Directory('test');

  if (!libDir.existsSync()) {
    stderr.writeln('Error: lib directory not found');
    return 1;
  }

  final violations = <String>[];

  for (final dir in [libDir, if (testDir.existsSync()) testDir]) {
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in files) {
      final fileViolations = checkFile(file);
      violations.addAll(fileViolations);
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln(
      'Pre-commit check failed with ${violations.length} '
      'violation(s):\n',
    );
    for (final v in violations) {
      stderr.writeln('  ✗ $v');
    }
    stderr.writeln('\nPlease fix the violations before committing.');
    return 1;
  }

  stdout.writeln('✓ Pre-commit checks passed');
  return 0;
}

List<String> checkFile(File file) {
  final violations = <String>[];
  final lines = file.readAsLinesSync();
  final relativePath = file.path;
  final isTestFile =
      relativePath.contains('/test/') || relativePath.contains('_test.dart');

  // Check file size (excluding comments and blank lines)
  final codeLines = countCodeLines(lines);
  if (codeLines > 500) {
    violations.add(
      '$relativePath: File has $codeLines lines of code '
      '(max 500)',
    );
  }

  // Check function sizes (skip test files - they have naturally large blocks)
  if (!isTestFile) {
    final functionViolations = checkFunctionSizes(lines, relativePath);
    violations.addAll(functionViolations);
  }

  return violations;
}

/// Counts lines of code, excluding blank lines and comments.
int countCodeLines(List<String> lines) {
  var count = 0;
  var inMultiLineComment = false;

  for (final line in lines) {
    final trimmed = line.trim();

    // Handle multi-line comments
    if (inMultiLineComment) {
      if (trimmed.contains('*/')) {
        inMultiLineComment = false;
      }
      continue;
    }

    if (trimmed.startsWith('/*')) {
      if (!trimmed.contains('*/')) {
        inMultiLineComment = true;
      }
      continue;
    }

    // Skip blank lines
    if (trimmed.isEmpty) continue;

    // Skip single-line comments
    if (trimmed.startsWith('//')) continue;

    // Skip doc comments
    if (trimmed.startsWith('///')) continue;

    count++;
  }

  return count;
}

/// Checks all functions/methods for size violations.
List<String> checkFunctionSizes(List<String> lines, String filePath) {
  final violations = <String>[];
  final functions = findFunctions(lines);

  for (final func in functions) {
    final codeLines = countCodeLinesInRange(
      lines,
      func.startLine,
      func.endLine,
    );
    if (codeLines > 50) {
      violations.add(
        '$filePath:${func.startLine + 1}: Function '
        '"${func.name}" has $codeLines lines of code (max 50)',
      );
    }
  }

  return violations;
}

/// Finds all function/method definitions and their line ranges.
List<FunctionInfo> findFunctions(List<String> lines) {
  final functions = <FunctionInfo>[];
  final functionPattern = RegExp(
    r'^\s*'
    r'(?:static\s+)?'
    r'(?:async\s+)?'
    r'(?:[\w<>,\s\?]+\s+)?'
    r'([\w]+)\s*'
    r'(?:<[^>]+>)?'
    r'\s*\([^)]*\)\s*'
    r'(?:async\s*)?'
    r'(?:{\s*)?$',
  );

  // Also match arrow functions and getters/setters
  final arrowPattern = RegExp(
    r'^\s*'
    r'(?:static\s+)?'
    r'(?:[\w<>,\s\?]+\s+)?'
    r'(?:get\s+|set\s+)?'
    r'([\w]+)\s*'
    r'(?:<[^>]+>)?'
    r'\s*(?:\([^)]*\))?\s*'
    r'=>',
  );

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();

    // Skip empty lines and comments
    if (trimmed.isEmpty ||
        trimmed.startsWith('//') ||
        trimmed.startsWith('/*') ||
        trimmed.startsWith('///') ||
        trimmed.startsWith('*')) {
      continue;
    }

    // Check for function declaration
    var match = functionPattern.firstMatch(line);
    if (match != null) {
      final name = match.group(1) ?? 'anonymous';
      // Skip class declarations and constructors
      if (_isClassOrConstructor(trimmed)) continue;

      final endLine = findMatchingBrace(lines, i);
      if (endLine > i) {
        functions.add(FunctionInfo(name: name, startLine: i, endLine: endLine));
      }
      continue;
    }

    // Check for arrow functions (single line, skip them as they're short)
    match = arrowPattern.firstMatch(line);
    if (match != null && !_isClassOrConstructor(trimmed)) {
      // Arrow functions on single line are fine, multi-line need checking
      if (!line.contains(';')) {
        final name = match.group(1) ?? 'anonymous';
        var endLine = i;
        // Find the semicolon
        for (var j = i; j < lines.length; j++) {
          if (lines[j].contains(';')) {
            endLine = j;
            break;
          }
        }
        if (endLine > i) {
          functions.add(
            FunctionInfo(name: name, startLine: i, endLine: endLine),
          );
        }
      }
    }
  }

  return functions;
}

bool _isClassOrConstructor(String line) {
  return line.startsWith('class ') ||
      line.startsWith('abstract class ') ||
      line.startsWith('mixin ') ||
      line.startsWith('extension ') ||
      line.startsWith('enum ') ||
      line.contains(' factory ');
}

/// Finds the line number of the closing brace matching the opening brace.
int findMatchingBrace(List<String> lines, int startLine) {
  var braceCount = 0;
  var foundOpenBrace = false;

  for (var i = startLine; i < lines.length; i++) {
    final line = lines[i];

    for (var j = 0; j < line.length; j++) {
      final char = line[j];

      // Skip strings
      if (char == '"' || char == "'") {
        final quote = char;
        j++;
        while (j < line.length && line[j] != quote) {
          if (line[j] == '\\') j++;
          j++;
        }
        continue;
      }

      if (char == '{') {
        braceCount++;
        foundOpenBrace = true;
      } else if (char == '}') {
        braceCount--;
        if (foundOpenBrace && braceCount == 0) {
          return i;
        }
      }
    }
  }

  return startLine;
}

/// Counts code lines in a range, excluding comments and blank lines.
int countCodeLinesInRange(List<String> lines, int start, int end) {
  if (start >= lines.length || end >= lines.length || start > end) {
    return 0;
  }
  return countCodeLines(lines.sublist(start, end + 1));
}

class FunctionInfo {
  final String name;
  final int startLine;
  final int endLine;

  FunctionInfo({
    required this.name,
    required this.startLine,
    required this.endLine,
  });
}
