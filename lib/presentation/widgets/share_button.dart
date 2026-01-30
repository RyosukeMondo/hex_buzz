import 'package:flutter/material.dart';

/// A reusable button widget for social media sharing.
///
/// Displays an icon above a label with a tap action.
class ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ShareButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  /// Creates a Twitter/X share button.
  factory ShareButton.twitter({required VoidCallback onTap}) {
    return ShareButton(
      icon: Icons.close, // X icon for Twitter/X
      label: 'Twitter',
      color: const Color(0xFF1DA1F2),
      onTap: onTap,
    );
  }

  /// Creates a Misskey share button.
  factory ShareButton.misskey({required VoidCallback onTap}) {
    return ShareButton(
      icon: Icons.public, // Globe icon for federated platform
      label: 'Misskey',
      color: const Color(0xFF86B300),
      onTap: onTap,
    );
  }

  /// Creates a Facebook share button.
  factory ShareButton.facebook({required VoidCallback onTap}) {
    return ShareButton(
      icon: Icons.facebook,
      label: 'Facebook',
      color: const Color(0xFF1877F2),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Share to $label',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
