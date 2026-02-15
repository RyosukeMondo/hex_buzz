import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tests that ensure the app doesn't use dart:io APIs that crash on web.
///
/// These tests scan source files for patterns known to break web deployments.
/// This prevents regressions like the stdout crash (dart:io unavailable in browser).
void main() {
  group('Web compatibility', () {
    test('no dart:io imports in non-platform lib code', () {
      // Files allowed to use dart:io (platform-specific, debug-only, or guarded by kDebugMode)
      final allowedPaths = [
        'lib/debug/',
        'lib/platform/',
        'lib/data/local/file_',
        'lib/presentation/providers/notification_provider.dart', // guarded by kIsWeb
      ];

      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !allowedPaths.any((p) => f.path.contains(p)));

      final violations = <String>[];
      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        if (content.contains("import 'dart:io'") ||
            content.contains('import "dart:io"')) {
          violations.add(file.path);
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'These files import dart:io which crashes on web:\n'
            '${violations.join('\n')}\n'
            'Use conditional imports or platform-safe alternatives.',
      );
    });

    test('no direct FirebaseFirestore.instance in presentation layer', () {
      final presentationDir = Directory('lib/presentation');
      if (!presentationDir.existsSync()) return;

      final dartFiles = presentationDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violations = <String>[];
      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        if (content.contains('FirebaseFirestore.instance')) {
          violations.add(file.path);
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'These presentation files bypass DI with direct Firestore access:\n'
            '${violations.join('\n')}\n'
            'Use repository pattern via Riverpod providers instead.',
      );
    });

    test('no catchError handlers that rethrow', () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violations = <String>[];
      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        // Match catchError handlers that throw inside
        final pattern = RegExp(r'\.catchError\([^)]*throw\b');
        if (pattern.hasMatch(content)) {
          violations.add(file.path);
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'These files have catchError handlers that rethrow errors:\n'
            '${violations.join('\n')}\n'
            'catchError should swallow errors or use proper error handling.',
      );
    });
  });
}
