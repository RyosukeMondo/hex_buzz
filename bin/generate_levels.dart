import 'dart:convert';
import 'dart:io';

import '../lib/domain/services/level_generator.dart';

/// Generates pre-built levels and saves them to assets.
void main(List<String> args) async {
  final generator = LevelGenerator();

  // Configuration: how many levels per size
  // Size 3: ~0.5s per level, Size 4: slower but feasible for 100 levels
  final config = {
    3: 100, // 100 levels of size 3 (19 cells, easier)
    4: 100, // 100 levels of size 4 (37 cells, medium difficulty)
  };

  final levels = <Map<String, dynamic>>[];
  var totalGenerated = 0;

  for (final entry in config.entries) {
    final size = entry.key;
    final count = entry.value;

    stderr.writeln('Generating $count levels of size $size...');

    for (var i = 0; i < count; i++) {
      final result = generator.generate(size);
      if (result.success) {
        levels.add(result.level!.toJson());
        totalGenerated++;
        if ((i + 1) % 10 == 0) {
          stderr.writeln('  Generated ${i + 1}/$count');
        }
      } else {
        stderr.writeln('  Failed to generate level ${i + 1}: ${result.error}');
        i--; // Retry
      }
    }
  }

  // Output JSON
  final output = {
    'version': 1,
    'generatedAt': DateTime.now().toIso8601String(),
    'counts': config.map((k, v) => MapEntry(k.toString(), v)),
    'levels': levels,
  };

  final outputPath = 'assets/levels/pregenerated.json';
  final file = File(outputPath);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(output));

  stderr.writeln('\nGenerated $totalGenerated levels to $outputPath');
}
