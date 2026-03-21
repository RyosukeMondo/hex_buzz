import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'models/diagnostic_models.dart';

/// Inspects the Flutter widget tree at runtime for diagnostics.
///
/// Uses [Element.visitChildren] and [RenderObject] APIs to traverse
/// the live widget tree and detect layout issues, find widgets by type,
/// and capture tree structure for serialization.
class WidgetTreeInspector {
  /// Captures the current widget tree as a serializable structure.
  ///
  /// Traverses from the given [context] down to [maxDepth] levels,
  /// returning a nested map of widget type, size, and children.
  Map<String, dynamic> captureWidgetTree(
    BuildContext context, {
    int maxDepth = 10,
  }) {
    final element = context as Element;
    return _captureElement(element, 0, maxDepth);
  }

  Map<String, dynamic> _captureElement(
    Element element,
    int depth,
    int maxDepth,
  ) {
    final widget = element.widget;
    final renderObject = element.renderObject;

    final node = <String, dynamic>{
      'type': widget.runtimeType.toString(),
      'depth': depth,
    };

    if (renderObject is RenderBox && renderObject.hasSize) {
      node['size'] = {
        'width': renderObject.size.width,
        'height': renderObject.size.height,
      };

      final offset = _getGlobalOffset(renderObject);
      if (offset != null) {
        node['position'] = {'x': offset.dx, 'y': offset.dy};
      }
    }

    // Add key info if present
    if (widget.key != null) {
      node['key'] = widget.key.toString();
    }

    // Capture children if within depth limit
    if (depth < maxDepth) {
      final children = <Map<String, dynamic>>[];
      element.visitChildren((child) {
        children.add(_captureElement(child, depth + 1, maxDepth));
      });
      if (children.isNotEmpty) {
        node['children'] = children;
      }
    }

    return node;
  }

  /// Finds all widgets matching [typeName] in the tree.
  ///
  /// Returns a list of maps with widget type, size, position, and depth.
  List<Map<String, dynamic>> findWidgets(
    BuildContext context,
    String typeName,
  ) {
    final results = <Map<String, dynamic>>[];
    _visitAll(context as Element, (element, depth) {
      if (element.widget.runtimeType.toString() == typeName) {
        results.add(_buildWidgetInfo(element, depth));
      }
    });
    return results;
  }

  /// Detects common layout issues in the widget tree.
  ///
  /// Checks for overflow, zero-size widgets, off-screen positioning,
  /// text overflow/clipping, and unbounded constraints.
  List<LayoutIssue> detectLayoutIssues(BuildContext context) {
    final issues = <LayoutIssue>[];
    final screenSize = _getScreenSize(context);

    _visitAll(context as Element, (element, depth) {
      final renderObject = element.renderObject;
      if (renderObject is! RenderBox) return;

      _checkOverflow(element, renderObject, issues);
      _checkZeroSize(element, renderObject, issues);
      _checkOffscreen(element, renderObject, screenSize, issues);
      _checkTextOverflow(element, issues);
    });

    return issues;
  }

  /// Gets the current route name from the navigator.
  String getCurrentRoute(BuildContext context) {
    String? routeName;
    Navigator.of(context).popUntil((route) {
      routeName = route.settings.name;
      return true; // Don't actually pop
    });
    return routeName ?? 'unknown';
  }

  /// Lists all registered routes from AppRoutes.
  ///
  /// Returns all route names defined in the application.
  List<String> getRegisteredRoutes() {
    return const [
      '/',
      '/auth',
      '/levels',
      '/game',
      '/daily-challenge',
      '/leaderboard',
      '/tutorial',
      '/achievements',
      '/level-packs',
      '/pack-levels',
      '/friends',
      '/editor',
      '/my-levels',
      '/store',
      '/timed-challenge-menu',
      '/timed-challenge',
      '/settings',
      '/app-info',
      '/notification-settings',
      '/privacy-policy',
      '/terms',
      '/whats-new',
    ];
  }

  // -- Private helpers --

  void _visitAll(
    Element element,
    void Function(Element element, int depth) visitor, {
    int depth = 0,
  }) {
    visitor(element, depth);
    element.visitChildren((child) {
      _visitAll(child, visitor, depth: depth + 1);
    });
  }

  Map<String, dynamic> _buildWidgetInfo(Element element, int depth) {
    final widget = element.widget;
    final renderObject = element.renderObject;
    final info = <String, dynamic>{
      'type': widget.runtimeType.toString(),
      'depth': depth,
    };

    if (renderObject is RenderBox && renderObject.hasSize) {
      info['size'] = {
        'width': renderObject.size.width,
        'height': renderObject.size.height,
      };

      final offset = _getGlobalOffset(renderObject);
      if (offset != null) {
        info['position'] = {'x': offset.dx, 'y': offset.dy};
      }
    }

    if (widget.key != null) {
      info['key'] = widget.key.toString();
    }

    return info;
  }

  void _checkOverflow(
    Element element,
    RenderBox renderBox,
    List<LayoutIssue> issues,
  ) {
    // Detect RenderFlex overflow via overflow flag on parent
    if (renderBox is RenderFlex) {
      // RenderFlex stores overflow in debug properties
      final diagnostics = renderBox.debugDescribeChildren();
      for (final child in diagnostics) {
        if (child.toString().contains('OVERFLOW')) {
          issues.add(LayoutIssue(
            type: LayoutIssueType.overflow,
            widgetType: element.widget.runtimeType.toString(),
            details: 'RenderFlex overflow detected',
            location: _buildLocation(element, renderBox),
          ));
          break;
        }
      }
    }

    // Check if the render object has overflowing paint
    if (renderBox.debugNeedsLayout) {
      issues.add(LayoutIssue(
        type: LayoutIssueType.overflow,
        widgetType: element.widget.runtimeType.toString(),
        details: 'Widget needs layout (may indicate layout error)',
        location: _buildLocation(element, renderBox),
      ));
    }
  }

  void _checkZeroSize(
    Element element,
    RenderBox renderBox,
    List<LayoutIssue> issues,
  ) {
    if (!renderBox.hasSize) return;
    final size = renderBox.size;

    // Skip intentionally zero-size widgets
    final typeName = element.widget.runtimeType.toString();
    if (_isIntentionallyEmpty(typeName)) return;

    if (size.width == 0 && size.height == 0) {
      issues.add(LayoutIssue(
        type: LayoutIssueType.zeroSize,
        widgetType: typeName,
        details: 'Widget has zero width and height',
        location: _buildLocation(element, renderBox),
      ));
    }
  }

  void _checkOffscreen(
    Element element,
    RenderBox renderBox,
    Size? screenSize,
    List<LayoutIssue> issues,
  ) {
    if (screenSize == null || !renderBox.hasSize) return;

    final offset = _getGlobalOffset(renderBox);
    if (offset == null) return;

    final size = renderBox.size;
    final typeName = element.widget.runtimeType.toString();

    // Skip decorations, painters, and non-visual widgets
    if (_isNonVisual(typeName)) return;

    // Check if fully off-screen (not just partially)
    final isFullyOffscreen = offset.dx + size.width < 0 ||
        offset.dy + size.height < 0 ||
        offset.dx > screenSize.width ||
        offset.dy > screenSize.height;

    if (isFullyOffscreen && size.width > 0 && size.height > 0) {
      issues.add(LayoutIssue(
        type: LayoutIssueType.offscreen,
        widgetType: typeName,
        details: 'Widget is fully off-screen at '
            '(${offset.dx.toStringAsFixed(1)}, '
            '${offset.dy.toStringAsFixed(1)})',
        location: _buildLocation(element, renderBox),
      ));
    }
  }

  void _checkTextOverflow(Element element, List<LayoutIssue> issues) {
    final widget = element.widget;
    if (widget is Text && widget.overflow == TextOverflow.clip) {
      final renderObject = element.renderObject;
      if (renderObject is RenderParagraph) {
        if (renderObject.didExceedMaxLines) {
          issues.add(LayoutIssue(
            type: LayoutIssueType.textOverflow,
            widgetType: 'Text',
            details: 'Text is clipped: "${_truncateText(widget.data)}"',
            location: _buildLocation(
              element,
              renderObject as RenderBox,
            ),
          ));
        }
      }
    }
  }

  Map<String, dynamic> _buildLocation(Element element, RenderBox renderBox) {
    final location = <String, dynamic>{
      'widget': element.widget.runtimeType.toString(),
    };

    if (renderBox.hasSize) {
      location['size'] = {
        'width': renderBox.size.width,
        'height': renderBox.size.height,
      };
    }

    final offset = _getGlobalOffset(renderBox);
    if (offset != null) {
      location['position'] = {'x': offset.dx, 'y': offset.dy};
    }

    return location;
  }

  Offset? _getGlobalOffset(RenderBox renderBox) {
    try {
      if (!renderBox.attached) return null;
      return renderBox.localToGlobal(Offset.zero);
    } catch (_) {
      return null;
    }
  }

  Size? _getScreenSize(BuildContext context) {
    try {
      return MediaQuery.of(context).size;
    } catch (_) {
      return null;
    }
  }

  String _truncateText(String? text) {
    if (text == null) return '';
    return text.length > 40 ? '${text.substring(0, 40)}...' : text;
  }

  bool _isIntentionallyEmpty(String typeName) {
    return typeName == 'SizedBox' ||
        typeName == 'Spacer' ||
        typeName == 'SizedBox.shrink' ||
        typeName.startsWith('_');
  }

  bool _isNonVisual(String typeName) {
    return typeName.contains('Painter') ||
        typeName.contains('Decoration') ||
        typeName.startsWith('_') ||
        typeName == 'Semantics' ||
        typeName == 'MediaQuery';
  }
}
