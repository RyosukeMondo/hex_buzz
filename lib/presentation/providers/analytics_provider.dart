import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/analytics/funnel_tracker.dart';
import '../../core/analytics/session_tracker.dart';

/// Provider for the analytics service (dependency injection point).
///
/// Override this provider in main.dart with a concrete implementation
/// (e.g., FirebaseAnalyticsService for production, LocalAnalyticsService
/// for debug builds).
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  throw UnimplementedError(
    'analyticsServiceProvider must be overridden with a concrete implementation',
  );
});

/// Provider for the session tracker (dependency injection point).
///
/// Override this provider in main.dart with an initialized SessionTracker.
final sessionTrackerProvider = Provider<SessionTracker>((ref) {
  throw UnimplementedError(
    'sessionTrackerProvider must be overridden with an initialized instance',
  );
});

/// Provider for the funnel tracker (dependency injection point).
///
/// Override this provider in main.dart with an initialized FunnelTracker.
final funnelTrackerProvider = Provider<FunnelTracker>((ref) {
  throw UnimplementedError(
    'funnelTrackerProvider must be overridden with an initialized instance',
  );
});
