import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_initializer.dart';
import 'core/logging/diagnostic_logger.dart';
import 'core/logging/logger.dart';
import 'domain/services/timed_challenge_service.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/achievements/achievement_screen.dart';
import 'presentation/screens/auth/auth_screen.dart';
import 'presentation/screens/daily_challenge/daily_challenge_screen.dart';
import 'presentation/screens/front/front_screen.dart';
import 'presentation/screens/game/game_screen.dart';
import 'presentation/screens/leaderboard/leaderboard_screen.dart';
import 'presentation/screens/editor/level_editor_screen.dart';
import 'presentation/screens/friends/friends_screen.dart';
import 'presentation/screens/editor/my_levels_screen.dart';
import 'presentation/screens/level_packs/level_packs_screen.dart';
import 'presentation/screens/level_packs/pack_levels_screen.dart';
import 'presentation/screens/level_select/level_select_screen.dart';
import 'presentation/screens/store/store_screen.dart';
import 'presentation/screens/timed_challenge/timed_challenge_menu_screen.dart';
import 'presentation/screens/timed_challenge/timed_challenge_screen.dart';
import 'presentation/screens/settings/app_info_screen.dart';
import 'presentation/screens/settings/notification_settings_screen.dart';
import 'presentation/screens/settings/privacy_policy_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/settings/terms_screen.dart';
import 'presentation/screens/whats_new/whats_new_screen.dart';
import 'presentation/screens/tutorial/tutorial_screen.dart';
import 'presentation/theme/honey_theme.dart';
import 'platform/windows/window_config.dart';

/// Route names for navigation.
class AppRoutes {
  static const String front = '/';
  static const String auth = '/auth';
  static const String levels = '/levels';
  static const String game = '/game';
  static const String dailyChallenge = '/daily-challenge';
  static const String leaderboard = '/leaderboard';
  static const String tutorial = '/tutorial';
  static const String achievements = '/achievements';
  static const String levelPacks = '/level-packs';
  static const String packLevels = '/pack-levels';
  static const String friends = '/friends';
  static const String editor = '/editor';
  static const String myLevels = '/my-levels';
  static const String store = '/store';
  static const String timedChallengeMenu = '/timed-challenge-menu';
  static const String timedChallenge = '/timed-challenge';
  static const String settings = '/settings';
  static const String appInfo = '/app-info';
  static const String notificationSettings = '/notification-settings';
  static const String privacyPolicy = '/privacy-policy';
  static const String terms = '/terms';
  static const String whatsNew = '/whats-new';

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
  await WindowConfig.initialize();
  await initializeFirebaseCore();
  final prefs = await SharedPreferences.getInstance();

  final overrides = await buildProviderOverrides(
    prefs: prefs,
    enableApi: _enableApiFromEnv,
  );

  runApp(
    ProviderScope(
      overrides: overrides,
      child: const HexBuzzApp(),
    ),
  );

  // Initialize notification service after app is running
  final notification = createNotificationService();
  startPostLaunchServices(notification, prefs);
}

class HexBuzzApp extends ConsumerStatefulWidget {
  const HexBuzzApp({super.key});

  @override
  ConsumerState<HexBuzzApp> createState() => _HexBuzzAppState();
}

class _HexBuzzAppState extends ConsumerState<HexBuzzApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupNotificationHandlers();
  }

  /// Sets up handlers for incoming notifications.
  void _setupNotificationHandlers() {
    final svc = ref.read(notificationServiceProvider);

    svc.onMessageReceived.listen((message) {
      if (kDebugMode) {
        debugPrint('Notification received: $message');
      }

      _handleNotificationMessage(message);
    });
  }

  /// Handles a received notification message.
  void _handleNotificationMessage(Map<String, dynamic> message) {
    final context = _navigatorKey.currentContext;
    if (context == null) return;

    final title = message['title'] as String? ?? '';
    final body = message['body'] as String? ?? '';
    final data = message['data'] as Map<String, dynamic>? ?? {};

    DiagnosticLogger.logEvent(
      'notification_received',
      data: {'title': title, 'type': data['type']},
      level: LogLevel.info,
    );

    // Show snackbar for foreground notifications
    if (title.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (body.isNotEmpty) Text(body),
            ],
          ),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => _navigateFromNotification(data),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// Navigates to the appropriate screen based on notification data.
  void _navigateFromNotification(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final route = data['route'] as String?;

    DiagnosticLogger.logEvent(
      'notification_navigation',
      data: {'type': type, 'route': route},
      level: LogLevel.info,
    );

    switch (type) {
      case 'daily_challenge':
        _navigatorKey.currentState?.pushNamed(AppRoutes.dailyChallenge);
        break;

      case 'new_level':
        final levelIndex = data['levelIndex'] as int?;
        _navigatorKey.currentState?.pushNamed(
          AppRoutes.game,
          arguments: levelIndex,
        );
        break;

      default:
        // Generic route from notification data
        if (route != null) {
          _navigatorKey.currentState?.pushNamed(route);
        } else {
          // Default to front screen
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            AppRoutes.front,
            (route) => false,
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themePref = ref.watch(themeProvider);
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'HexBuzz',
      theme: HoneyTheme.lightTheme,
      darkTheme: HoneyTheme.darkTheme,
      themeMode: themeModeFromPreference(themePref),
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

      case AppRoutes.dailyChallenge:
        return _buildRoute(const DailyChallengeScreen(), settings, isForward);

      case AppRoutes.leaderboard:
        return _buildRoute(const LeaderboardScreen(), settings, isForward);

      case AppRoutes.tutorial:
        return _buildRoute(const TutorialScreen(), settings, isForward);

      case AppRoutes.achievements:
        return _buildRoute(const AchievementScreen(), settings, isForward);

      case AppRoutes.settings:
        return _buildRoute(const SettingsScreen(), settings, isForward);

      case AppRoutes.appInfo:
        return _buildRoute(const AppInfoScreen(), settings, isForward);

      case AppRoutes.notificationSettings:
        return _buildRoute(
          const NotificationSettingsScreen(),
          settings,
          isForward,
        );

      case AppRoutes.privacyPolicy:
        return _buildRoute(
          const PrivacyPolicyScreen(),
          settings,
          isForward,
        );

      case AppRoutes.terms:
        return _buildRoute(const TermsScreen(), settings, isForward);

      case AppRoutes.whatsNew:
        return _buildRoute(const WhatsNewScreen(), settings, isForward);

      case AppRoutes.levelPacks:
        return _buildRoute(const LevelPacksScreen(), settings, isForward);

      case AppRoutes.packLevels:
        final packId = settings.arguments as String;
        return _buildRoute(
          PackLevelsScreen(packId: packId),
          settings,
          isForward,
        );

      case AppRoutes.friends:
        return _buildRoute(const FriendsScreen(), settings, isForward);

      case AppRoutes.editor:
        return _buildRoute(const LevelEditorScreen(), settings, isForward);

      case AppRoutes.myLevels:
        return _buildRoute(const MyLevelsScreen(), settings, isForward);

      case AppRoutes.store:
        return _buildRoute(const StoreScreen(), settings, isForward);

      case AppRoutes.timedChallengeMenu:
        return _buildRoute(
          const TimedChallengeMenuScreen(),
          settings,
          isForward,
        );

      case AppRoutes.timedChallenge:
        final config = settings.arguments as TimedChallengeConfig;
        return _buildRoute(
          TimedChallengeScreen(config: config),
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
