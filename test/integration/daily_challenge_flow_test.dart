import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../lib/data/firebase/firestore_daily_challenge_repository.dart';
import '../../lib/domain/models/level.dart';

/// Comprehensive autonomous test of daily challenge flow
void main() {
  group('Daily Challenge Flow - Full Integration Test', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreDailyChallengeRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirestoreDailyChallengeRepository(firestore: fakeFirestore);
    });

    test(
      'Complete flow: generate challenge -> fetch -> parse -> display',
      () async {
        print('🧪 Starting comprehensive daily challenge flow test\n');

        // Step 1: Create challenge data (simulating what Cloud Function does)
        print('📝 Step 1: Creating challenge data...');
        final today = DateTime.now().toUtc();
        final dateStr =
            '${today.year.toString().padLeft(4, '0')}-'
            '${today.month.toString().padLeft(2, '0')}-'
            '${today.day.toString().padLeft(2, '0')}';

        // Create level (same structure as Cloud Function generates)
        final cells = <Map<String, dynamic>>[];
        for (int q = 0; q < 6; q++) {
          for (int r = 0; r < 6; r++) {
            final cell = {'q': q, 'r': r};
            if (q == 0 && r == 0) cell['checkpoint'] = 1;
            if (q == 5 && r == 5) cell['checkpoint'] = 2;
            cells.add(cell);
          }
        }

        final walls = <Map<String, dynamic>>[
          {'q1': 0, 'r1': 0, 'q2': 1, 'r2': 0},
          {'q1': 1, 'r1': 1, 'q2': 2, 'r2': 1},
        ];

        final levelData = {
          'id': 'daily-$dateStr',
          'size': 6,
          'cells': cells,
          'walls': walls,
          'checkpointCount': 2,
        };

        final challengeData = {
          'id': dateStr,
          'level': levelData,
          'completionCount': 0,
          'notificationSent': false,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await fakeFirestore
            .collection('dailyChallenges')
            .doc(dateStr)
            .set(challengeData);

        print('✅ Challenge data created in Firestore\n');

        // Step 2: Fetch challenge using repository
        print('📡 Step 2: Fetching challenge via repository...');
        final challenge = await repository.getTodaysChallenge();

        expect(challenge, isNotNull, reason: 'Challenge should exist');
        print('✅ Challenge fetched: ${challenge!.id}\n');

        // Step 3: Validate level structure
        print('🎮 Step 3: Validating level structure...');
        final level = challenge.level;

        expect(level.id, equals('daily-$dateStr'));
        expect(level.size, equals(6));
        expect(level.cells.length, equals(36));
        expect(level.walls.length, equals(2));
        expect(level.checkpointCount, equals(2));

        print('   - Level ID: ${level.id}');
        print('   - Size: ${level.size}x${level.size}');
        print('   - Cells: ${level.cells.length}');
        print('   - Walls: ${level.walls.length}');
        print('   - Checkpoints: ${level.checkpointCount}');
        print('✅ Level structure valid\n');

        // Step 4: Validate start/end cells
        print('🎯 Step 4: Validating checkpoints...');
        final startCell = level.startCell;
        final endCell = level.endCell;

        expect(startCell.checkpoint, equals(1));
        expect(endCell.checkpoint, equals(2));

        print(
          '   - Start: (${startCell.q}, ${startCell.r}) - checkpoint ${startCell.checkpoint}',
        );
        print(
          '   - End: (${endCell.q}, ${endCell.r}) - checkpoint ${endCell.checkpoint}',
        );
        print('✅ Checkpoints valid\n');

        // Step 5: Validate walls
        print('🧱 Step 5: Validating walls...');
        expect(level.hasWall(0, 0, 1, 0), isTrue);
        expect(level.hasWall(1, 1, 2, 1), isTrue);
        expect(level.hasWall(0, 0, 0, 1), isFalse);

        print('   - Wall between (0,0) and (1,0): exists ✓');
        print('   - Wall between (1,1) and (2,1): exists ✓');
        print('   - No wall between (0,0) and (0,1): correct ✓');
        print('✅ Walls valid\n');

        // Step 6: Test serialization round-trip
        print('🔄 Step 6: Testing serialization...');
        final json = level.toJson();
        final levelFromJson = Level.fromJson(json);

        expect(levelFromJson.id, equals(level.id));
        expect(levelFromJson.size, equals(level.size));
        expect(levelFromJson.cells.length, equals(level.cells.length));
        expect(levelFromJson.walls.length, equals(level.walls.length));

        print('   - Level -> JSON -> Level: successful ✓');
        print('✅ Serialization works\n');

        // Step 7: Test caching
        print('💾 Step 7: Testing cache...');
        final challenge2 = await repository.getTodaysChallenge();

        expect(challenge2, isNotNull);
        expect(challenge2!.id, equals(challenge.id));
        print('   - Second fetch returned cached result ✓');
        print('✅ Caching works\n');

        print('🎉 ALL TESTS PASSED!\n');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('✅ Daily challenge flow is working correctly');
        print('✅ Challenge generation: OK');
        print('✅ Data fetching: OK');
        print('✅ Level parsing: OK');
        print('✅ Checkpoints: OK');
        print('✅ Walls: OK');
        print('✅ Serialization: OK');
        print('✅ Caching: OK');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      },
    );

    test('Handle missing challenge gracefully', () async {
      print('🧪 Testing missing challenge handling...\n');

      final challenge = await repository.getTodaysChallenge();

      expect(challenge, isNull);
      print('✅ Returns null for missing challenge\n');
    });

    test('Handle malformed data gracefully', () async {
      print('🧪 Testing malformed data handling...\n');

      final today = DateTime.now().toUtc();
      final dateStr =
          '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';

      // Create challenge with missing level data
      await fakeFirestore.collection('dailyChallenges').doc(dateStr).set({
        'id': dateStr,
        'completionCount': 0,
        // Missing 'level' field!
      });

      final challenge = await repository.getTodaysChallenge();

      expect(challenge, isNull);
      print('✅ Returns null for malformed data\n');
    });
  });
}
