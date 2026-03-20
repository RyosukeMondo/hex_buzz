import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/honey_theme.dart';

/// Section with a text input and button for adding friends by code.
///
/// Validates that the entered code is exactly 6 alphanumeric characters
/// before enabling the submit button.
class AddFriendSection extends ConsumerStatefulWidget {
  /// Callback invoked with the entered friend code when the user submits.
  final Future<void> Function(String code) onSendRequest;

  const AddFriendSection({
    super.key,
    required this.onSendRequest,
  });

  @override
  ConsumerState<AddFriendSection> createState() => _AddFriendSectionState();
}

class _AddFriendSectionState extends ConsumerState<AddFriendSection> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValidCode {
    final code = _controller.text.trim();
    return code.length == 6 && RegExp(r'^[A-Za-z0-9]+$').hasMatch(code);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HoneyTheme.spacingLg),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: HoneyTheme.spacingMd),
          _buildInputRow(),
        ],
      ),
    );
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Friend',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: HoneyTheme.textPrimary,
          ),
        ),
        SizedBox(height: HoneyTheme.spacingSm),
        Text(
          'Enter your friend\'s 6-character code',
          style: TextStyle(fontSize: 14, color: HoneyTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildInputRow() {
    return Row(
      children: [
        Expanded(child: _buildCodeTextField()),
        const SizedBox(width: HoneyTheme.spacingSm),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildCodeTextField() {
    return TextField(
      controller: _controller,
      textCapitalization: TextCapitalization.characters,
      maxLength: 6,
      decoration: _buildTextFieldDecoration(),
      style: const TextStyle(
        fontSize: 18,
        letterSpacing: 2,
        fontWeight: FontWeight.w500,
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  InputDecoration _buildTextFieldDecoration() {
    return InputDecoration(
      hintText: 'ABC123',
      labelText: 'Enter friend code',
      counterText: '',
      filled: true,
      fillColor: HoneyTheme.warmCream,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HoneyTheme.radiusSm),
        borderSide: BorderSide(
          color: HoneyTheme.honeyGold.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HoneyTheme.radiusSm),
        borderSide: const BorderSide(
          color: HoneyTheme.honeyGold,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: HoneyTheme.spacingMd,
        vertical: HoneyTheme.spacingMd,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isValidCode && !_isSubmitting ? _handleSubmit : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: HoneyTheme.brownAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: HoneyTheme.spacingLg,
          vertical: HoneyTheme.spacingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoneyTheme.radiusSm),
        ),
      ),
      child: _isSubmitting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text('Add'),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_isValidCode) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.onSendRequest(_controller.text.trim().toUpperCase());
      _controller.clear();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
