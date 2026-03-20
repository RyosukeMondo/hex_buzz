import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/friend_provider.dart';
import '../../../theme/honey_theme.dart';

/// Card displaying the user's shareable friend code with a copy button.
///
/// Loads the code asynchronously on first build and caches it.
/// Shows a loading spinner while the code is being fetched.
class FriendCodeCard extends ConsumerStatefulWidget {
  /// Callback invoked when the friend code is loaded.
  final ValueChanged<String> onCodeLoaded;

  const FriendCodeCard({
    super.key,
    required this.onCodeLoaded,
  });

  @override
  ConsumerState<FriendCodeCard> createState() => _FriendCodeCardState();
}

class _FriendCodeCardState extends ConsumerState<FriendCodeCard> {
  String? _code;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCode();
  }

  Future<void> _loadCode() async {
    try {
      final code = await ref.read(friendProvider.notifier).getMyFriendCode();
      if (mounted) {
        setState(() {
          _code = code;
          _isLoading = false;
        });
        widget.onCodeLoaded(code);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HoneyTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HoneyTheme.honeyGold,
            HoneyTheme.honeyGoldLight,
          ],
        ),
        borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: HoneyTheme.brownAccent.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Friend Code',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: HoneyTheme.textPrimary,
            ),
          ),
          const SizedBox(height: HoneyTheme.spacingSm),
          _buildCodeDisplay(),
        ],
      ),
    );
  }

  Widget _buildCodeDisplay() {
    if (_isLoading) {
      return const SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_error != null) {
      return Text(
        'Error loading code',
        style: TextStyle(color: Colors.red.shade700),
      );
    }

    return Semantics(
      label: 'Your friend code is ${_code ?? ''}. Tap to copy',
      button: true,
      child: GestureDetector(
        onTap: _copyCode,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: HoneyTheme.spacingLg,
                  vertical: HoneyTheme.spacingMd,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(HoneyTheme.radiusSm),
                ),
                child: ExcludeSemantics(
                  child: Text(
                    _code ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: HoneyTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: HoneyTheme.spacingSm),
            IconButton(
              onPressed: _copyCode,
              icon: const Icon(Icons.copy),
              color: HoneyTheme.textPrimary,
              tooltip: 'Copy friend code',
            ),
          ],
        ),
      ),
    );
  }

  void _copyCode() {
    if (_code == null) return;
    Clipboard.setData(ClipboardData(text: _code!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Friend code copied to clipboard!')),
    );
  }
}
