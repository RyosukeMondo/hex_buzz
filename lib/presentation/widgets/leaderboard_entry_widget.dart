import 'package:flutter/material.dart';

import '../../domain/models/leaderboard_entry.dart';
import '../theme/honey_theme.dart';

/// A widget displaying a single leaderboard entry.
///
/// Shows rank badge, user avatar, username, and star count.
/// Applies special styling for top 3 ranks (gold, silver, bronze medals).
/// Highlights the entry if it represents the current user.
class LeaderboardEntryWidget extends StatelessWidget {
  /// The leaderboard entry data to display.
  final LeaderboardEntry entry;

  /// Whether this entry represents the current user.
  final bool isCurrentUser;

  /// Whether to show completion time (for daily challenges).
  final bool showCompletionTime;

  /// Creates a leaderboard entry widget.
  const LeaderboardEntryWidget({
    super.key,
    required this.entry,
    this.isCurrentUser = false,
    this.showCompletionTime = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: HoneyTheme.spacingMd),
      padding: const EdgeInsets.all(HoneyTheme.spacingLg),
      decoration: _buildDecoration(),
      child: Row(
        children: [
          _buildRankBadge(entry.rank),
          const SizedBox(width: HoneyTheme.spacingMd),
          _buildAvatar(entry.avatarUrl, entry.username),
          const SizedBox(width: HoneyTheme.spacingMd),
          Expanded(child: _buildUserInfo()),
          _buildStarBadge(
            showCompletionTime && entry.stars != null
                ? entry.stars!
                : entry.totalStars,
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildDecoration() {
    return BoxDecoration(
      color: isCurrentUser
          ? HoneyTheme.honeyGoldLight.withValues(alpha: 0.3)
          : Colors.white,
      borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
      border: isCurrentUser
          ? Border.all(color: HoneyTheme.honeyGold, width: 2)
          : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildRankBadge(int rank) {
    Color badgeColor;
    Color textColor;

    if (rank == 1) {
      // Gold medal for 1st place
      badgeColor = const Color(0xFFFFD700);
      textColor = Colors.black87;
    } else if (rank == 2) {
      // Silver medal for 2nd place
      badgeColor = const Color(0xFFC0C0C0);
      textColor = Colors.black87;
    } else if (rank == 3) {
      // Bronze medal for 3rd place
      badgeColor = const Color(0xFFCD7F32);
      textColor = Colors.black87;
    } else {
      // Regular badge for other ranks
      badgeColor = HoneyTheme.brownAccentLight;
      textColor = Colors.white;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, String username) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: HoneyTheme.honeyGoldLight,
        onBackgroundImageError: (_, __) {
          // Fallback handled by backgroundColor
        },
      );
    }

    // Fallback to initial letter avatar
    return CircleAvatar(
      radius: 20,
      backgroundColor: HoneyTheme.honeyGoldLight,
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : '?',
        style: const TextStyle(
          color: HoneyTheme.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 16.0,
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    if (showCompletionTime && entry.completionTime != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entry.username,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
              color: HoneyTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            _formatTime(entry.completionTime!),
            style: const TextStyle(
              fontSize: 14.0,
              color: HoneyTheme.textSecondary,
            ),
          ),
        ],
      );
    }

    return Text(
      entry.username,
      style: TextStyle(
        fontSize: 16.0,
        fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
        color: HoneyTheme.textPrimary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStarBadge(int stars) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HoneyTheme.spacingMd,
        vertical: HoneyTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: HoneyTheme.starFilled,
        borderRadius: BorderRadius.circular(HoneyTheme.radiusSm),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            size: HoneyTheme.iconSizeMd,
            color: Colors.black87,
          ),
          const SizedBox(width: HoneyTheme.spacingXs),
          Text(
            '$stars',
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final ms = (duration.inMilliseconds % 1000) ~/ 10;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${ms.toString().padLeft(2, '0')}';
  }
}
