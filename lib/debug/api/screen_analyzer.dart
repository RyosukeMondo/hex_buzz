import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/game_provider.dart';
import '../../presentation/providers/progress_provider.dart';
import 'models/diagnostic_models.dart';

/// Analyzes the current screen state for diagnostics.
///
/// Captures visible text, tappable elements, provider states,
/// and validates screen state against expectations.
class ScreenAnalyzer {
  /// Captures all visible text on the current screen.
  ///
  /// Walks the element tree and collects text from [Text],
  /// [RichText], and [EditableText] widgets.
  List<String> captureVisibleText(BuildContext context) {
    final texts = <String>[];
    _visitAll(context as Element, (element) {
      final text = _extractText(element);
      if (text != null && text.isNotEmpty) {
        texts.add(text);
      }
    });
    return texts;
  }

  /// Captures all tappable elements on screen.
  ///
  /// Finds buttons, gesture detectors, ink wells, and other
  /// interactive widgets, returning their type, label, size,
  /// and position.
  List<Map<String, dynamic>> captureTappableElements(BuildContext context) {
    final elements = <Map<String, dynamic>>[];
    _visitAll(context as Element, (element) {
      final tappable = _extractTappableInfo(element);
      if (tappable != null) {
        elements.add(tappable);
      }
    });
    return elements;
  }

  /// Captures current provider states as JSON.
  ///
  /// Reads game state, progress, and other provider values
  /// that are useful for diagnostic snapshots.
  Map<String, dynamic> captureProviderStates(WidgetRef ref) {
    final states = <String, dynamic>{};

    try {
      final gameState = ref.read(gameProvider);
      states['game'] = {
        'mode': gameState.mode.name,
        'isStarted': gameState.isStarted,
        'isComplete': gameState.isComplete,
        'pathLength': gameState.path.length,
        'nextCheckpoint': gameState.nextCheckpoint,
        'elapsedTimeMs': gameState.elapsedTime.inMilliseconds,
        'currentCell': gameState.currentCell != null
            ? {
                'q': gameState.currentCell!.q,
                'r': gameState.currentCell!.r,
              }
            : null,
      };
    } catch (_) {
      states['game'] = {'error': 'not_available'};
    }

    try {
      final progressAsync = ref.read(progressProvider);
      final progressState = progressAsync.valueOrNull;
      if (progressState != null) {
        states['progress'] = {
          'totalStars': progressState.totalStars,
          'completedLevels': progressState.completedLevels,
          'highestUnlockedLevel': progressState.highestUnlockedLevel,
        };
      } else {
        states['progress'] = {'status': 'loading_or_error'};
      }
    } catch (_) {
      states['progress'] = {'error': 'not_available'};
    }

    return states;
  }

  /// Validates screen state against a map of expectations.
  ///
  /// Supported expectation keys:
  /// - `route`: expected current route name
  /// - `visibleTexts`: list of strings expected on screen
  /// - `missingTexts`: list of strings expected to be absent
  /// - `tappableCount`: expected minimum tappable element count
  List<ValidationError> validateScreen(
    BuildContext context,
    Map<String, dynamic> expectations,
  ) {
    final errors = <ValidationError>[];

    _validateRoute(context, expectations, errors);
    _validateVisibleTexts(context, expectations, errors);
    _validateMissingTexts(context, expectations, errors);
    _validateTappableCount(context, expectations, errors);

    return errors;
  }

  // -- Private helpers --

  void _validateRoute(
    BuildContext context,
    Map<String, dynamic> expectations,
    List<ValidationError> errors,
  ) {
    if (!expectations.containsKey('route')) return;

    final expected = expectations['route'] as String;
    String? currentRoute;
    Navigator.of(context).popUntil((route) {
      currentRoute = route.settings.name;
      return true;
    });

    if (currentRoute != expected) {
      errors.add(ValidationError(
        field: 'route',
        expected: expected,
        actual: currentRoute ?? 'unknown',
      ));
    }
  }

  void _validateVisibleTexts(
    BuildContext context,
    Map<String, dynamic> expectations,
    List<ValidationError> errors,
  ) {
    if (!expectations.containsKey('visibleTexts')) return;

    final expectedTexts =
        (expectations['visibleTexts'] as List).cast<String>();
    final visibleTexts = captureVisibleText(context);

    for (final expected in expectedTexts) {
      if (!visibleTexts.any((t) => t.contains(expected))) {
        errors.add(ValidationError(
          field: 'visibleText',
          expected: expected,
          actual: 'not found on screen',
        ));
      }
    }
  }

  void _validateMissingTexts(
    BuildContext context,
    Map<String, dynamic> expectations,
    List<ValidationError> errors,
  ) {
    if (!expectations.containsKey('missingTexts')) return;

    final missingTexts =
        (expectations['missingTexts'] as List).cast<String>();
    final visibleTexts = captureVisibleText(context);

    for (final notExpected in missingTexts) {
      if (visibleTexts.any((t) => t.contains(notExpected))) {
        errors.add(ValidationError(
          field: 'missingText',
          expected: 'absent',
          actual: 'found "$notExpected" on screen',
        ));
      }
    }
  }

  void _validateTappableCount(
    BuildContext context,
    Map<String, dynamic> expectations,
    List<ValidationError> errors,
  ) {
    if (!expectations.containsKey('tappableCount')) return;

    final expectedMin = expectations['tappableCount'] as int;
    final tappable = captureTappableElements(context);

    if (tappable.length < expectedMin) {
      errors.add(ValidationError(
        field: 'tappableCount',
        expected: '>= $expectedMin',
        actual: '${tappable.length}',
      ));
    }
  }

  void _visitAll(Element element, void Function(Element) visitor) {
    visitor(element);
    element.visitChildren((child) {
      _visitAll(child, visitor);
    });
  }

  String? _extractText(Element element) {
    final widget = element.widget;

    if (widget is Text) {
      return widget.data;
    }

    if (widget is RichText) {
      return widget.text.toPlainText();
    }

    if (widget is EditableText) {
      return widget.controller.text;
    }

    return null;
  }

  Map<String, dynamic>? _extractTappableInfo(Element element) {
    final widget = element.widget;
    final isTappable = _isTappableWidget(widget);
    if (!isTappable) return null;

    final info = <String, dynamic>{
      'type': widget.runtimeType.toString(),
    };

    // Extract label from child text if available
    final label = _findChildText(element);
    if (label != null) {
      info['label'] = label;
    }

    // Extract size and position from render object
    final renderObject = element.renderObject;
    if (renderObject is RenderBox && renderObject.hasSize) {
      info['size'] = {
        'width': renderObject.size.width,
        'height': renderObject.size.height,
      };

      try {
        if (renderObject.attached) {
          final offset = renderObject.localToGlobal(Offset.zero);
          info['position'] = {'x': offset.dx, 'y': offset.dy};
        }
      } catch (_) {
        // Position not available
      }
    }

    // Extract enabled state
    if (widget is ElevatedButton) {
      info['enabled'] = widget.onPressed != null;
    } else if (widget is TextButton) {
      info['enabled'] = widget.onPressed != null;
    } else if (widget is IconButton) {
      info['enabled'] = widget.onPressed != null;
    }

    return info;
  }

  bool _isTappableWidget(Widget widget) {
    return widget is ElevatedButton ||
        widget is TextButton ||
        widget is OutlinedButton ||
        widget is IconButton ||
        widget is FloatingActionButton ||
        widget is InkWell ||
        widget is GestureDetector;
  }

  String? _findChildText(Element element) {
    String? text;
    element.visitChildren((child) {
      if (text != null) return;
      final extracted = _extractText(child);
      if (extracted != null && extracted.isNotEmpty) {
        text = extracted;
        return;
      }
      // Recurse into child
      text = _findChildText(child);
    });
    return text;
  }
}
