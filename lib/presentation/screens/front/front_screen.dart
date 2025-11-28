import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../main.dart';
import '../../providers/auth_provider.dart';
import '../../theme/honey_theme.dart';

/// Front screen with HexBuzz branding and animated "Tap to Start" prompt.
///
/// Displays a centered title with honeycomb-themed background. On tap,
/// navigates based on auth state:
/// - Logged in: [LevelSelectScreen]
/// - Not logged in: [AuthScreen]
class FrontScreen extends ConsumerStatefulWidget {
  const FrontScreen({super.key});

  @override
  ConsumerState<FrontScreen> createState() => _FrontScreenState();
}

class _FrontScreenState extends ConsumerState<FrontScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    final authState = ref.read(authProvider);
    final isLoggedIn = authState.valueOrNull != null;

    final route = isLoggedIn ? AppRoutes.levels : AppRoutes.auth;

    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: _buildBackgroundDecoration(),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  _buildLogo(),
                  const SizedBox(height: HoneyTheme.spacingXl),
                  _buildTitle(),
                  const Spacer(flex: 2),
                  _buildTapPrompt(),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          HoneyTheme.warmCream,
          HoneyTheme.honeyGoldLight.withValues(alpha: 0.3),
          HoneyTheme.warmCream,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HoneyTheme.honeyGold, HoneyTheme.deepHoney],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: HoneyTheme.honeyGoldDark.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(60, 70),
          painter: _HexagonPainter(),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'HexBuzz',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: HoneyTheme.honeyGoldDark,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: HoneyTheme.brownAccent.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(1, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: HoneyTheme.spacingSm),
        Text(
          'One Path Challenge',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: HoneyTheme.textSecondary,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildTapPrompt() {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(opacity: _opacityAnimation.value, child: child);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app_outlined,
            color: HoneyTheme.deepHoney,
            size: HoneyTheme.iconSizeMd,
          ),
          const SizedBox(width: HoneyTheme.spacingSm),
          Text(
            'Tap to Start',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: HoneyTheme.deepHoney,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for a hexagon shape used in the logo.
class _HexagonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = HoneyTheme.honeyGoldDark.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = _createHexagonPath(size);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  Path _createHexagonPath(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;

    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * math.pi / 180;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
