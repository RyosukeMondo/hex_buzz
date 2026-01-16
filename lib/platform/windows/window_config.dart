import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Windows window configuration helper
///
/// Provides utilities for configuring window properties on Windows platform,
/// including minimum window size constraints for optimal gameplay experience.
class WindowConfig {
  WindowConfig._();

  /// Minimum window width for Windows desktop
  static const double minWidth = 720.0;

  /// Minimum window height for Windows desktop
  static const double minHeight = 480.0;

  /// Default window width for Windows desktop
  static const double defaultWidth = 1024.0;

  /// Default window height for Windows desktop
  static const double defaultHeight = 768.0;

  /// Whether the current platform is Windows
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Whether the current platform is desktop (Windows, macOS, Linux)
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Initializes window configuration for Windows platform
  ///
  /// This should be called early in the app initialization process,
  /// before runApp() is called.
  static Future<void> initialize() async {
    if (!isWindows) return;

    // Note: Window size constraints can be set using packages like window_manager
    // or bitsdojo_window. For now, we'll just log the configuration.
    if (kDebugMode) {
      debugPrint(
        'Window config: min ${minWidth}x$minHeight, '
        'default ${defaultWidth}x$defaultHeight',
      );
    }
  }

  /// Gets responsive breakpoint based on window width
  static WindowBreakpoint getBreakpoint(double width) {
    if (width < 600) return WindowBreakpoint.compact;
    if (width < 840) return WindowBreakpoint.medium;
    if (width < 1200) return WindowBreakpoint.expanded;
    return WindowBreakpoint.large;
  }

  /// Gets grid padding based on window size
  static EdgeInsets getGridPadding(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final breakpoint = getBreakpoint(size.width);

    switch (breakpoint) {
      case WindowBreakpoint.compact:
        return const EdgeInsets.all(8.0);
      case WindowBreakpoint.medium:
        return const EdgeInsets.all(16.0);
      case WindowBreakpoint.expanded:
        return const EdgeInsets.all(24.0);
      case WindowBreakpoint.large:
        return const EdgeInsets.all(32.0);
    }
  }

  /// Gets maximum game grid size based on window size
  static double getMaxGridSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = getGridPadding(context);

    // Reserve space for header, footer, and padding
    const headerHeight = 80.0;
    const footerHeight = 60.0;

    final availableWidth = size.width - padding.horizontal;
    final availableHeight =
        size.height - headerHeight - footerHeight - padding.vertical;

    // Return the smaller dimension to fit the grid
    return availableWidth < availableHeight ? availableWidth : availableHeight;
  }
}

/// Window size breakpoints for responsive layout
enum WindowBreakpoint {
  /// < 600px - Phone
  compact,

  /// 600-840px - Small tablet
  medium,

  /// 840-1200px - Large tablet / small desktop
  expanded,

  /// >= 1200px - Desktop
  large,
}
