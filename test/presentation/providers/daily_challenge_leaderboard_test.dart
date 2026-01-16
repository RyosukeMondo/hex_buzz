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

  group('DailyChallengeLeaderboardNotifier', () {
    final testDate = DateTime(2024, 1, 15);

    group('build', () {
      test('loads daily challenge leaderboard on initialization', () async {
        when(
          () => mockRepository.getDailyChallengeLeaderboard(
            date: testDate,
            limit: 100,
          ),
        ).thenAnswer((_) async => testLeaderboardEntries);

        container.read(dailyChallengeLeaderboardProvider(testDate));
        await container.read(
          dailyChallengeLeaderboardProvider(testDate).future,
        );

        verify(
          () => mockRepository.getDailyChallengeLeaderboard(
            date: testDate,
            limit: 100,
          ),
        ).called(1);

        final state = container.read(
          dailyChallengeLeaderboardProvider(testDate),
        );
        expect(state.value?.entries, testLeaderboardEntries);
        expect(state.value?.date, testDate);
        expect(state.value?.error, isNull);
        expect(state.value?.isLoading, false);
      });

      test('handles error during initialization', () async {
        when(
          () => mockRepository.getDailyChallengeLeaderboard(
            date: testDate,
            limit: 100,
          ),
        ).thenThrow(Exception('Network error'));

        await container.read(
          dailyChallengeLeaderboardProvider(testDate).future,
        );

        final state = container.read(
          dailyChallengeLeaderboardProvider(testDate),
        );
        expect(state.value?.entries, isEmpty);
        expect(state.value?.date, testDate);
        expect(state.value?.error, contains('Network error'));
      });
    });

    group('refresh', () {
      test('refreshes daily challenge leaderboard successfully', () async {
        when(
          () => mockRepository.getDailyChallengeLeaderboard(
            date: testDate,
            limit: 100,
          ),
        ).thenAnswer((_) async => testLeaderboardEntries);

        await container.read(
          dailyChallengeLeaderboardProvider(testDate).future,
        );

        final updatedEntries = [
          ...testLeaderboardEntries,
          LeaderboardEntry(
            userId: 'user4',
            username: 'Player4',
            totalStars: 70,
            rank: 4,
            updatedAt: testDate,
          ),
        ];
        when(
          () => mockRepository.getDailyChallengeLeaderboard(
            date: testDate,
            limit: 100,
          ),
        ).thenAnswer((_) async => updatedEntries);

        final notifier = container.read(
          dailyChallengeLeaderboardProvider(testDate).notifier,
        );
        await notifier.refresh();

        final state = container.read(
          dailyChallengeLeaderboardProvider(testDate),
        );
        expect(state.value?.entries, updatedEntries);
        expect(state.value?.date, testDate);
        expect(state.value?.error, isNull);

        verify(
          () => mockRepository.getDailyChallengeLeaderboard(
            date: testDate,
            limit: 100,
          ),
        ).called(2);
      });

      test('handles error during refresh', () async {
        when(
          () => mockRepository.getDailyChallengeLeaderboard(
            date: testDate,
            limit: 100,
          ),
        ).thenAnswer((_) async => testLeaderboardEntries);

        await container.read(
          dailyChallengeLeaderboardProvider(testDate).future,
        );

        when(
          () => mockRepository.getDailyChallengeLeaderboard(
            date: testDate,
            limit: 100,
          ),
        ).thenThrow(Exception('Network error'));

        final notifier = container.read(
          dailyChallengeLeaderboardProvider(testDate).notifier,
        );
        await notifier.refresh();

        final state = container.read(
          dailyChallengeLeaderboardProvider(testDate),
        );
        expect(state.value?.error, contains('Network error'));
        expect(state.value?.date, testDate);
      });
    });
  });

  group('DailyChallengeLeaderboardState', () {
    final testDate = DateTime(2024, 1, 15);

    test('copyWith creates new state with updated values', () {
      final original = DailyChallengeLeaderboardState(
        date: testDate,
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
      expect(updated.date, testDate);
    });

    test('copyWith preserves original values when not specified', () {
      final original = DailyChallengeLeaderboardState(
        date: testDate,
        entries: testLeaderboardEntries,
        isLoading: true,
        error: 'Test error',
      );

      final updated = original.copyWith(isLoading: false);

      expect(updated.entries, testLeaderboardEntries);
      expect(updated.isLoading, false);
      expect(updated.error, 'Test error');
      expect(updated.date, testDate);
    });

    test('copyWith clears error when clearError is true', () {
      final original = DailyChallengeLeaderboardState(
        date: testDate,
        entries: [],
        error: 'Test error',
      );

      final updated = original.copyWith(clearError: true);

      expect(updated.error, isNull);
      expect(updated.entries, isEmpty);
      expect(updated.date, testDate);
    });
  });
}
