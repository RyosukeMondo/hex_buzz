import 'package:flutter/material.dart';

import '../../../domain/models/hex_cell.dart';
import '../../../domain/models/level.dart';
import 'hex_grid_animator.dart';
import 'hex_grid_gesture_handler.dart';
import 'hex_grid_layout.dart';
import 'hex_grid_renderer.dart';
import 'hex_grid_theme.dart';

/// Interactive hexagonal grid widget that composes cells, walls, and path.
///
/// This is the main composition root that orchestrates:
/// - Layout calculation (HexGridLayout)
/// - Gesture handling (HexGridGestureHandler)
/// - Visual rendering (HexGridRenderer)
/// - Cell animations (HexGridAnimator)
/// - Theming (HexGridTheme)
class HexGridWidget extends StatefulWidget {
  final Level level;
  final List<HexCell> path;
  final Set<HexCell> visitedCells;
  final CellCallback? onCellEntered;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  const HexGridWidget({
    super.key,
    required this.level,
    required this.path,
    required this.visitedCells,
    this.onCellEntered,
    this.onDragStart,
    this.onDragEnd,
  });

  @override
  State<HexGridWidget> createState() => _HexGridWidgetState();
}

class _HexGridWidgetState extends State<HexGridWidget> {
  late HexGridTheme _theme;
  late HexGridAnimator _animator;

  /// Track previous visited cell count to detect path reset
  int _previousVisitedCount = 0;

  @override
  void initState() {
    super.initState();
    _theme = HexGridTheme.fromHoneyTheme();
    _animator = HexGridAnimator();
  }

  @override
  Widget build(BuildContext context) {
    // Reset animated cells when starting a new path (empty visited cells).
    // This replaces didUpdateWidget lifecycle method with inline check.
    if (widget.visitedCells.isEmpty && _previousVisitedCount > 0) {
      _animator.reset();
    }
    _previousVisitedCount = widget.visitedCells.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = HexGridLayout.calculate(
          level: widget.level,
          constraints: constraints,
        );

        return HexGridGestureHandler(
          layout: layout,
          level: widget.level,
          onCellEntered: widget.onCellEntered,
          onDragStart: widget.onDragStart,
          onDragEnd: widget.onDragEnd,
          child: Stack(
            children: [
              // Base layer: the grid painted via CustomPainter
              HexGridRenderer(
                layout: layout,
                level: widget.level,
                path: widget.path,
                visitedCells: widget.visitedCells,
                theme: _theme,
              ),
              // Animation overlay: positioned AnimatedCellPaint widgets
              HexGridAnimationOverlays(
                visitedCells: widget.visitedCells,
                path: widget.path,
                totalCells: widget.level.cells.length,
                cellSize: layout.cellSize,
                origin: layout.origin,
                theme: _theme,
                animator: _animator,
              ),
            ],
          ),
        );
      },
    );
  }
}
