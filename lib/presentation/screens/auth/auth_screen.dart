import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/auth_result.dart';
import '../../../main.dart';
import '../../providers/auth_provider.dart';
import '../../theme/honey_theme.dart';

/// Authentication mode for the form.
enum AuthMode { login, register }

/// Authentication screen with login/register form and guest play option.
///
/// Displays username/password fields with validation:
/// - Username: minimum 3 characters
/// - Password: minimum 6 characters
///
/// On successful auth, navigates to [LevelSelectScreen].
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AuthMode _mode = AuthMode.login;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == AuthMode.login ? AuthMode.register : AuthMode.login;
      _errorMessage = null;
      _formKey.currentState?.reset();
    });
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) return 'Username is required';
    if (value.length < 3) return 'Username must be at least 3 characters';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (_mode == AuthMode.register && value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authNotifier = ref.read(authProvider.notifier);
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    final result = _mode == AuthMode.login
        ? await authNotifier.login(username, password)
        : await authNotifier.register(username, password);

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
                _buildFormContainer(),
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
        Text(
          'HexBuzz',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: HoneyTheme.honeyGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: HoneyTheme.spacingSm),
        Text(
          _mode == AuthMode.login ? 'Welcome Back!' : 'Create Account',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: HoneyTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildFormContainer() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(HoneyTheme.spacingXl),
      decoration: _formDecoration(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUsernameField(),
            const SizedBox(height: HoneyTheme.spacingLg),
            _buildPasswordField(),
            if (_mode == AuthMode.register) _buildConfirmPasswordField(),
            if (_errorMessage != null) _buildErrorMessage(),
            const SizedBox(height: HoneyTheme.spacingXl),
            _buildSubmitButton(),
            const SizedBox(height: HoneyTheme.spacingLg),
            _buildToggleModeButton(),
          ],
        ),
      ),
    );
  }

  BoxDecoration _formDecoration() {
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

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      validator: _validateUsername,
      enabled: !_isLoading,
      decoration: _inputDecoration(
        label: 'Username',
        icon: Icons.person_outline,
      ),
      textInputAction: TextInputAction.next,
      autocorrect: false,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      validator: _validatePassword,
      enabled: !_isLoading,
      obscureText: _obscurePassword,
      decoration: _inputDecoration(
        label: 'Password',
        icon: Icons.lock_outline,
        suffixIcon: _buildVisibilityToggle(
          obscure: _obscurePassword,
          onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      textInputAction: _mode == AuthMode.register
          ? TextInputAction.next
          : TextInputAction.done,
      onFieldSubmitted: _mode == AuthMode.login ? (_) => _submit() : null,
    );
  }

  Widget _buildConfirmPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(top: HoneyTheme.spacingLg),
      child: TextFormField(
        controller: _confirmPasswordController,
        validator: _validateConfirmPassword,
        enabled: !_isLoading,
        obscureText: _obscureConfirmPassword,
        decoration: _inputDecoration(
          label: 'Confirm Password',
          icon: Icons.lock_outline,
          suffixIcon: _buildVisibilityToggle(
            obscure: _obscureConfirmPassword,
            onToggle: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
          ),
        ),
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _submit(),
      ),
    );
  }

  Widget _buildVisibilityToggle({
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off : Icons.visibility,
        color: HoneyTheme.textSecondary,
        semanticLabel: obscure ? 'Show password' : 'Hide password',
      ),
      onPressed: onToggle,
      tooltip: obscure ? 'Show password' : 'Hide password',
    );
  }

  Widget _buildErrorMessage() {
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: HoneyTheme.spacingLg),
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
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: HoneyTheme.honeyGold,
          foregroundColor: HoneyTheme.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
          ),
          elevation: 2,
        ),
        child: _isLoading ? _buildLoadingIndicator() : _buildSubmitText(),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(HoneyTheme.textPrimary),
      ),
    );
  }

  Widget _buildSubmitText() {
    return Text(
      _mode == AuthMode.login ? 'Log In' : 'Create Account',
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }

  Widget _buildToggleModeButton() {
    return TextButton(
      onPressed: _isLoading ? null : _toggleMode,
      child: Text(
        _mode == AuthMode.login
            ? "Don't have an account? Register"
            : 'Already have an account? Log In',
        style: TextStyle(
          color: HoneyTheme.deepHoney,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: HoneyTheme.honeyGoldDark),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: HoneyTheme.warmCream.withValues(alpha: 0.5),
      border: _inputBorder(HoneyTheme.honeyGoldLight),
      enabledBorder: _inputBorder(
        HoneyTheme.honeyGoldLight.withValues(alpha: 0.5),
      ),
      focusedBorder: _inputBorder(HoneyTheme.honeyGold, width: 2),
      errorBorder: _inputBorder(Colors.red.shade300),
      focusedErrorBorder: _inputBorder(Colors.red.shade400, width: 2),
      labelStyle: TextStyle(color: HoneyTheme.textSecondary),
    );
  }

  OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
      borderSide: BorderSide(color: color, width: width),
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
