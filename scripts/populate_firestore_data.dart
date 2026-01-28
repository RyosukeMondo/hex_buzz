#!/usr/bin/env dart

/// Script to populate Firestore with test data for daily challenge and leaderboard.
///
/// Usage: dart scripts/populate_firestore_data.dart

import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// Import Firebase options
import '../lib/firebase_options.dart';
import '../lib/domain/models/hex_cell.dart';
import '../lib/domain/models/level.dart';

Future<void> main() async {
  print('🔥 Initializing Firebase...');

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.web);

  final firestore = FirebaseFirestore.instance;

  print('\n📝 Step 1: Creating daily challenge for today...');
  await createDailyChallenge(firestore);

  print('\n📝 Step 2: Creating leaderboard entries...');
  await createLeaderboardEntries(firestore);

  print('\n✅ Done! Firestore populated successfully.');
  print('   - Daily challenge created for today');
  print('   - 10 test users added to leaderboard');
  print('\n🚀 You can now test the app!');

  exit(0);
}

/// Creates today's daily challenge in Firestore.
Future<void> createDailyChallenge(FirebaseFirestore firestore) async {
  final today = DateTime.now().toUtc();
  final dateStr = _formatDate(today);

  print('   Creating challenge for date: $dateStr');

  // Generate a simple 6x6 level
  final level = _generateLevel(gridSize: 6, difficulty: 'medium');

  final challengeRef = firestore.collection('dailyChallenges').doc(dateStr);

  // Check if already exists
  final existingDoc = await challengeRef.get();
  if (existingDoc.exists) {
    print('   ⚠️  Challenge already exists for today, skipping...');
    return;
  }

  await challengeRef.set({
    'id': dateStr,
    'createdAt': FieldValue.serverTimestamp(),
    'level': level.toJson(),
    'completionCount': 0,
    'notificationSent': false,
  });

  print('   ✓ Daily challenge created successfully');
}

/// Creates test leaderboard entries.
Future<void> createLeaderboardEntries(FirebaseFirestore firestore) async {
  final testUsers = [
    {'username': 'BeeKeeper', 'stars': 245},
    {'username': 'HoneyHunter', 'stars': 198},
    {'username': 'BuzzMaster', 'stars': 187},
    {'username': 'HiveQueen', 'stars': 165},
    {'username': 'PollenCollector', 'stars': 142},
    {'username': 'NectarSeeker', 'stars': 128},
    {'username': 'WaxWorker', 'stars': 115},
    {'username': 'DroneRanger', 'stars': 98},
    {'username': 'HoneyDipper', 'stars': 87},
    {'username': 'BumbleBuddy', 'stars': 76},
  ];

  int count = 0;
  for (var user in testUsers) {
    final userId = 'test_user_${count + 1}';
    final leaderboardRef = firestore.collection('leaderboard').doc(userId);

    // Check if already exists
    final existingDoc = await leaderboardRef.get();
    if (existingDoc.exists) {
      print(
        '   ⚠️  Leaderboard entry for ${user['username']} already exists, skipping...',
      );
      count++;
      continue;
    }

    await leaderboardRef.set({
      'userId': userId,
      'username': user['username'],
      'avatarUrl': null,
      'totalStars': user['stars'],
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLevel': 'level-${(count ~/ 2) + 1}',
    });

    print(
      '   ✓ Created leaderboard entry for ${user['username']} (${user['stars']} stars)',
    );
    count++;
  }

  print('   ✓ $count leaderboard entries created');
}

/// Generates a level for daily challenge.
Level _generateLevel({required int gridSize, required String difficulty}) {
  final random = Random();
  final cells = <HexCell>[];

  // Generate hexagonal grid
  for (int q = 0; q < gridSize; q++) {
    for (int r = 0; r < gridSize; r++) {
      // Skip cells outside hexagonal shape
      if ((q + r) < gridSize || (q + r) >= gridSize * 2) {
        continue;
      }

      // Random 30% of cells are obstacles
      final isObstacle = random.nextDouble() < 0.3;

      cells.add(HexCell(q: q, r: r, isObstacle: isObstacle));
    }
  }

  // Ensure start and end are not obstacles
  final start = HexCell(q: 0, r: gridSize - 1, isObstacle: false);
  final end = HexCell(q: gridSize - 1, r: gridSize - 1, isObstacle: false);

  // Replace any existing cells at start/end positions
  cells.removeWhere(
    (c) => (c.q == start.q && c.r == start.r) || (c.q == end.q && c.r == end.r),
  );
  cells.add(start);
  cells.add(end);

  return Level(
    id: 'daily-${_formatDate(DateTime.now().toUtc())}',
    gridSize: gridSize,
    difficulty: difficulty,
    cells: cells,
    startPosition: start,
    endPosition: end,
  );
}

/// Formats a DateTime as YYYY-MM-DD.
String _formatDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
