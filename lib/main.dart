import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/local/local_progress_repository.dart';
import 'debug/api/server.dart';
import 'domain/data/test_level.dart';
import 'domain/models/game_mode.dart';
import 'domain/services/game_engine.dart';
import 'domain/services/level_repository.dart';
import 'presentation/providers/game_provider.dart';
import 'presentation/providers/progress_provider.dart';
import 'presentation/screens/level_select/level_select_screen.dart';
import 'presentation/theme/honey_theme.dart';

/// Whether to enable the debug API server.
///
/// Set via --dart-define=ENABLE_API=true or defaults to true in debug mode.
const bool _enableApiFromEnv = bool.fromEnvironment(
  'ENABLE_API',
  defaultValue: false,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-load level repository for instant level switching
  final levelRepository = LevelRepository();
  try {
    await levelRepository.load();
    if (kDebugMode) {
      debugPrint('Loaded pre-generated levels:');
      for (final size in levelRepository.availableSizes) {
        debugPrint(
          '  Size $size: ${levelRepository.getLevelCount(size)} levels',
        );
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Failed to load pre-generated levels: $e');
      debugPrint('Will use dynamic generation as fallback.');
    }
  }

  // Initialize progress repository for player progress persistence
  final prefs = await SharedPreferences.getInstance();
  final progressRepository = LocalProgressRepository(prefs);
  if (kDebugMode) {
    debugPrint('Progress repository initialized');
  }

  // Start debug API server if enabled and in debug mode
  DebugApiServer? apiServer;
  if (kDebugMode && _enableApiFromEnv) {
    apiServer = await _startDebugApiServer();
  }

  runApp(
    ProviderScope(
      overrides: [
        levelRepositoryProvider.overrideWithValue(levelRepository),
        progressRepositoryProvider.overrideWithValue(progressRepository),
        if (apiServer != null)
          debugApiServerProvider.overrideWithValue(apiServer),
      ],
      child: const HoneycombApp(),
    ),
  );
}

/// Starts the debug API server on port 8080.
///
/// Creates a dedicated [GameEngine] instance for API interactions.
/// Only available in debug builds.
Future<DebugApiServer> _startDebugApiServer() async {
  final level = getTestLevel();
  final engine = GameEngine(level: level, mode: GameMode.practice);

  final server = await startServer(8080, engine);

  if (kDebugMode) {
    debugPrint('Debug API server started at http://localhost:8080');
    debugPrint('Available endpoints:');
    debugPrint('  GET  /api/health - Health check');
    debugPrint('  GET  /api/game/state - Get current game state');
    debugPrint('  POST /api/game/move - Make a move {q, r}');
    debugPrint('  POST /api/game/reset - Reset the game');
    debugPrint('  POST /api/level/validate - Validate a level');
  }

  return server;
}

/// Provider for the debug API server (available only in debug mode with ENABLE_API).
final debugApiServerProvider = Provider<DebugApiServer?>((ref) => null);

class HoneycombApp extends StatelessWidget {
  const HoneycombApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Honeycomb One Pass',
      theme: HoneyTheme.lightTheme,
      home: const LevelSelectScreen(),
    );
  }
}
