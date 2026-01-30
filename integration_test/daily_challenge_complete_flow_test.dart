// Integration test for daily challenge complete flow.
//
// Tests the full user journey: notification → start → suspend → resume → complete → share
// Validates one-attempt-per-day enforcement and timer preservation.
//
// To run: flutter test integration_test/daily_challenge_complete_flow_test.dart

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/daily_challenge.dart';
import 'package:hex_buzz/domain/models/daily_challenge_completion.dart';
import 'package:hex_buzz/domain/models/daily_challenge_state.dart';
import 'package:hex_buzz/domain/models/leaderboard_entry.dart';
import 'package:hex_buzz/domain/models/user.dart';
import 'package:hex_buzz/domain/services/daily_challenge_repository.dart';
import 'package:hex_buzz/presentation/providers/auth_provider.dart';
import 'package:hex_buzz/presentation/providers/daily_challenge_provider.dart';
import 'package:hex_buzz/presentation/screens/daily_challenge/daily_challenge_screen.dart';
import 'package:hex_buzz/presentation/theme/honey_theme.dart';
import 'package:hex_buzz/presentation/widgets/daily_challenge_completion_dialog.dart';
import 'package:hex_buzz/presentation/widgets/share_button.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository authRepo;
  late MockDailyChallengeRepository dailyChallengeRepo;
  late User testUser1;
  late User testUser2;

  setUp(() {
    authRepo = MockAuthRepository();
    dailyChallengeRepo = MockDailyChallengeRepository();
    testUser1 = User(
      id: 'user1',
      username: 'TestUser1',
      createdAt: DateTime.now(),
      isGuest: false,
    );
    testUser2 = User(
      id: 'user2',
      username: 'TestUser2',
      createdAt: DateTime.now(),
      isGuest: false,
    );
  });

  tearDown(() => authRepo.dispose());

  Widget buildApp(User currentUser) {
    // Set current user in mock auth repo
    authRepo.setCurrentUser(currentUser);

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        dailyChallengeRepositoryProvider.overrideWithValue(dailyChallengeRepo),
      ],
      child: MaterialApp(
        title: 'HexBuzz - Daily Challenge Test',
        theme: HoneyTheme.lightTheme,
        home: const DailyChallengeScreen(),
      ),
    );
  }

  group('Daily Challenge Complete Flow E2E', () {
    testWidgets(
      'User 1: Start → Suspend → Resume → Complete → Share buttons visible',
      (tester) async {
        await tester.pumpWidget(buildApp(testUser1));
        await tester.pumpAndSettle();

        // Should start in NotStarted state with "Start Challenge" button
        expect(find.text('Start Challenge'), findsOneWidget);
        expect(find.text("Today's Challenge"), findsOneWidget);

        // Tap "Start Challenge"
        await tester.tap(find.text('Start Challenge'));
        await tester.pumpAndSettle();

        // Should transition to Playing state
        // The UI should show the game board or "Playing" state indicator
        final playingState =
            dailyChallengeRepo.getCurrentState(testUser1.id);
        expect(playingState, isA<DailyChallengeStatePlaying>());

        final startTime = (playingState as DailyChallengeStatePlaying).startTime;
        print('Challenge started at: $startTime');

        // Suspend the challenge
        await tester.runAsync(() async {
          // Simulate user leaving the app or tapping suspend
          final container = ProviderScope.containerOf(
            tester.element(find.byType(DailyChallengeScreen)),
          );
          container
              .read(dailyChallengeProvider(testUser1.id).notifier)
              .suspend();
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();

        // Should transition to Suspended state
        final suspendedState =
            dailyChallengeRepo.getCurrentState(testUser1.id);
        expect(suspendedState, isA<DailyChallengeStateSuspended>());

        // Verify startTime is preserved
        expect(
          (suspendedState as DailyChallengeStateSuspended).startTime,
          equals(startTime),
        );
        print('Challenge suspended, startTime preserved: $startTime');

        // Resume the challenge
        await tester.runAsync(() async {
          final container = ProviderScope.containerOf(
            tester.element(find.byType(DailyChallengeScreen)),
          );
          container
              .read(dailyChallengeProvider(testUser1.id).notifier)
              .resume();
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();

        // Should transition back to Playing state with same startTime
        final resumedState =
            dailyChallengeRepo.getCurrentState(testUser1.id);
        expect(resumedState, isA<DailyChallengeStatePlaying>());
        expect(
          (resumedState as DailyChallengeStatePlaying).startTime,
          equals(startTime),
        );
        print('Challenge resumed, startTime still: $startTime');

        // Complete the challenge
        await tester.runAsync(() async {
          final container = ProviderScope.containerOf(
            tester.element(find.byType(DailyChallengeScreen)),
          );
          await container
              .read(dailyChallengeProvider(testUser1.id).notifier)
              .complete(3); // 3 stars
          await Future.delayed(const Duration(milliseconds: 500));
        });
        await tester.pumpAndSettle();

        // Should show completion dialog
        expect(
          find.byType(DailyChallengeCompletionDialog),
          findsOneWidget,
        );

        // Verify share buttons are present
        expect(find.byType(ShareButton), findsWidgets);
        expect(find.text('Twitter'), findsOneWidget);
        expect(find.text('Misskey'), findsOneWidget);
        expect(find.text('Facebook'), findsOneWidget);

        // Verify completion data
        final completion = await dailyChallengeRepo.getCompletion(
          userId: testUser1.id,
          dateId: dailyChallengeRepo.todaysDateId,
        );
        expect(completion, isNotNull);
        expect(completion!.stars, equals(3));
        expect(completion.rank, equals(1)); // First to complete

        print(
          'Challenge completed! Stars: ${completion.stars}, Rank: ${completion.rank}, Time: ${completion.completionTimeMs}ms',
        );
      },
    );

    testWidgets(
      'User 1 cannot retry after completion - shows AlreadyCompleted state',
      (tester) async {
        // User 1 has already completed the challenge in the previous test
        // (repository maintains state across test widgets in same test group)
        await dailyChallengeRepo.submitChallengeCompletion(
          userId: testUser1.id,
          stars: 3,
          completionTimeMs: 30000,
        );

        await tester.pumpWidget(buildApp(testUser1));
        await tester.pumpAndSettle();

        // Should show "Already Completed" state, not "Start Challenge"
        expect(find.text('Start Challenge'), findsNothing);
        expect(find.text('Retry'), findsNothing);
        expect(find.text('Challenge Complete!'), findsOneWidget);

        // State should be AlreadyCompleted
        final state = dailyChallengeRepo.getCurrentState(testUser1.id);
        expect(state, isA<DailyChallengeStateAlreadyCompleted>());

        print('User 1 cannot retry - one-attempt-per-day enforced ✓');
      },
    );

    testWidgets(
      'User 2 can start same challenge after User 1 completes',
      (tester) async {
        // User 2 should be able to start the challenge
        await tester.pumpWidget(buildApp(testUser2));
        await tester.pumpAndSettle();

        // Should show "Start Challenge" button for User 2
        expect(find.text('Start Challenge'), findsOneWidget);

        // Tap "Start Challenge"
        await tester.tap(find.text('Start Challenge'));
        await tester.pumpAndSettle();

        // Should transition to Playing state
        final playingState =
            dailyChallengeRepo.getCurrentState(testUser2.id);
        expect(playingState, isA<DailyChallengeStatePlaying>());

        print('User 2 can start challenge independently ✓');

        // Complete with different stats
        await tester.runAsync(() async {
          final container = ProviderScope.containerOf(
            tester.element(find.byType(DailyChallengeScreen)),
          );
          await container
              .read(dailyChallengeProvider(testUser2.id).notifier)
              .complete(2); // 2 stars
          await Future.delayed(const Duration(milliseconds: 500));
        });
        await tester.pumpAndSettle();

        // Verify User 2's completion
        final completion = await dailyChallengeRepo.getCompletion(
          userId: testUser2.id,
          dateId: dailyChallengeRepo.todaysDateId,
        );
        expect(completion, isNotNull);
        expect(completion!.stars, equals(2));
        expect(completion.rank, equals(2)); // Second to complete

        print('User 2 completed with rank: ${completion.rank} ✓');
      },
    );

    testWidgets(
      'Timer cannot be reset - startTime preserved across suspend/resume',
      (tester) async {
        // Reset repo for this test
        dailyChallengeRepo.reset();

        final testUser = User(
          id: 'user3',
          username: 'TestUser3',
          createdAt: DateTime.now(),
          isGuest: false,
        );

        await tester.pumpWidget(buildApp(testUser));
        await tester.pumpAndSettle();

        // Start challenge
        await tester.tap(find.text('Start Challenge'));
        await tester.pumpAndSettle();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(DailyChallengeScreen)),
        );

        final initialState =
            container.read(dailyChallengeProvider(testUser.id));
        expect(initialState, isA<DailyChallengeStatePlaying>());
        final originalStartTime =
            (initialState as DailyChallengeStatePlaying).startTime;

        // Wait a bit to ensure time passes
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 200));
        });

        // Suspend and resume multiple times
        for (int i = 0; i < 3; i++) {
          container.read(dailyChallengeProvider(testUser.id).notifier).suspend();
          await tester.pumpAndSettle();

          final suspendedState =
              container.read(dailyChallengeProvider(testUser.id));
          expect(suspendedState, isA<DailyChallengeStateSuspended>());
          expect(
            (suspendedState as DailyChallengeStateSuspended).startTime,
            equals(originalStartTime),
          );

          await tester.runAsync(() async {
            await Future.delayed(const Duration(milliseconds: 100));
          });

          container.read(dailyChallengeProvider(testUser.id).notifier).resume();
          await tester.pumpAndSettle();

          final resumedState =
              container.read(dailyChallengeProvider(testUser.id));
          expect(resumedState, isA<DailyChallengeStatePlaying>());
          expect(
            (resumedState as DailyChallengeStatePlaying).startTime,
            equals(originalStartTime),
          );

          print('Suspend/resume cycle ${i + 1}: startTime preserved ✓');
        }

        print('Timer cannot be reset - all cycles preserved startTime ✓');
      },
    );

    testWidgets(
      'Leaderboard shows rankings after multiple completions',
      (tester) async {
        // Set up multiple completions
        dailyChallengeRepo.reset();

        for (int i = 1; i <= 5; i++) {
          await dailyChallengeRepo.submitChallengeCompletion(
            userId: 'user$i',
            stars: 3,
            completionTimeMs: 10000 * i,
          );
        }

        // Get leaderboard
        final leaderboard = await dailyChallengeRepo.getChallengeLeaderboard(
          date: DateTime.now(),
          limit: 100,
        );

        expect(leaderboard.length, equals(5));
        expect(leaderboard[0].userId, equals('user1')); // Fastest
        expect(leaderboard[0].rank, equals(1));
        expect(leaderboard[4].userId, equals('user5')); // Slowest
        expect(leaderboard[4].rank, equals(5));

        // Verify sorted by time (ascending)
        for (int i = 0; i < leaderboard.length - 1; i++) {
          expect(
            leaderboard[i].completionTime ?? 0,
            lessThan(leaderboard[i + 1].completionTime ?? 0),
          );
        }

        print('Leaderboard correctly ranked by completion time ✓');
      },
    );
  });
}

/// Mock repository for daily challenge operations in integration tests.
class MockDailyChallengeRepository implements DailyChallengeRepository {
  final Map<String, DailyChallengeCompletion> _completions = {};
  final Map<String, DailyChallengeState> _currentStates = {};
  late DailyChallenge _todaysChallenge;
  int _completionCounter = 0;

  MockDailyChallengeRepository() {
    // Create a simple test challenge
    final testLevel = createSimpleLevel(id: 'daily-$todaysDateId');
    _todaysChallenge = DailyChallenge(
      id: todaysDateId,
      date: DateTime.now(),
      level: testLevel,
      completionCount: 0,
    );
  }

  String get todaysDateId {
    final now = DateTime.now().toUtc();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  DailyChallengeState getCurrentState(String userId) {
    return _currentStates[userId] ?? const DailyChallengeStateLoading();
  }

  void reset() {
    _completions.clear();
    _currentStates.clear();
    _completionCounter = 0;
  }

  @override
  Future<DailyChallenge?> getTodaysChallenge() async {
    await Future.delayed(const Duration(milliseconds: 50)); // Simulate network
    return _todaysChallenge;
  }

  @override
  Future<bool> submitChallengeCompletion({
    required String userId,
    required int stars,
    required int completionTimeMs,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50)); // Simulate network

    final existingCompletion = _completions['$userId:$todaysDateId'];
    if (existingCompletion != null) {
      // Duplicate completion not allowed
      return false;
    }

    _completionCounter++;
    final completion = DailyChallengeCompletion(
      userId: userId,
      dateId: todaysDateId,
      stars: stars,
      completionTimeMs: completionTimeMs,
      completedAt: DateTime.now(),
      rank: _completionCounter, // Simple rank assignment
    );

    _completions['$userId:$todaysDateId'] = completion;

    // Update current state
    _currentStates[userId] = DailyChallengeStateCompleted(completion);

    // Update challenge completion count
    _todaysChallenge = _todaysChallenge.copyWith(
      completionCount: _completions.length,
    );

    return true;
  }

  @override
  Future<List<LeaderboardEntry>> getChallengeLeaderboard({
    required DateTime date,
    int limit = 100,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50)); // Simulate network

    final dateId =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final entries = _completions.entries
        .where((e) => e.value.dateId == dateId)
        .map((e) => LeaderboardEntry(
              userId: e.value.userId,
              username: e.value.userId, // Use userId as username
              totalStars: e.value.stars,
              rank: e.value.rank ?? 0,
              updatedAt: e.value.completedAt,
              completionTime: e.value.completionTimeMs,
              stars: e.value.stars,
            ))
        .toList();

    // Sort by stars (descending) then by time (ascending)
    entries.sort((a, b) {
      final starsCompare = (b.stars ?? 0).compareTo(a.stars ?? 0);
      if (starsCompare != 0) return starsCompare;
      return (a.completionTime ?? 0).compareTo(b.completionTime ?? 0);
    });

    // Update ranks after sorting
    for (int i = 0; i < entries.length; i++) {
      entries[i] = entries[i].copyWith(rank: i + 1);
    }

    return entries.take(limit).toList();
  }

  @override
  Future<bool> hasCompletedToday(String userId) async {
    await Future.delayed(const Duration(milliseconds: 50)); // Simulate network
    return _completions.containsKey('$userId:$todaysDateId');
  }

  @override
  Future<DailyChallengeCompletion?> getCompletion({
    required String userId,
    required String dateId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50)); // Simulate network
    return _completions['$userId:$dateId'];
  }
}
