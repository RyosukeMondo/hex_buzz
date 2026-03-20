import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/firebase/firebase_auth_repository.dart';
import '../data/firebase/firestore_daily_challenge_repository.dart';
import '../data/firebase/firestore_friend_repository.dart';
import '../data/firebase/firestore_leaderboard_repository.dart';
import '../data/firebase/firestore_progress_repository.dart';
import '../data/hybrid_auth_repository.dart';
import '../data/local/local_achievement_repository.dart';
import '../data/local/local_guest_auth_repository.dart';
import '../data/local/local_level_pack_repository.dart';
import '../data/local/local_progress_repository.dart';
import '../data/local/local_timed_challenge_repository.dart';
import '../data/local/local_user_level_repository.dart';
import '../domain/services/level_repository.dart';
import '../presentation/providers/achievement_provider.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/daily_challenge_provider.dart';
import '../presentation/providers/editor_provider.dart';
import '../presentation/providers/friend_provider.dart';
import '../presentation/providers/game_provider.dart';
import '../presentation/providers/leaderboard_provider.dart';
import '../presentation/providers/level_pack_provider.dart';
import '../presentation/providers/progress_provider.dart';
import '../presentation/providers/timed_challenge_provider.dart';

/// Initializes all repositories and returns their provider overrides.
Future<List<Override>> buildRepositoryOverrides(
  SharedPreferences prefs,
) async {
  final level = await _initializeLevelRepo();
  final progress = LocalProgressRepository(prefs);
  if (kDebugMode) debugPrint('Progress repository initialized');

  final auth = await _initializeAuthRepo(progress, prefs);

  return [
    levelRepositoryProvider.overrideWithValue(level),
    progressRepositoryProvider.overrideWithValue(progress),
    authRepositoryProvider.overrideWithValue(auth),
    dailyChallengeRepositoryProvider.overrideWithValue(
      FirestoreDailyChallengeRepository(),
    ),
    leaderboardRepositoryProvider.overrideWithValue(
      FirestoreLeaderboardRepository(),
    ),
    achievementRepositoryProvider.overrideWithValue(
      LocalAchievementRepository(prefs),
    ),
    userLevelRepositoryProvider.overrideWithValue(
      LocalUserLevelRepository(prefs),
    ),
    friendRepositoryProvider.overrideWithValue(FirestoreFriendRepository()),
    levelPackRepositoryProvider.overrideWithValue(
      LocalLevelPackRepository(prefs: prefs),
    ),
    timedChallengeRepositoryProvider.overrideWithValue(
      LocalTimedChallengeRepository(prefs),
    ),
  ];
}

Future<LevelRepository> _initializeLevelRepo() async {
  final repo = LevelRepository();
  try {
    await repo.load();
    if (kDebugMode) {
      debugPrint('Loaded pre-generated levels:');
      for (final size in repo.availableSizes) {
        debugPrint('  Size $size: ${repo.getLevelCount(size)} levels');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Failed to load pre-generated levels: $e');
      debugPrint('Will use dynamic generation as fallback.');
    }
  }
  return repo;
}

Future<HybridAuthRepository> _initializeAuthRepo(
  LocalProgressRepository localProgress,
  SharedPreferences prefs,
) async {
  final firebaseAuth = FirebaseAuthRepository();
  final guest = LocalGuestAuthRepository(prefs: prefs);
  final firestoreProgress = FirestoreProgressRepository();

  final auth = HybridAuthRepository(
    firebaseRepo: firebaseAuth,
    guestRepo: guest,
    localProgress: localProgress,
    firestoreProgress: firestoreProgress,
  );

  if (kDebugMode) {
    debugPrint('Hybrid auth repository initialized with migration support');
  }
  return auth;
}
