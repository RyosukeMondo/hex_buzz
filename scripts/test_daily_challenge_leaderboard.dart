import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../lib/firebase_options.dart';

/// Test script to insert and verify daily challenge leaderboard entries
Future<void> main() async {
  print('🧪 Testing Daily Challenge Leaderboard');
  print('=' * 60);

  // Initialize Firebase
  print('📱 Initializing Firebase...');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('✅ Firebase initialized\n');

  final firestore = FirebaseFirestore.instance;
  final today = DateTime.now().toUtc();
  final dateId =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  print('📅 Today\'s date ID: $dateId');
  print('🕐 UTC timestamp: ${today.toIso8601String()}\n');

  // Test user data
  final testUserId = 'test-user-${DateTime.now().millisecondsSinceEpoch}';
  final testUsername = 'Test User';
  final testStars = 3;
  final testTimeMs = 45000; // 45 seconds

  print('👤 Test user data:');
  print('   User ID: $testUserId');
  print('   Username: $testUsername');
  print('   Stars: $testStars');
  print('   Time: ${testTimeMs}ms (${testTimeMs / 1000}s)\n');

  // Step 1: Check if daily challenge exists for today
  print('Step 1: Checking if daily challenge exists for today...');
  final challengeRef = firestore.collection('dailyChallenges').doc(dateId);
  final challengeSnapshot = await challengeRef.get();

  if (!challengeSnapshot.exists) {
    print('⚠️  Daily challenge not found for $dateId');
    print('   Creating placeholder daily challenge...');

    await challengeRef.set({
      'id': dateId,
      'createdAt': today.toIso8601String(),
      'level': {
        'id': 'daily-$dateId',
        'gridSize': 8,
        'difficulty': 'medium',
        'cells': [],
        'startPosition': {'q': 0, 'r': 0},
        'endPosition': {'q': 7, 'r': 7},
      },
      'completionCount': 0,
      'notificationSent': false,
    });
    print('✅ Placeholder challenge created\n');
  } else {
    print('✅ Daily challenge already exists\n');
  }

  // Step 2: Insert test leaderboard entry
  print('Step 2: Inserting test leaderboard entry...');
  final completionRef = challengeRef.collection('completions').doc(testUserId);

  final completionData = {
    'userId': testUserId,
    'username': testUsername,
    'stars': testStars,
    'completionTime': testTimeMs,
    'completedAt': today.toIso8601String(),
  };

  await completionRef.set(completionData);
  print('✅ Test entry inserted\n');

  // Step 3: Verify the entry was inserted
  print('Step 3: Verifying insertion...');
  final verifySnapshot = await completionRef.get();

  if (verifySnapshot.exists) {
    print('✅ Entry exists in Firestore');
    print('   Data: ${verifySnapshot.data()}\n');
  } else {
    print('❌ Entry NOT found in Firestore\n');
    exit(1);
  }

  // Step 4: Query leaderboard (sorted by stars desc, then time asc)
  print('Step 4: Querying leaderboard...');
  final leaderboardQuery = challengeRef
      .collection('completions')
      .orderBy('stars', descending: true)
      .orderBy('completionTime', descending: false);

  final leaderboardSnapshot = await leaderboardQuery.get();

  print('📊 Leaderboard Results:');
  print('   Total entries: ${leaderboardSnapshot.docs.length}');

  if (leaderboardSnapshot.docs.isEmpty) {
    print('❌ No entries found in leaderboard query\n');
    exit(1);
  }

  print('\n   Leaderboard standings:');
  for (var i = 0; i < leaderboardSnapshot.docs.length; i++) {
    final doc = leaderboardSnapshot.docs[i];
    final data = doc.data();
    print(
      '   ${i + 1}. ${data['username']} - ${data['stars']} stars (${data['completionTime']}ms)',
    );
  }
  print('');

  // Step 5: Verify our test entry is in the results
  final foundTestEntry = leaderboardSnapshot.docs.any(
    (doc) => doc.id == testUserId,
  );

  if (foundTestEntry) {
    print('✅ Test entry found in leaderboard query\n');
  } else {
    print('❌ Test entry NOT found in leaderboard query\n');
    exit(1);
  }

  // Step 6: Check Firestore indexes
  print('Step 6: Verifying Firestore indexes...');
  print(
    '   Note: If the query above worked, indexes are configured correctly.',
  );
  print(
    '   If you get an index error, check the Firebase console for index creation.\n',
  );

  // Step 7: Clean up test data (optional)
  print('Step 7: Cleanup');
  print('   Do you want to delete the test entry? (y/n)');

  final input = stdin.readLineSync();
  if (input?.toLowerCase() == 'y') {
    await completionRef.delete();
    print('✅ Test entry deleted\n');
  } else {
    print('⏭️  Test entry kept for manual inspection\n');
  }

  print('=' * 60);
  print('🎉 Test Complete!');
  print('');
  print('Summary:');
  print('  ✅ Daily challenge exists/created');
  print('  ✅ Test entry inserted successfully');
  print('  ✅ Entry appears in Firestore');
  print('  ✅ Leaderboard query returns results');
  print('  ✅ Test entry found in query results');
  print('');
  print('If your app shows 0 entries, check:');
  print('  1. Date calculation (ensure UTC consistency)');
  print('  2. Collection path (dailyChallenges/{dateId}/completions)');
  print('  3. Query ordering (stars DESC, completionTimeMs ASC)');
  print('  4. Firestore security rules (read access to completions)');

  exit(0);
}
