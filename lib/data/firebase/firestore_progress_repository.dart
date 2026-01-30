import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/progress_state.dart';
import '../../domain/services/progress_repository.dart';

/// Firestore implementation of [ProgressRepository].
///
/// Stores player progress in Firestore with real-time synchronization.
/// Progress is stored per-user in the users/{userId}/progress collection.
/// Handles network errors gracefully by returning empty state on failures.
class FirestoreProgressRepository implements ProgressRepository {
  final FirebaseFirestore _firestore;

  FirestoreProgressRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Gets the progress collection reference for a specific user.
  CollectionReference _getProgressCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('progress');
  }

  @override
  Future<ProgressState> loadForUser(String userId) async {
    try {
      final snapshot = await _getProgressCollection(userId).get();

      if (snapshot.docs.isEmpty) {
        return const ProgressState.empty();
      }

      final levelsMap = <int, LevelProgress>{};

      for (final doc in snapshot.docs) {
        try {
          final levelIndex = int.parse(doc.id);
          final data = doc.data() as Map<String, dynamic>;
          levelsMap[levelIndex] = LevelProgress.fromJson(data);
        } catch (e) {
          // Skip invalid entries
          continue;
        }
      }

      return ProgressState(levels: levelsMap);
    } catch (e) {
      // Return empty state on error
      return const ProgressState.empty();
    }
  }

  @override
  Future<void> saveForUser(String userId, ProgressState state) async {
    final batch = _firestore.batch();
    final collection = _getProgressCollection(userId);

    for (final entry in state.levels.entries) {
      final levelIndex = entry.key;
      final progress = entry.value;
      final docRef = collection.doc(levelIndex.toString());

      batch.set(docRef, {
        ...progress.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  @override
  Future<void> resetForUser(String userId) async {
    final snapshot = await _getProgressCollection(userId).get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Saves progress for a single level.
  ///
  /// More efficient than saving the entire state when only one level changes.
  Future<void> saveLevelProgress(
    String userId,
    int levelIndex,
    LevelProgress progress,
  ) async {
    final docRef = _getProgressCollection(userId).doc(levelIndex.toString());
    await docRef.set({
      ...progress.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Watches progress changes for a user in real-time.
  ///
  /// Returns a stream that emits updated progress whenever Firestore data changes.
  Stream<ProgressState> watchProgress(String userId) {
    return _getProgressCollection(userId).snapshots().map((snapshot) {
      final levelsMap = <int, LevelProgress>{};

      for (final doc in snapshot.docs) {
        try {
          final levelIndex = int.parse(doc.id);
          final data = doc.data() as Map<String, dynamic>;
          levelsMap[levelIndex] = LevelProgress.fromJson(data);
        } catch (e) {
          // Skip invalid entries
          continue;
        }
      }

      return ProgressState(levels: levelsMap);
    });
  }
}
