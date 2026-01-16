import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keyboard shortcuts configuration for Windows desktop
///
/// Provides desktop-standard keyboard shortcuts:
/// - Ctrl+Z: Undo last move
/// - Escape: Go back / close overlay
/// - F11: Toggle fullscreen (future enhancement)
class KeyboardShortcuts extends StatelessWidget {
  const KeyboardShortcuts({
    required this.child,
    this.onUndo,
    this.onBack,
    super.key,
  });

  /// The widget to wrap with keyboard shortcuts
  final Widget child;

  /// Callback for undo action (Ctrl+Z)
  final VoidCallback? onUndo;

  /// Callback for back action (Escape)
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        // Only handle key down events to avoid duplicate triggers
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }

        // Ctrl+Z - Undo
        if (event.logicalKey == LogicalKeyboardKey.keyZ &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          if (onUndo != null) {
            onUndo!();
            return KeyEventResult.handled;
          }
        }

        // Escape - Back
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          if (onBack != null) {
            onBack!();
            return KeyEventResult.handled;
          }
        }

        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}

/// Shortcut keys configuration for different actions
class ShortcutKeys {
  ShortcutKeys._();

  /// Undo shortcut (Ctrl+Z / Cmd+Z)
  static const SingleActivator undo = SingleActivator(
    LogicalKeyboardKey.keyZ,
    control: true,
    meta: true,
  );

  /// Back/Close shortcut (Escape)
  static const SingleActivator back = SingleActivator(
    LogicalKeyboardKey.escape,
  );

  /// Refresh shortcut (F5)
  static const SingleActivator refresh = SingleActivator(LogicalKeyboardKey.f5);

  /// Help shortcut (F1)
  static const SingleActivator help = SingleActivator(LogicalKeyboardKey.f1);
}

/// Mixin for widgets that need keyboard shortcut support
///
/// Provides common shortcut handling logic that can be mixed into StatefulWidgets.
mixin KeyboardShortcutsMixin<T extends StatefulWidget> on State<T> {
  /// Handle undo shortcut (Ctrl+Z)
  void handleUndo() {
    // Override in subclass
  }

  /// Handle back shortcut (Escape)
  void handleBack() {
    Navigator.of(context).maybePop();
  }

  /// Handle refresh shortcut (F5)
  void handleRefresh() {
    // Override in subclass
  }

  /// Wraps a widget with keyboard shortcuts
  Widget withKeyboardShortcuts({required Widget child}) {
    return KeyboardShortcuts(
      onUndo: handleUndo,
      onBack: handleBack,
      child: child,
    );
  }

  /// Creates a CallbackShortcuts widget with common shortcuts
  Widget withCallbackShortcuts({required Widget child}) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
            handleUndo,
        const SingleActivator(LogicalKeyboardKey.escape): handleBack,
        const SingleActivator(LogicalKeyboardKey.f5): handleRefresh,
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
