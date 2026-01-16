import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/auth_result.dart';
import '../../../main.dart';
import '../../providers/auth_provider.dart';
import '../../theme/honey_theme.dart';

/// Authentication screen with Google Sign-In as primary authentication method.
///
/// Displays a welcome message with a "Sign in with Google" button following
/// Google's branding guidelines. Shows loading state during authentication
/// and handles authentication errors gracefully.
///
/// On successful authentication, navigates to [LevelSelectScreen].
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authNotifier = ref.read(authProvider.notifier);
    final result = await authNotifier.signInWithGoogle();

    if (!mounted) return;

    setState(() => _isLoading = false);

    switch (result) {
      case AuthSuccess():
        _navigateToLevels();
      case AuthFailure(:final error):
        setState(() => _errorMessage = error);
    }
  }

  Future<void> _playAsGuest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref.read(authProvider.notifier).playAsGuest();

    if (!mounted) return;

    setState(() => _isLoading = false);

    switch (result) {
      case AuthSuccess():
        _navigateToLevels();
      case AuthFailure(:final error):
        setState(() => _errorMessage = error);
    }
  }

  void _navigateToLevels() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.levels);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(HoneyTheme.spacingXl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(),
                const SizedBox(height: HoneyTheme.spacingXxl),
                _buildAuthContainer(),
                const SizedBox(height: HoneyTheme.spacingXl),
                _buildGuestSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        _buildAppIcon(),
        const SizedBox(height: HoneyTheme.spacingLg),
        Text(
          'HexBuzz',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: HoneyTheme.honeyGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: HoneyTheme.spacingSm),
        Text(
          'Welcome!',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: HoneyTheme.textSecondary),
        ),
        const SizedBox(height: HoneyTheme.spacingSm),
        Text(
          'Sign in to compete on leaderboards',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: HoneyTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildAppIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: HoneyTheme.honeyGoldLight,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: HoneyTheme.honeyGold.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.hexagon, size: 64, color: HoneyTheme.textPrimary),
    );
  }

  Widget _buildAuthContainer() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(HoneyTheme.spacingXl),
      decoration: _authContainerDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            _buildErrorMessage(),
            const SizedBox(height: HoneyTheme.spacingLg),
          ],
          _buildGoogleSignInButton(),
        ],
      ),
    );
  }

  BoxDecoration _authContainerDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(HoneyTheme.radiusLg),
      boxShadow: [
        BoxShadow(
          color: HoneyTheme.brownAccent.withValues(alpha: 0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(
        color: HoneyTheme.honeyGoldLight.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    // Following Google's branding guidelines:
    // https://developers.google.com/identity/branding-guidelines
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF3C4043),
          elevation: 1,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: const Color(0xFFDADCE0), width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: _isLoading
            ? _buildLoadingIndicator()
            : _buildGoogleButtonContent(),
      ),
    );
  }

  Widget _buildGoogleButtonContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildGoogleLogo(),
        const SizedBox(width: 24),
        const Text(
          'Sign in with Google',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.25,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleLogo() {
    // Google "G" logo using path for accurate representation
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }

  Widget _buildLoadingIndicator() {
    return const SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(HoneyTheme.honeyGold),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(HoneyTheme.spacingMd),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(HoneyTheme.radiusSm),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade700,
              size: HoneyTheme.iconSizeSm,
              semanticLabel: 'Error',
            ),
            const SizedBox(width: HoneyTheme.spacingSm),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestSection() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        children: [
          _buildDividerWithText('or'),
          const SizedBox(height: HoneyTheme.spacingLg),
          _buildGuestButton(),
          const SizedBox(height: HoneyTheme.spacingMd),
          _buildGuestDisclaimer(),
        ],
      ),
    );
  }

  Widget _buildDividerWithText(String text) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: HoneyTheme.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: HoneyTheme.spacingLg),
          child: Text(
            text,
            style: TextStyle(
              color: HoneyTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: HoneyTheme.textSecondary.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _playAsGuest,
        icon: const Icon(Icons.play_arrow),
        label: const Text(
          'Play as Guest',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: HoneyTheme.deepHoney,
          side: BorderSide(color: HoneyTheme.deepHoney, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestDisclaimer() {
    return Text(
      'Progress saved locally only',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: HoneyTheme.textSecondary,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

/// Custom painter for Google's "G" logo following brand guidelines.
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Google Blue
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -0.52,
      2.09,
      true,
      paint,
    );

    // Google Green
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      1.57,
      2.09,
      true,
      paint,
    );

    // Google Yellow
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      3.665,
      2.09,
      true,
      paint,
    );

    // Google Red
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -2.61,
      2.09,
      true,
      paint,
    );

    // White center circle
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.45,
      paint,
    );

    // Blue segment for center
    paint.color = const Color(0xFF4285F4);
    final path = Path();
    path.moveTo(size.width / 2, size.height / 2);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width, size.height * 0.75);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
