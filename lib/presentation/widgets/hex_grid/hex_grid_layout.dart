import 'dart:math';

import 'package:flutter/material.dart';

import '../../../domain/models/level.dart';
import '../../utils/hex_utils.dart';

/// Handles hexagonal grid layout calculations and positioning.
///
/// Responsible for:
/// - Calculating optimal cell size to fit available space
/// - Computing grid dimensions in pixels
/// - Centering the grid within constraints
/// - Converting between pixel and hex coordinates
class HexGridLayout {
  final Level level;
  final BoxConstraints constraints;
  final double cellSize;
  final Offset origin;
  final Size gridSize;

  static const _minCellSize = 20.0;
  static const _maxCellSize = 80.0;
  static const _padding = 24.0;

  HexGridLayout._({
    required this.level,
    required this.constraints,
    required this.cellSize,
    required this.origin,
    required this.gridSize,
  });

  /// Creates a layout by calculating all necessary dimensions.
  factory HexGridLayout.calculate({
    required Level level,
    required BoxConstraints constraints,
  }) {
    final cellSize = _calculateCellSize(level, constraints);
    final gridSize = _calculateGridSize(level, cellSize);
    final origin = _calculateOrigin(level, constraints, gridSize, cellSize);

    return HexGridLayout._(
      level: level,
      constraints: constraints,
      cellSize: cellSize,
      origin: origin,
      gridSize: gridSize,
    );
  }

  /// Converts hex coordinate to pixel position.
  Offset hexToPixel(int q, int r) {
    return HexUtils.axialToPixel(q, r, cellSize, origin);
  }

  /// Converts pixel position to hex coordinate.
  ({int q, int r}) pixelToHex(Offset position) {
    return HexUtils.pixelToAxial(position, cellSize, origin);
  }

  /// Calculates the optimal cell size to fit the grid within constraints.
  static double _calculateCellSize(Level level, BoxConstraints constraints) {
    final availableWidth = constraints.maxWidth - (_padding * 2);
    final availableHeight = constraints.maxHeight - (_padding * 2);

    final cells = level.cells.values;
    if (cells.isEmpty) return _minCellSize;

    // Calculate actual pixel bounds at size=1.0 to determine scaling
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    for (final cell in cells) {
      final pos = HexUtils.axialToPixel(cell.q, cell.r, 1.0);
      minX = min(minX, pos.dx);
      maxX = max(maxX, pos.dx);
      minY = min(minY, pos.dy);
      maxY = max(maxY, pos.dy);
    }

    // Add hex radius to bounds (cells extend beyond their centers)
    final gridWidth = (maxX - minX) + 2.0; // +2 for hex width at size 1
    final gridHeight =
        (maxY - minY) + sqrt(3); // +sqrt(3) for hex height at size 1

    if (gridWidth <= 0 || gridHeight <= 0) return _minCellSize;

    // Calculate scale factor to fit
    final scaleX = availableWidth / gridWidth;
    final scaleY = availableHeight / gridHeight;
    final cellSize = min(scaleX, scaleY);

    return cellSize.clamp(_minCellSize, _maxCellSize);
  }

  /// Calculates the actual pixel size of the grid.
  static Size _calculateGridSize(Level level, double cellSize) {
    final cells = level.cells.values;
    if (cells.isEmpty) return Size.zero;

    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    for (final cell in cells) {
      final pos = HexUtils.axialToPixel(cell.q, cell.r, cellSize);
      minX = min(minX, pos.dx);
      maxX = max(maxX, pos.dx);
      minY = min(minY, pos.dy);
      maxY = max(maxY, pos.dy);
    }

    final width = (maxX - minX) + HexUtils.hexWidth(cellSize);
    final height = (maxY - minY) + HexUtils.hexHeight(cellSize);

    return Size(width, height);
  }

  /// Calculates the origin offset to center the grid.
  static Offset _calculateOrigin(
    Level level,
    BoxConstraints constraints,
    Size gridSize,
    double cellSize,
  ) {
    final cells = level.cells.values;
    if (cells.isEmpty) return Offset.zero;

    // Find the center of all cell positions
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    for (final cell in cells) {
      final pos = HexUtils.axialToPixel(cell.q, cell.r, cellSize);
      minX = min(minX, pos.dx);
      maxX = max(maxX, pos.dx);
      minY = min(minY, pos.dy);
      maxY = max(maxY, pos.dy);
    }

    final gridCenterX = (minX + maxX) / 2;
    final gridCenterY = (minY + maxY) / 2;

    // Offset to center grid in available space
    final originX = constraints.maxWidth / 2 - gridCenterX;
    final originY = constraints.maxHeight / 2 - gridCenterY;

    return Offset(originX, originY);
  }
}
