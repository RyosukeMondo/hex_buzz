import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/leaderboard_entry.dart';
import 'package:hex_buzz/presentation/providers/leaderboard_provider.dart';
import 'package:mocktail/mocktail.dart';

import 'leaderboard_test_helpers.dart';

void main() {
  late MockLeaderboardRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockLeaderboardRepository();
    container = ProviderContainer(
      overrides: [
        leaderboardRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('LeaderboardNotifier', () {
    group('build', () {
      test('loads top players on initialization', () async {
        when(
          () => mockRepository.getTopPlayers(limit: 100),
        ).thenAnswer((_) async => testLeaderboardEntries);

        container.read(leaderboardProvider);
        await container.read(leaderboardProvider.future);

        verify(() => mockRepository.getTopPlayers(limit: 100)).called(1);

        final state = container.read(leaderboardProvider);
        expect(state.value?.entries, testLeaderboardEntries);
        expect(state.value?.error, isNull);
        expect(state.value?.isLoading, false);
      });

      test('handles error during initialization', () async {
        when(
          () => mockRepository.getTopPlayers(limit: 100),
        ).thenThrow(Exception('Network error'));

        await container.read(leaderboardProvider.future);

        final state = container.read(leaderboardProvider);
        expect(state.value?.entries, isEmpty);
        expect(state.value?.error, contains('Network error'));
      });
    });

    group('refresh', () {
      test('refreshes leaderboard data successfully', () async {
        when(
          () => mockRepository.getTopPlayers(limit: 100),
        ).thenAnswer((_) async => testLeaderboardEntries);

        await container.read(leaderboardProvider.future);

        final updatedEntries = [
          ...testLeaderboardEntries,
          LeaderboardEntry(
            userId: 'user4',
            username: 'Player4',
            totalStars: 70,
            rank: 4,
            updatedAt: DateTime(2024, 1, 2),
          ),
        ];
        when(
          () => mockRepository.getTopPlayers(limit: 100),
        ).thenAnswer((_) async => updatedEntries);

        final notifier = container.read(leaderboardProvider.notifier);
        await notifier.refresh();

        final state = container.read(leaderboardProvider);
        expect(state.value?.entries, updatedEntries);
        expect(state.value?.error, isNull);
        verify(() => mockRepository.getTopPlayers(limit: 100)).called(2);
      });

      test('handles error during refresh', () async {
        when(
          () => mockRepository.getTopPlayers(limit: 100),
        ).thenAnswer((_) async => testLeaderboardEntries);

        await container.read(leaderboardProvider.future);

        when(
          () => mockRepository.getTopPlayers(limit: 100),
        ).thenThrow(Exception('Network error'));

        final notifier = container.read(leaderboardProvider.notifier);
        await notifier.refresh();

        final state = container.read(leaderboardProvider);
        expect(state.value?.error, contains('Network error'));
      });
    });

    group('fetchUserRank', () {
      test('fetches user rank successfully', () async {
        when(
          () => mockRepository.getTopPlayers(limit: 100),
        ).thenAnswer((_) async => testLeaderboardEntries);
        when(
          () => mockRepository.getUserRank('current-user'),
        ).thenAnswer((_) async => testUserEntry);

        await container.read(leaderboardProvider.future);

        final notifier = container.read(leaderboardProvider.notifier);
        await notifier.fetchUserRank('current-user');

        final state = container.read(leaderboardProvider);
        expect(state.value?.userEntry, testUserEntry);
        expect(state.value?.error, isNull);
        expect(state.value?.isLoading, false);
        verify(() => mockRepository.getUserRank('current-user')).called(1);
      });

      test('handles error when fetching user rank', () async {
        when(
          () => mockRepository.getTopPlayers(limit: 100),
        ).thenAnswer((_) async => testLeaderboardEntries);
        when(
          () => mockRepository.getUserRank('current-user'),
        ).thenThrow(Exception('User not found'));

        await container.read(leaderboardProvider.future);

        final notifier = container.read(leaderboardProvider.notifier);
        await notifier.fetchUserRank('current-user');

        final state = container.read(leaderboardProvider);
        expect(state.value?.userEntry, isNull);
        expect(state.value?.error, contains('User not found'));
        expect(state.value?.isLoading, false);
      });

      test('clears loading state after fetch completes', () async {
        when(
          () => mockRepository.getTopPlayers(limit: 100),
        ).thenAnswer((_) async => testLeaderboardEntries);
        when(
          () => mockRepository.getUserRank('current-user'),
        ).thenAnswer((_) async => testUserEntry);

        await container.read(leaderboardProvider.future);

        final notifier = container.read(leaderboardProvider.notifier);
        await notifier.fetchUserRank('current-user');

        final finalState = container.read(leaderboardProvider);
        expect(finalState.value?.isLoading, false);
        expect(finalState.value?.userEntry, testUserEntry);
      });
    });

    group('submitScore', () {
      test('submits score successfully and refreshes', () async {
        when(
          () => mockRepository.getTopPlayers(limit: 100),
        ).thenAnswer((_) async => testLeaderboardEntries);
        when(
          () => mockRepository.submitScore(
            userId: 'current-user',
            stars: 85,
            levelId: 'level-1',
          ),
        ).thenAnswer((_) async => true);

        await container.read(leaderboardProvider.future);

        final notifier = container.read(leaderboardProvider.notifier);
        final success = await notifier.submitScore(
          userId: 'current-user',
          stars: 85,
          levelId: 'level-1',
        );

        expect(success, true);
        verify(
          () => mockRepository.submitScore(
            userId: 'current-user',
            stars: 85,
            levelId: 'level-1',
          ),
        ).called(1);
        verify(() => mockRepository.getTopPlayers(limit: 100)).called(2);
      });

      test('returns false and sets error when submission fails', () async {
        when(
          () => mockRepository.getTopPlayers(limit: 100),
        ).thenAnswer((_) async => testLeaderboardEntries);
        when(
          () => mockRepository.submitScore(
            userId: 'current-user',
            stars: 85,
            levelId: 'level-1',
          ),
        ).thenThrow(Exception('Submission failed'));

        await container.read(leaderboardProvider.future);

        final notifier = container.read(leaderboardProvider.notifier);
        final success = await notifier.submitScore(
          userId: 'current-user',
          stars: 85,
          levelId: 'level-1',
        );

        expect(success, false);
        final state = container.read(leaderboardProvider);
        expect(state.value?.error, contains('Submission failed'));
        verify(() => mockRepository.getTopPlayers(limit: 100)).called(1);
      });

      test('returns false when submission returns false', () async {
        when(
          () => mockRepository.getTopPlayers(limit: 100),
        ).thenAnswer((_) async => testLeaderboardEntries);
        when(
          () => mockRepository.submitScore(
            userId: 'current-user',
            stars: 85,
            levelId: 'level-1',
          ),
        ).thenAnswer((_) async => false);

        await container.read(leaderboardProvider.future);

        final notifier = container.read(leaderboardProvider.notifier);
        final success = await notifier.submitScore(
          userId: 'current-user',
          stars: 85,
          levelId: 'level-1',
        );

        expect(success, false);
        verify(() => mockRepository.getTopPlayers(limit: 100)).called(1);
      });

      test('submits score without levelId', () async {
        when(
          () => mockRepository.getTopPlayers(limit: 100),
        ).thenAnswer((_) async => testLeaderboardEntries);
        when(
          () => mockRepository.submitScore(
            userId: 'current-user',
            stars: 85,
            levelId: null,
          ),
        ).thenAnswer((_) async => true);

        await container.read(leaderboardProvider.future);

        final notifier = container.read(leaderboardProvider.notifier);
        final success = await notifier.submitScore(
          userId: 'current-user',
          stars: 85,
        );

        expect(success, true);
        verify(
          () => mockRepository.submitScore(
            userId: 'current-user',
            stars: 85,
            levelId: null,
          ),
        ).called(1);
      });
    });

    group('loadMore', () {
      test('loads more entries successfully', () async {
        when(
          () => mockRepository.getTopPlayers(limit: 100),
        ).thenAnswer((_) async => testLeaderboardEntries);

        await container.read(leaderboardProvider.future);

        final moreEntries = [
          LeaderboardEntry(
            userId: 'user4',
            username: 'Player4',
            totalStars: 70,
            rank: 4,
            updatedAt: DateTime(2024, 1, 1),
          ),
          LeaderboardEntry(
            userId: 'user5',
            username: 'Player5',
            totalStars: 60,
            rank: 5,
            updatedAt: DateTime(2024, 1, 1),
          ),
        ];
        when(
          () => mockRepository.getTopPlayers(limit: 50, offset: 3),
        ).thenAnswer((_) async => moreEntries);

        final notifier = container.read(leaderboardProvider.notifier);
        await notifier.loadMore();

        final state = container.read(leaderboardProvider);
        expect(state.value?.entries.length, 5);
        expect(state.value?.entries, [
          ...testLeaderboardEntries,
          ...moreEntries,
        ]);
        expect(state.value?.isLoading, false);
        verify(
          () => mockRepository.getTopPlayers(limit: 50, offset: 3),
        ).called(1);
      });

      test('handles error when loading more', () async {
        when(
          () => mockRepository.getTopPlayers(limit: 100),
        ).thenAnswer((_) async => testLeaderboardEntries);

        await container.read(leaderboardProvider.future);

        when(
          () => mockRepository.getTopPlayers(limit: 50, offset: 3),
        ).thenThrow(Exception('Load error'));

        final notifier = container.read(leaderboardProvider.notifier);
        await notifier.loadMore();

        final state = container.read(leaderboardProvider);
        expect(state.value?.entries, testLeaderboardEntries);
        expect(state.value?.error, contains('Load error'));
        expect(state.value?.isLoading, false);
      });

      test('does not load more when already loading', () async {
        when(
          () => mockRepository.getTopPlayers(limit: 100),
        ).thenAnswer((_) async => testLeaderboardEntries);

        await container.read(leaderboardProvider.future);

        when(
          () => mockRepository.getTopPlayers(limit: 50, offset: 3),
        ).thenAnswer(
          (_) => Future.delayed(const Duration(milliseconds: 100), () => []),
        );

        final notifier = container.read(leaderboardProvider.notifier);
        final loadMoreFuture = notifier.loadMore();

        await Future.delayed(const Duration(milliseconds: 10));
        await notifier.loadMore();
        await loadMoreFuture;

        verify(
          () => mockRepository.getTopPlayers(limit: 50, offset: 3),
        ).called(1);
      });
    });
  });

  group('LeaderboardState', () {
    test('copyWith creates new state with updated values', () {
      const original = LeaderboardState(
        entries: [],
        isLoading: false,
        error: null,
      );

      final updated = original.copyWith(
        entries: testLeaderboardEntries,
        isLoading: true,
        error: 'Test error',
      );

      expect(updated.entries, testLeaderboardEntries);
      expect(updated.isLoading, true);
      expect(updated.error, 'Test error');
      expect(updated.userEntry, isNull);
    });

    test('copyWith preserves original values when not specified', () {
      final original = LeaderboardState(
        entries: testLeaderboardEntries,
        userEntry: testUserEntry,
        isLoading: true,
        error: 'Test error',
      );

      final updated = original.copyWith(isLoading: false);

      expect(updated.entries, testLeaderboardEntries);
      expect(updated.userEntry, testUserEntry);
      expect(updated.isLoading, false);
      expect(updated.error, 'Test error');
    });

    test('copyWith clears userEntry when clearUserEntry is true', () {
      final original = LeaderboardState(
        entries: testLeaderboardEntries,
        userEntry: testUserEntry,
      );

      final updated = original.copyWith(clearUserEntry: true);

      expect(updated.userEntry, isNull);
      expect(updated.entries, testLeaderboardEntries);
    });

    test('copyWith clears error when clearError is true', () {
      const original = LeaderboardState(entries: [], error: 'Test error');

      final updated = original.copyWith(clearError: true);

      expect(updated.error, isNull);
      expect(updated.entries, isEmpty);
    });
  });
}
