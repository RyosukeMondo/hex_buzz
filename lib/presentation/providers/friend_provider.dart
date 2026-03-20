import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/friend.dart';
import '../../domain/models/social_leaderboard.dart';
import '../../domain/services/friend_repository.dart';
import 'auth_provider.dart';
import 'leaderboard_provider.dart';

/// Provider for the friend repository (dependency injection point).
///
/// Override this provider in main.dart with a concrete implementation.
final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  throw UnimplementedError(
    'friendRepositoryProvider must be overridden with a concrete implementation',
  );
});

/// AsyncNotifier for managing friend relationships.
///
/// Handles sending requests, accepting requests, removing friends,
/// and retrieving the user's friend code.
class FriendNotifier extends AsyncNotifier<List<FriendRelation>> {
  late FriendRepository _repository;

  @override
  Future<List<FriendRelation>> build() async {
    _repository = ref.watch(friendRepositoryProvider);
    final user = ref.watch(authProvider).valueOrNull;
    if (user == null) return [];
    return _repository.getFriends(user.id);
  }

  /// Sends a friend request using a 6-character friend code.
  ///
  /// Throws if the code is invalid or a request already exists.
  Future<void> sendRequest(String friendCode) async {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) throw StateError('Not authenticated');

    await _repository.sendFriendRequest(user.id, friendCode);
    ref.invalidateSelf();
  }

  /// Accepts a pending friend request from [friendId].
  Future<void> acceptRequest(String friendId) async {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) throw StateError('Not authenticated');

    await _repository.acceptFriendRequest(user.id, friendId);
    ref.invalidateSelf();
  }

  /// Removes a friend or cancels a pending request.
  Future<void> removeFriend(String friendId) async {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) throw StateError('Not authenticated');

    await _repository.removeFriend(user.id, friendId);
    ref.invalidateSelf();
  }

  /// Gets the current user's shareable friend code.
  ///
  /// Creates one if it does not yet exist.
  Future<String> getMyFriendCode() async {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) throw StateError('Not authenticated');

    return _repository.getOrCreateFriendCode(user.id);
  }
}

/// Provider for friend state management.
final friendProvider =
    AsyncNotifierProvider<FriendNotifier, List<FriendRelation>>(
      FriendNotifier.new,
    );

/// Provider that builds a friends-only leaderboard from the global leaderboard.
///
/// Filters global leaderboard entries to only include the current user
/// and their accepted friends, then re-ranks them.
final friendsLeaderboardProvider =
    FutureProvider<List<SocialLeaderboardEntry>>((ref) async {
      final user = ref.watch(authProvider).valueOrNull;
      if (user == null) return [];

      final friends = await ref.watch(friendProvider.future);
      final globalEntries = await ref.watch(globalLeaderboardProvider.future);

      // Build set of accepted friend IDs
      final friendIds = friends
          .where((f) => f.status == FriendStatus.accepted)
          .map((f) => f.friendId)
          .toSet();

      // Filter and map to social entries
      final filtered = globalEntries
          .where((e) => e.userId == user.id || friendIds.contains(e.userId))
          .toList();

      // Sort by total stars descending, then by updatedAt
      filtered.sort((a, b) => b.totalStars.compareTo(a.totalStars));

      // Assign new ranks within the friends leaderboard
      return List.generate(filtered.length, (i) {
        final entry = filtered[i];
        return SocialLeaderboardEntry(
          userId: entry.userId,
          username: entry.username,
          stars: entry.totalStars,
          completionTime: entry.completionTime,
          rank: i + 1,
          isFriend: friendIds.contains(entry.userId),
          isCurrentUser: entry.userId == user.id,
        );
      });
    });
