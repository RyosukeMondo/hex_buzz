import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/local/local_auth_repository.dart';
import 'data/local/local_progress_repository.dart';
import 'debug/api/server.dart';
import 'domain/data/test_level.dart';
import 'domain/models/game_mode.dart';
import 'domain/services/game_engine.dart';
import 'domain/services/level_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/game_provider.dart';
import 'presentation/providers/progress_provider.dart';
import 'presentation/screens/auth/auth_screen.dart';
import 'presentation/screens/front/front_screen.dart';
import 'presentation/screens/game/game_screen.dart';
import 'presentation/screens/level_select/level_select_screen.dart';
import 'presentation/theme/honey_theme.dart';

/// Route names for navigation.
class AppRoutes {
  static const String front = '/';
  static const String auth = '/auth';
  static const String levels = '/levels';
  static const String game = '/game';

  AppRoutes._();
}

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

  // Initialize repositories for persistence
  final prefs = await SharedPreferences.getInstance();
  final progressRepository = LocalProgressRepository(prefs);
  final authRepository = LocalAuthRepository(prefs);
  if (kDebugMode) {
    debugPrint('Progress and Auth repositories initialized');
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
        authRepositoryProvider.overrideWithValue(authRepository),
        if (apiServer != null)
          debugApiServerProvider.overrideWithValue(apiServer),
      ],
      child: const HexBuzzApp(),
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

class HexBuzzApp extends StatelessWidget {
  const HexBuzzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HexBuzz',
      theme: HoneyTheme.lightTheme,
      initialRoute: AppRoutes.front,
      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    final path = uri.path;

    // Determine if this is a forward or backward navigation
    // Forward: slides left, Back: slides right
    final isForward = !_isBackNavigation(settings);

    switch (path) {
      case AppRoutes.front:
        return _buildRoute(const FrontScreen(), settings, isForward);

      case AppRoutes.auth:
        return _buildRoute(const AuthScreen(), settings, isForward);

      case AppRoutes.levels:
        return _buildRoute(const LevelSelectScreen(), settings, isForward);

      case AppRoutes.game:
        final levelIndex = settings.arguments as int?;
        return _buildRoute(
          GameScreen(levelIndex: levelIndex),
          settings,
          isForward,
        );

      default:
        return _buildRoute(const FrontScreen(), settings, isForward);
    }
  }

  bool _isBackNavigation(RouteSettings settings) {
    // Back navigation occurs when returning to front or levels from deeper screens
    final name = settings.name ?? '';
    return name == AppRoutes.front ||
        (name == AppRoutes.levels && settings.arguments == 'back');
  }

  Route<T> _buildRoute<T>(Widget page, RouteSettings settings, bool isForward) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide direction: forward slides left (offset from right)
        // backward slides right (offset from left)
        final begin = isForward
            ? const Offset(1.0, 0.0)
            : const Offset(-1.0, 0.0);
        const end = Offset.zero;

        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );

        final slideAnimation = Tween<Offset>(
          begin: begin,
          end: end,
        ).animate(curvedAnimation);

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(curvedAnimation);

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(position: slideAnimation, child: child),
        );
      },
    );
  }
}
