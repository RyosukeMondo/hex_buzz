import '../models/friend.dart';

/// Abstract interface for friend relationship operations.
///
/// Provides methods for managing friend requests, lookups by friend code,
/// and friend list retrieval. Implementations can use different backends
/// (Firestore, local storage, etc.) while consumers depend only on this
/// interface for dependency injection.
abstract class FriendRepository {
  /// Gets all friend relations for a user.
  ///
  /// Returns a list of [FriendRelation] objects including pending requests,
  /// accepted friends, and blocked users. Sorted by creation date (newest first).
  ///
  /// Returns empty list if the user has no relations or on error.
  Future<List<FriendRelation>> getFriends(String userId);

  /// Sends a friend request using a friend code.
  ///
  /// Looks up the user associated with [friendCode] and creates
  /// bidirectional [FriendRelation] records with pending status.
  ///
  /// Throws [ArgumentError] if the code is invalid or not found.
  /// Throws [StateError] if already friends or request already sent.
  Future<void> sendFriendRequest(String userId, String friendCode);

  /// Accepts a pending friend request.
  ///
  /// Updates both the user's and friend's relation records to accepted status.
  ///
  /// Throws [StateError] if no pending request exists from [friendId].
  Future<void> acceptFriendRequest(String ownerId, String friendId);

  /// Removes a friend relationship.
  ///
  /// Deletes both bidirectional relation records. Works for accepted friends
  /// and pending requests (cancellation).
  Future<void> removeFriend(String ownerId, String friendId);

  /// Gets or creates a friend code for the user.
  ///
  /// If the user already has a friend code, returns it.
  /// Otherwise, generates a new unique 6-character code and stores it.
  ///
  /// Returns the 6-character alphanumeric friend code string.
  Future<String> getOrCreateFriendCode(String userId);

  /// Finds a user ID by their friend code.
  ///
  /// Returns the user ID associated with the given [code],
  /// or null if no user has that code.
  Future<String?> findUserByCode(String code);
}
