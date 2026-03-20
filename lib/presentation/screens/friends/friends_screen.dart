import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_event.dart';
import '../../../domain/models/friend.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/friend_provider.dart';
import '../../theme/honey_theme.dart';
import 'widgets/add_friend_section.dart';
import 'widgets/friend_code_card.dart';
import 'widgets/friend_list_section.dart';

/// Screen for managing friends and viewing friend codes.
///
/// Displays the user's friend code for sharing, an input to add friends
/// by code, and a list of current friends with pending request management.
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendProvider);

    return Scaffold(
      backgroundColor: HoneyTheme.warmCream,
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: HoneyTheme.honeyGold,
      ),
      body: friendsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(error),
        data: (friends) => _buildContent(friends),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: HoneyTheme.iconSizeLg,
            color: Colors.red,
          ),
          const SizedBox(height: HoneyTheme.spacingLg),
          Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: HoneyTheme.spacingLg),
          ElevatedButton(
            onPressed: () => ref.invalidate(friendProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<FriendRelation> friends) {
    final pendingReceived = friends
        .where((f) => f.status == FriendStatus.pending && !f.isInitiator)
        .toList();
    final pendingSent = friends
        .where((f) => f.status == FriendStatus.pending && f.isInitiator)
        .toList();
    final accepted = friends
        .where((f) => f.status == FriendStatus.accepted)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(HoneyTheme.spacingLg),
      children: [
        FriendCodeCard(
          onCodeLoaded: (code) {},
        ),
        const SizedBox(height: HoneyTheme.spacingLg),
        AddFriendSection(
          onSendRequest: _handleSendRequest,
        ),
        const SizedBox(height: HoneyTheme.spacingXl),
        if (pendingReceived.isNotEmpty) ...[
          _buildSectionTitle('Pending Requests'),
          const SizedBox(height: HoneyTheme.spacingSm),
          ...pendingReceived.map(
            (f) => _buildPendingReceivedTile(f),
          ),
          const SizedBox(height: HoneyTheme.spacingLg),
        ],
        if (pendingSent.isNotEmpty) ...[
          _buildSectionTitle('Sent Requests'),
          const SizedBox(height: HoneyTheme.spacingSm),
          ...pendingSent.map(
            (f) => _buildPendingSentTile(f),
          ),
          const SizedBox(height: HoneyTheme.spacingLg),
        ],
        _buildSectionTitle('Friends (${accepted.length})'),
        const SizedBox(height: HoneyTheme.spacingSm),
        if (accepted.isEmpty)
          _buildEmptyState()
        else
          FriendListSection(
            friends: accepted,
            onRemoveFriend: _handleRemoveFriend,
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: HoneyTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildPendingReceivedTile(FriendRelation relation) {
    return Semantics(
      label: 'Friend request from ${relation.friendUsername}',
      child: Container(
        margin: const EdgeInsets.only(bottom: HoneyTheme.spacingSm),
        padding: const EdgeInsets.all(HoneyTheme.spacingMd),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
          border: Border.all(
            color: HoneyTheme.honeyGold.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: CircleAvatar(
                backgroundColor: HoneyTheme.honeyGoldLight,
                child: Text(
                  relation.friendUsername.isNotEmpty
                      ? relation.friendUsername[0].toUpperCase()
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
                relation.friendUsername,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: HoneyTheme.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _handleAcceptRequest(relation.friendId),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green.shade700,
              ),
              child: const Text('Accept'),
            ),
            TextButton(
              onPressed: () => _handleRemoveFriend(relation.friendId),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade700,
              ),
              child: const Text('Decline'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingSentTile(FriendRelation relation) {
    return Semantics(
      label: 'Friend request sent to ${relation.friendUsername}, pending',
      child: Container(
        margin: const EdgeInsets.only(bottom: HoneyTheme.spacingSm),
        padding: const EdgeInsets.all(HoneyTheme.spacingMd),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: CircleAvatar(
                backgroundColor: HoneyTheme.warmCreamDark,
                child: Text(
                  relation.friendUsername.isNotEmpty
                      ? relation.friendUsername[0].toUpperCase()
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
                relation.friendUsername,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: HoneyTheme.textPrimary,
                ),
              ),
            ),
            const Text(
              'Pending',
              style: TextStyle(
                color: HoneyTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(HoneyTheme.spacingXl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.people_outline,
            size: HoneyTheme.iconSizeLg,
            color: HoneyTheme.textSecondary,
          ),
          SizedBox(height: HoneyTheme.spacingMd),
          Text(
            'No friends yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: HoneyTheme.textPrimary,
            ),
          ),
          SizedBox(height: HoneyTheme.spacingSm),
          Text(
            'Share your friend code or enter a friend\'s code '
            'above to connect and compete on the friends leaderboard.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: HoneyTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendRequest(String code) async {
    try {
      await ref.read(friendProvider.notifier).sendRequest(code);
      ref.read(analyticsServiceProvider).trackEvent(
        AnalyticsEventType.friendRequestSent,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleAcceptRequest(String friendId) async {
    try {
      await ref.read(friendProvider.notifier).acceptRequest(friendId);
      ref.read(analyticsServiceProvider).trackEvent(
        AnalyticsEventType.friendRequestAccepted,
        properties: {'friendId': friendId},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request accepted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleRemoveFriend(String friendId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: const Text('Are you sure you want to remove this friend?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(friendProvider.notifier).removeFriend(friendId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
