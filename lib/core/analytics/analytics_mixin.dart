import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/analytics_provider.dart';
import 'analytics_event.dart';

/// Mixin for automatic screen view tracking on ConsumerStatefulWidgets.
///
/// Screens that mix this in will automatically fire a
/// [AnalyticsEventType.screenViewed] event when they first mount.
///
/// Usage:
/// ```dart
/// class MyScreen extends ConsumerStatefulWidget {
///   const MyScreen({super.key});
///
///   @override
///   ConsumerState<MyScreen> createState() => _MyScreenState();
/// }
///
/// class _MyScreenState extends ConsumerState<MyScreen>
///     with ScreenAnalytics<MyScreen> {
///   @override
///   String get screenName => 'my_screen';
///
///   @override
///   Widget build(BuildContext context) { ... }
/// }
/// ```
mixin ScreenAnalytics<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// The name of this screen for analytics tracking.
  ///
  /// Should be a snake_case identifier (e.g., 'level_select', 'game_screen').
  String get screenName;

  @override
  void initState() {
    super.initState();
    _trackScreenView();
  }

  /// Fires a screen view event for this screen.
  void _trackScreenView() {
    final analytics = ref.read(analyticsServiceProvider);
    analytics.trackEvent(
      AnalyticsEventType.screenViewed,
      properties: {'screen': screenName},
    );
  }

  /// Convenience method to track a user action from within the screen.
  ///
  /// The [action] parameter must match an [AnalyticsEventType] name.
  /// Additional [properties] are merged into the event.
  void trackAction(
    String action, {
    Map<String, dynamic>? properties,
  }) {
    final analytics = ref.read(analyticsServiceProvider);
    analytics.trackEvent(
      AnalyticsEventType.values.byName(action),
      properties: properties,
    );
  }
}
