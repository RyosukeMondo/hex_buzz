import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/friend.dart';
import '../../domain/models/friend_code.dart';
import '../../domain/services/friend_repository.dart';

/// Firestore implementation of [FriendRepository].
///
/// Uses two Firestore collections:
/// - `friendCodes/{userId}` - stores friend codes with a secondary index on code value
/// - `friends/{userId}/relations/{friendId}` - stores bidirectional friend relations
class FirestoreFriendRepository implements FriendRepository {
  final FirebaseFirestore _firestore;

  FirestoreFriendRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _friendCodesCollection =>
      _firestore.collection('friendCodes');

  CollectionReference<Map<String, dynamic>> _relationsCollection(
    String userId,
  ) => _firestore.collection('friends').doc(userId).collection('relations');

  @override
  Future<List<FriendRelation>> getFriends(String userId) async {
    try {
      final snapshot = await _relationsCollection(userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return FriendRelation.fromJson(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> sendFriendRequest(String userId, String friendCode) async {
    final friendUserId = await _resolveFriendCode(userId, friendCode);
    await _ensureNoExistingRelation(userId, friendUserId);

    final now = DateTime.now();
    final senderUsername = await _getUsername(userId);
    final receiverUsername = await _getUsername(friendUserId);

    await _writeBidirectionalRelation(
      userId: userId,
      friendUserId: friendUserId,
      senderUsername: senderUsername,
      receiverUsername: receiverUsername,
      createdAt: now,
    );
  }

  /// Resolves a friend code to a user ID with validation.
  Future<String> _resolveFriendCode(String userId, String code) async {
    final friendUserId = await findUserByCode(code);
    if (friendUserId == null) {
      throw ArgumentError('No user found with code: $code');
    }
    if (friendUserId == userId) {
      throw ArgumentError('Cannot send a friend request to yourself');
    }
    return friendUserId;
  }

  /// Verifies no existing relation between the two users.
  Future<void> _ensureNoExistingRelation(
    String userId,
    String friendUserId,
  ) async {
    final existingDoc =
        await _relationsCollection(userId).doc(friendUserId).get();
    if (!existingDoc.exists) return;

    final status = existingDoc.data()?['status'] as String?;
    if (status == FriendStatus.accepted.name) {
      throw StateError('Already friends with this user');
    }
    throw StateError('Friend request already exists');
  }

  /// Creates bidirectional friend relation records in a single batch.
  Future<void> _writeBidirectionalRelation({
    required String userId,
    required String friendUserId,
    required String senderUsername,
    required String receiverUsername,
    required DateTime createdAt,
  }) async {
    final batch = _firestore.batch();

    batch.set(
      _relationsCollection(userId).doc(friendUserId),
      FriendRelation(
        ownerId: userId,
        friendId: friendUserId,
        friendUsername: receiverUsername,
        status: FriendStatus.pending,
        createdAt: createdAt,
        isInitiator: true,
      ).toJson(),
    );

    batch.set(
      _relationsCollection(friendUserId).doc(userId),
      FriendRelation(
        ownerId: friendUserId,
        friendId: userId,
        friendUsername: senderUsername,
        status: FriendStatus.pending,
        createdAt: createdAt,
        isInitiator: false,
      ).toJson(),
    );

    await batch.commit();
  }

  @override
  Future<void> acceptFriendRequest(String ownerId, String friendId) async {
    final doc = await _relationsCollection(ownerId).doc(friendId).get();
    if (!doc.exists) {
      throw StateError('No friend request found from this user');
    }

    final data = doc.data()!;
    if (data['status'] != FriendStatus.pending.name) {
      throw StateError('No pending request to accept');
    }

    final batch = _firestore.batch();

    // Update both sides to accepted
    batch.update(
      _relationsCollection(ownerId).doc(friendId),
      {'status': FriendStatus.accepted.name},
    );
    batch.update(
      _relationsCollection(friendId).doc(ownerId),
      {'status': FriendStatus.accepted.name},
    );

    await batch.commit();
  }

  @override
  Future<void> removeFriend(String ownerId, String friendId) async {
    final batch = _firestore.batch();

    batch.delete(_relationsCollection(ownerId).doc(friendId));
    batch.delete(_relationsCollection(friendId).doc(ownerId));

    await batch.commit();
  }

  @override
  Future<String> getOrCreateFriendCode(String userId) async {
    final doc = await _friendCodesCollection.doc(userId).get();
    if (doc.exists) {
      return doc.data()!['code'] as String;
    }

    // Generate a unique code with collision check
    String code;
    bool isUnique;
    do {
      code = FriendCode.generate();
      isUnique = await _isCodeUnique(code);
    } while (!isUnique);

    final friendCode = FriendCode(
      ownerId: userId,
      code: code,
      createdAt: DateTime.now(),
    );

    await _friendCodesCollection.doc(userId).set(friendCode.toJson());
    return code;
  }

  @override
  Future<String?> findUserByCode(String code) async {
    final normalizedCode = code.toUpperCase().trim();
    final snapshot = await _friendCodesCollection
        .where('code', isEqualTo: normalizedCode)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data()['ownerId'] as String;
  }

  /// Checks whether a friend code is unique across all users.
  Future<bool> _isCodeUnique(String code) async {
    final existing = await findUserByCode(code);
    return existing == null;
  }

  /// Retrieves a username from the leaderboard or users collection.
  Future<String> _getUsername(String userId) async {
    // Try leaderboard collection first (most likely to have username)
    final leaderboardDoc =
        await _firestore.collection('leaderboard').doc(userId).get();
    if (leaderboardDoc.exists) {
      return leaderboardDoc.data()?['username'] as String? ?? 'Unknown';
    }

    // Fallback to users collection
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data()?['username'] as String? ?? 'Unknown';
    }

    return 'Unknown';
  }
}
