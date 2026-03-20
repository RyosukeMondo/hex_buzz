import 'package:flutter/material.dart';

import '../../../../domain/models/friend.dart';
import '../../../theme/honey_theme.dart';

/// Displays a list of accepted friends with long-press to remove.
///
/// Each friend tile shows their avatar initial, username, and status.
/// Long-pressing a friend triggers the remove callback with confirmation.
class FriendListSection extends StatelessWidget {
  /// The list of accepted friend relations to display.
  final List<FriendRelation> friends;

  /// Callback invoked with the friend's user ID when the user requests removal.
  final Future<void> Function(String friendId) onRemoveFriend;

  const FriendListSection({
    super.key,
    required this.friends,
    required this.onRemoveFriend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: friends.map((friend) => _buildFriendTile(friend)).toList(),
    );
  }

  String _formatFriendSince(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildFriendTile(FriendRelation friend) {
    final friendSince = _formatFriendSince(friend.createdAt);
    return Semantics(
      label: '${friend.friendUsername}, friend since $friendSince',
      child: GestureDetector(
        onLongPress: () => onRemoveFriend(friend.friendId),
        child: Container(
          margin: const EdgeInsets.only(bottom: HoneyTheme.spacingSm),
          padding: const EdgeInsets.all(HoneyTheme.spacingMd),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: CircleAvatar(
                  backgroundColor: HoneyTheme.honeyGoldLight,
                  child: Text(
                    friend.friendUsername.isNotEmpty
                        ? friend.friendUsername[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: HoneyTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: HoneyTheme.spacingMd),
              Expanded(
                child: Text(
                  friend.friendUsername,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: HoneyTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ExcludeSemantics(
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: HoneyTheme.iconSizeMd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
