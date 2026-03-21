import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/analytics/analytics_event.dart';
import 'core/analytics/analytics_service.dart';
import 'core/analytics/firebase_analytics_service.dart';
import 'core/analytics/funnel_tracker.dart';
import 'core/analytics/local_analytics_service.dart';
import 'core/analytics/session_tracker.dart';
import 'core/logging/diagnostic_logger.dart';
import 'data/local/local_purchase_service.dart';
import 'data/local/placeholder_ad_service.dart';
import 'debug/api/server.dart';
import 'di/repository_overrides.dart';
import 'domain/data/test_level.dart';
import 'domain/models/game_mode.dart';
import 'domain/services/game_engine.dart';
import 'domain/services/notification_service.dart';
import 'firebase_options.dart';
import 'presentation/providers/analytics_provider.dart';
import 'presentation/providers/monetization_provider.dart';
import 'presentation/providers/notification_provider.dart';

/// Provider for the debug API server (available only in debug mode with ENABLE_API).
final debugApiServerProvider = Provider<DebugApiServer?>((ref) => null);

/// Initializes Firebase, Crashlytics, Performance, and DiagnosticLogger.
Future<void> initializeFirebaseCore() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (kDebugMode) debugPrint('Firebase initialized');

  DiagnosticLogger.init();

  // Disable Performance Monitoring on web — Firebase Installations
  // fails with 400 on web builds and causes cascading errors.
  try {
    final performance = FirebasePerformance.instance;
    await performance.setPerformanceCollectionEnabled(!kIsWeb);
  } catch (e) {
    if (kDebugMode) debugPrint('Firebase Performance init skipped: $e');
  }

  if (!kDebugMode) {
    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
}

/// Builds all Riverpod provider overrides for the app.
///
/// Creates and initializes all repositories, services, and analytics,
/// then returns the list of overrides to inject into [ProviderScope].
Future<List<Override>> buildProviderOverrides({
  required SharedPreferences prefs,
  required bool enableApi,
}) async {
  final repoOverrides = await buildRepositoryOverrides(prefs);
  final serviceOverrides = await _buildServiceOverrides(prefs, enableApi);

  return [...repoOverrides, ...serviceOverrides];
}

/// Starts post-launch services like notification subscriptions.
void startPostLaunchServices(
  NotificationService notification,
  SharedPreferences prefs,
) async {
  try {
    final hasPermission = await notification.requestPermission();
    if (!hasPermission) {
      if (kDebugMode) {
        debugPrint(
          'Notification permission not granted, skipping initialization',
        );
      }
      return;
    }

    final initialized = await notification.initialize();
    if (!initialized) {
      if (kDebugMode) debugPrint('Failed to initialize notification service');
      return;
    }

    if (kDebugMode) debugPrint('Notification service initialized');

    await initializeNotificationSubscriptions(notification, prefs);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error initializing notification service: $e');
    }
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

Future<List<Override>> _buildServiceOverrides(
  SharedPreferences prefs,
  bool enableApi,
) async {
  final analytics = await _initializeAnalytics(prefs);
  final session = SessionTracker(prefs: prefs, analytics: analytics);
  final funnel = FunnelTracker(analytics: analytics, prefs: prefs);
  await session.startSession();
  analytics.trackEvent(AnalyticsEventType.appOpened);

  final ad = PlaceholderAdService();
  await ad.initialize();
  final purchase = LocalPurchaseService(prefs);
  await purchase.initialize();

  final notification = createNotificationService();

  DebugApiServer? apiServer;
  if (kDebugMode && enableApi) {
    apiServer = await _startDebugApiServer();
  }

  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    analyticsServiceProvider.overrideWithValue(analytics),
    sessionTrackerProvider.overrideWithValue(session),
    funnelTrackerProvider.overrideWithValue(funnel),
    adServiceProvider.overrideWithValue(ad),
    purchaseServiceProvider.overrideWithValue(purchase),
    notificationServiceProvider.overrideWithValue(notification),
    if (apiServer != null)
      debugApiServerProvider.overrideWithValue(apiServer),
  ];
}

Future<AnalyticsService> _initializeAnalytics(SharedPreferences prefs) async {
  final AnalyticsService svc;

  if (kDebugMode) {
    svc = LocalAnalyticsService();
  } else {
    svc = FirebaseAnalyticsService(prefs: prefs);
  }

  await svc.initialize();
  if (kDebugMode) debugPrint('Analytics service initialized');
  return svc;
}

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
