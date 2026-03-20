import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models/diagnostic_models.dart';

/// Audits the widget tree for accessibility compliance.
///
/// Checks semantic labels, contrast ratios (WCAG AA), and
/// touch target sizes (minimum 48x48dp).
class AccessibilityAuditor {
  /// Minimum touch target size in logical pixels (48dp per Material guidelines).
  static const double _minTouchTargetSize = 48.0;

  /// WCAG AA minimum contrast ratio for normal text.
  static const double _wcagAANormalText = 4.5;

  /// WCAG AA minimum contrast ratio for large text (>= 18pt or 14pt bold).
  static const double _wcagAALargeText = 3.0;

  /// Checks that all interactive elements have semantic labels.
  ///
  /// Interactive elements include buttons, gesture detectors,
  /// and other tappable widgets. Missing labels make the app
  /// inaccessible to screen readers.
  List<AccessibilityIssue> auditSemantics(BuildContext context) {
    final issues = <AccessibilityIssue>[];
    _visitAll(context as Element, (element) {
      _checkSemanticLabel(element, issues);
    });
    return issues;
  }

  /// Checks text color contrast against background colors.
  ///
  /// Compares foreground and background luminance to verify
  /// WCAG AA compliance (4.5:1 for normal text, 3:1 for large).
  List<AccessibilityIssue> auditContrast(BuildContext context) {
    final issues = <AccessibilityIssue>[];
    _visitAll(context as Element, (element) {
      _checkContrast(element, context, issues);
    });
    return issues;
  }

  /// Checks that interactive elements meet minimum touch target size.
  ///
  /// Per Material Design guidelines, interactive elements should be
  /// at least 48x48dp to be comfortably tappable.
  List<AccessibilityIssue> auditTouchTargets(BuildContext context) {
    final issues = <AccessibilityIssue>[];
    _visitAll(context as Element, (element) {
      _checkTouchTarget(element, issues);
    });
    return issues;
  }

  /// Runs all accessibility audits and returns combined issues.
  List<AccessibilityIssue> runFullAudit(BuildContext context) {
    return [
      ...auditSemantics(context),
      ...auditContrast(context),
      ...auditTouchTargets(context),
    ];
  }

  // -- Semantic label checks --

  void _checkSemanticLabel(
    Element element,
    List<AccessibilityIssue> issues,
  ) {
    final widget = element.widget;
    if (!_isInteractive(widget)) return;

    // Check if this widget or a parent Semantics provides a label
    final hasLabel = _hasSemanticLabel(element);
    if (!hasLabel) {
      issues.add(AccessibilityIssue(
        type: AccessibilityIssueType.missingLabel,
        widgetType: widget.runtimeType.toString(),
        details: 'Interactive widget missing semantic label',
        severity: 'warning',
        location: _buildLocation(element),
      ));
    }
  }

  bool _hasSemanticLabel(Element element) {
    // Check if the widget itself is a Semantics with a label
    if (element.widget is Semantics) {
      final semantics = element.widget as Semantics;
      if (semantics.properties.label?.isNotEmpty == true) return true;
    }

    // Check if any child provides text (e.g., Text inside a button)
    bool hasText = false;
    element.visitChildren((child) {
      if (hasText) return;
      if (child.widget is Text) {
        final text = child.widget as Text;
        if (text.data?.isNotEmpty == true) hasText = true;
      }
      if (!hasText) {
        hasText = _hasSemanticLabel(child);
      }
    });

    return hasText;
  }

  // -- Contrast checks --

  void _checkContrast(
    Element element,
    BuildContext context,
    List<AccessibilityIssue> issues,
  ) {
    final widget = element.widget;
    if (widget is! Text) return;

    final style = _resolveTextStyle(widget, element);
    if (style == null) return;

    final textColor = style.color ?? Colors.black;
    final bgColor = _findBackgroundColor(element) ?? Colors.white;

    final ratio = _calculateContrastRatio(textColor, bgColor);
    final isLargeText = _isLargeText(style);
    final minRatio = isLargeText ? _wcagAALargeText : _wcagAANormalText;

    if (ratio < minRatio) {
      issues.add(AccessibilityIssue(
        type: AccessibilityIssueType.lowContrast,
        widgetType: 'Text',
        details: 'Contrast ratio ${ratio.toStringAsFixed(2)}:1 '
            'below WCAG AA minimum ${minRatio.toStringAsFixed(1)}:1 '
            'for ${isLargeText ? "large" : "normal"} text',
        severity: ratio < 2.0 ? 'error' : 'warning',
        location: {
          ..._buildLocation(element),
          'textColor': _colorToHex(textColor),
          'backgroundColor': _colorToHex(bgColor),
          'contrastRatio': ratio,
        },
      ));
    }
  }

  TextStyle? _resolveTextStyle(Text textWidget, Element element) {
    if (textWidget.style != null) return textWidget.style;

    // Try to resolve from default text style
    try {
      final defaultStyle = DefaultTextStyle.of(element);
      return defaultStyle.style;
    } catch (_) {
      return null;
    }
  }

  Color? _findBackgroundColor(Element element) {
    Color? bgColor;
    Element? current = element;

    // Walk up the tree looking for a Container/DecoratedBox with a color
    while (current != null && bgColor == null) {
      final widget = current.widget;

      if (widget is Container && widget.color != null) {
        bgColor = widget.color;
      } else if (widget is ColoredBox) {
        bgColor = widget.color;
      } else if (widget is Material) {
        bgColor = widget.color;
      } else if (widget is Scaffold) {
        bgColor = widget.backgroundColor;
      }

      // Walk up via visitAncestorElements
      Element? parent;
      current.visitAncestorElements((ancestor) {
        parent = ancestor;
        return false; // Stop after first ancestor
      });
      current = parent;
    }

    return bgColor;
  }

  // -- Touch target checks --

  void _checkTouchTarget(
    Element element,
    List<AccessibilityIssue> issues,
  ) {
    final widget = element.widget;
    if (!_isInteractive(widget)) return;

    final renderObject = element.renderObject;
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final size = renderObject.size;
    if (size.width < _minTouchTargetSize ||
        size.height < _minTouchTargetSize) {
      issues.add(AccessibilityIssue(
        type: AccessibilityIssueType.smallTouchTarget,
        widgetType: widget.runtimeType.toString(),
        details: 'Touch target ${size.width.toStringAsFixed(0)}x'
            '${size.height.toStringAsFixed(0)} is below '
            '${_minTouchTargetSize.toInt()}x'
            '${_minTouchTargetSize.toInt()} minimum',
        severity: 'warning',
        location: _buildLocation(element),
      ));
    }
  }

  // -- Utility methods --

  bool _isInteractive(Widget widget) {
    return widget is ElevatedButton ||
        widget is TextButton ||
        widget is OutlinedButton ||
        widget is IconButton ||
        widget is FloatingActionButton ||
        widget is InkWell ||
        widget is GestureDetector ||
        widget is Switch ||
        widget is Checkbox ||
        widget is Radio;
  }

  void _visitAll(Element element, void Function(Element) visitor) {
    visitor(element);
    element.visitChildren((child) {
      _visitAll(child, visitor);
    });
  }

  Map<String, dynamic> _buildLocation(Element element) {
    final location = <String, dynamic>{
      'widget': element.widget.runtimeType.toString(),
    };

    final renderObject = element.renderObject;
    if (renderObject is RenderBox && renderObject.hasSize) {
      location['size'] = {
        'width': renderObject.size.width,
        'height': renderObject.size.height,
      };
      try {
        if (renderObject.attached) {
          final offset = renderObject.localToGlobal(Offset.zero);
          location['position'] = {'x': offset.dx, 'y': offset.dy};
        }
      } catch (_) {
        // Position not available
      }
    }

    return location;
  }

  /// Calculates WCAG contrast ratio between two colors.
  ///
  /// Returns a value between 1 (identical) and 21 (black on white).
  double _calculateContrastRatio(Color foreground, Color background) {
    final fgLuminance = _relativeLuminance(foreground);
    final bgLuminance = _relativeLuminance(background);

    final lighter = math.max(fgLuminance, bgLuminance);
    final darker = math.min(fgLuminance, bgLuminance);

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calculates relative luminance per WCAG 2.0 formula.
  double _relativeLuminance(Color color) {
    final r = _linearize(color.r);
    final g = _linearize(color.g);
    final b = _linearize(color.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Converts sRGB channel value to linear.
  double _linearize(double channel) {
    return channel <= 0.03928
        ? channel / 12.92
        : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  bool _isLargeText(TextStyle style) {
    final fontSize = style.fontSize ?? 14.0;
    final isBold = style.fontWeight == FontWeight.bold ||
        (style.fontWeight != null && style.fontWeight!.index >= 6);
    return fontSize >= 18.0 || (fontSize >= 14.0 && isBold);
  }

  String _colorToHex(Color color) {
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }
}
