import 'dart:math';

import 'package:flutter/material.dart';

import '../../../domain/models/hex_cell.dart';
import '../../theme/honey_theme.dart';
import '../../utils/hex_utils.dart';

/// Renders a pulsing golden glow on a single cell to indicate a hint.
///
/// Uses an [AnimationController] to create a repeating pulse effect
/// that draws attention to the suggested cell without being distracting.
class HintHighlightOverlay extends StatefulWidget {
  final HexCell hintCell;
  final double cellSize;
  final Offset origin;

  const HintHighlightOverlay({
    super.key,
    required this.hintCell,
    required this.cellSize,
    required this.origin,
  });

  @override
  State<HintHighlightOverlay> createState() => _HintHighlightOverlayState();
}

class _HintHighlightOverlayState extends State<HintHighlightOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  static const _pulseDuration = Duration(milliseconds: 1200);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _pulseDuration,
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    if (reduceMotion) {
      return _buildStaticHighlight();
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _HintCellPainter(
            cell: widget.hintCell,
            cellSize: widget.cellSize,
            origin: widget.origin,
            glowOpacity: _pulseAnimation.value,
          ),
        );
      },
    );
  }

  Widget _buildStaticHighlight() {
    return CustomPaint(
      size: Size.infinite,
      painter: _HintCellPainter(
        cell: widget.hintCell,
        cellSize: widget.cellSize,
        origin: widget.origin,
        glowOpacity: 0.5,
      ),
    );
  }
}

/// Paints the golden glow hexagon for the hint highlight.
class _HintCellPainter extends CustomPainter {
  final HexCell cell;
  final double cellSize;
  final Offset origin;
  final double glowOpacity;

  static const _glowColor = HoneyTheme.honeyGold;
  static const _borderColor = HoneyTheme.honeyGoldDark;
  static const _glowScale = 0.9;
  static const _borderWidth = 3.0;

  _HintCellPainter({
    required this.cell,
    required this.cellSize,
    required this.origin,
    required this.glowOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = HexUtils.axialToPixel(cell.q, cell.r, cellSize, origin);
    final hexPath = _createHexPath(center, cellSize * _glowScale);

    // Draw golden fill with animated opacity
    final fillPaint = Paint()
      ..color = _glowColor.withValues(alpha: glowOpacity * 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawPath(hexPath, fillPaint);

    // Draw golden border
    final borderPaint = Paint()
      ..color = _borderColor.withValues(alpha: glowOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _borderWidth;
    canvas.drawPath(hexPath, borderPaint);
  }

  Path _createHexPath(Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      // Flat-top hex: first vertex at 0 degrees
      final angle = (60 * i) * pi / 180;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_HintCellPainter oldDelegate) {
    return cell != oldDelegate.cell ||
        cellSize != oldDelegate.cellSize ||
        origin != oldDelegate.origin ||
        glowOpacity != oldDelegate.glowOpacity;
  }
}
