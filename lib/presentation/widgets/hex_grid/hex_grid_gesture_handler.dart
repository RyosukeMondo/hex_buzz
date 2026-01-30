import 'package:flutter/material.dart';

import '../../../domain/models/hex_cell.dart';
import '../../../domain/models/level.dart';
import 'hex_grid_layout.dart';

/// Callback signature for cell interaction events.
typedef CellCallback = void Function(HexCell cell);

/// Handles user interactions with the hex grid.
///
/// Wraps child widget with gesture detection for:
/// - Tap: Single tap on a cell
/// - Drag: Pan gestures across multiple cells
///
/// Converts pixel positions to hex coordinates and emits cell events.
class HexGridGestureHandler extends StatefulWidget {
  final HexGridLayout layout;
  final Level level;
  final CellCallback? onCellEntered;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final Widget child;

  const HexGridGestureHandler({
    super.key,
    required this.layout,
    required this.level,
    required this.child,
    this.onCellEntered,
    this.onDragStart,
    this.onDragEnd,
  });

  @override
  State<HexGridGestureHandler> createState() => _HexGridGestureHandlerState();
}

class _HexGridGestureHandlerState extends State<HexGridGestureHandler> {
  HexCell? _lastEnteredCell;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handleDragStart,
      onPanUpdate: _handleDragUpdate,
      onPanEnd: _handleDragEnd,
      onTapDown: _handleTap,
      child: widget.child,
    );
  }

  void _handleDragStart(DragStartDetails details) {
    _isDragging = true;
    _lastEnteredCell = null;
    widget.onDragStart?.call();
    _processPointerPosition(details.localPosition);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    _processPointerPosition(details.localPosition);
  }

  void _handleDragEnd(DragEndDetails details) {
    _isDragging = false;
    _lastEnteredCell = null;
    widget.onDragEnd?.call();
  }

  void _handleTap(TapDownDetails details) {
    _processPointerPosition(details.localPosition);
  }

  void _processPointerPosition(Offset position) {
    final coords = widget.layout.pixelToHex(position);
    final cell = widget.level.getCell(coords.q, coords.r);

    if (cell == null) return;

    // Only emit if entering a different cell
    if (cell != _lastEnteredCell) {
      _lastEnteredCell = cell;
      widget.onCellEntered?.call(cell);
    }
  }
}
