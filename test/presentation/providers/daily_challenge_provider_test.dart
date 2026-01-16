import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/daily_challenge.dart';
import 'package:hex_buzz/domain/models/hex_cell.dart';
import 'package:hex_buzz/domain/models/level.dart';
import 'package:hex_buzz/domain/services/daily_challenge_repository.dart';
import 'package:hex_buzz/presentation/providers/daily_challenge_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockDailyChallengeRepository extends Mock
    implements DailyChallengeRepository {}

void main() {
  late MockDailyChallengeRepository mockRepository;
  late ProviderContainer container;

  final testLevel = Level(
    id: 'test-level',
    size: 2,
    cells: {
      (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
      (1, 0): const HexCell(q: 1, r: 0),
      (0, 1): const HexCell(q: 0, r: 1),
      (1, 1): const HexCell(q: 1, r: 1, checkpoint: 2),
    },
    walls: {},
    checkpointCount: 2,
  );

  final testChallenge = DailyChallenge(
    id: '2024-01-01',
    date: DateTime(2024, 1, 1),
    level: testLevel,
    completionCount: 100,
  );

  final completedChallenge = DailyChallenge(
    id: '2024-01-01',
    date: DateTime(2024, 1, 1),
    level: testLevel,
    completionCount: 100,
    userBestTime: 30000,
    userStars: 3,
    userRank: 10,
  );

  setUp(() {
    mockRepository = MockDailyChallengeRepository();

    container = ProviderContainer(
      overrides: [
        dailyChallengeRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('DailyChallengeNotifier', () {
    group('build', () {
      test('loads today\'s challenge on initialization', () async {
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallenge);

        // Access the provider to trigger build
        container.read(dailyChallengeProvider);

        // Wait for async initialization
        final state = await container.read(dailyChallengeProvider.future);

        // Verify getTodaysChallenge was called
        verify(() => mockRepository.getTodaysChallenge()).called(1);

        // Check final state
        expect(state.challenge, testChallenge);
        expect(state.hasCompleted, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.error, isNull);
      });

      test('sets hasCompleted when user has completed challenge', () async {
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => completedChallenge);

        await container.read(dailyChallengeProvider.future);

        final state = container.read(dailyChallengeProvider).requireValue;
        expect(state.challenge, completedChallenge);
        expect(state.hasCompleted, isTrue);
      });

      test('returns null challenge when none available', () async {
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => null);

        await container.read(dailyChallengeProvider.future);

        final state = container.read(dailyChallengeProvider).requireValue;
        expect(state.challenge, isNull);
        expect(state.hasCompleted, isFalse);
      });

      test('handles errors during initialization', () async {
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenThrow(Exception('Network error'));

        await container.read(dailyChallengeProvider.future);

        final state = container.read(dailyChallengeProvider).requireValue;
        expect(state.challenge, isNull);
        expect(state.error, contains('Network error'));
      });
    });

    group('refresh', () {
      test('successfully refreshes challenge data', () async {
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallenge);

        await container.read(dailyChallengeProvider.future);

        // Update mock to return different data
        final updatedChallenge = testChallenge.copyWith(completionCount: 150);
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => updatedChallenge);

        // Perform refresh
        final notifier = container.read(dailyChallengeProvider.notifier);
        await notifier.refresh();

        final state = container.read(dailyChallengeProvider).requireValue;
        expect(state.challenge?.completionCount, 150);
        expect(state.error, isNull);
      });

      test('completes refresh without errors', () async {
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallenge);

        await container.read(dailyChallengeProvider.future);

        // Mock refresh with updated data
        final updatedChallenge = testChallenge.copyWith(completionCount: 200);
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => updatedChallenge);

        final notifier = container.read(dailyChallengeProvider.notifier);

        // Perform refresh
        await notifier.refresh();

        final finalState = container.read(dailyChallengeProvider);
        expect(finalState.requireValue.challenge?.completionCount, 200);
      });

      test('handles errors during refresh', () async {
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallenge);

        await container.read(dailyChallengeProvider.future);

        // Mock error on refresh
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenThrow(Exception('Connection timeout'));

        final notifier = container.read(dailyChallengeProvider.notifier);
        await notifier.refresh();

        final state = container.read(dailyChallengeProvider).requireValue;
        expect(state.error, contains('Connection timeout'));
      });
    });

    group('checkCompletionStatus', () {
      test('updates completion status to true', () async {
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallenge);
        when(
          () => mockRepository.hasCompletedToday('user123'),
        ).thenAnswer((_) async => true);

        await container.read(dailyChallengeProvider.future);

        final notifier = container.read(dailyChallengeProvider.notifier);
        await notifier.checkCompletionStatus('user123');

        verify(() => mockRepository.hasCompletedToday('user123')).called(1);

        final state = container.read(dailyChallengeProvider).requireValue;
        expect(state.hasCompleted, isTrue);
        expect(state.error, isNull);
      });

      test('updates completion status to false', () async {
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => completedChallenge);
        when(
          () => mockRepository.hasCompletedToday('user123'),
        ).thenAnswer((_) async => false);

        await container.read(dailyChallengeProvider.future);

        final notifier = container.read(dailyChallengeProvider.notifier);
        await notifier.checkCompletionStatus('user123');

        final state = container.read(dailyChallengeProvider).requireValue;
        expect(state.hasCompleted, isFalse);
      });

      test('completes status check without errors', () async {
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallenge);
        when(
          () => mockRepository.hasCompletedToday(any()),
        ).thenAnswer((_) async => true);

        await container.read(dailyChallengeProvider.future);

        final notifier = container.read(dailyChallengeProvider.notifier);

        // Perform check
        await notifier.checkCompletionStatus('user123');

        final finalState = container.read(dailyChallengeProvider).requireValue;
        expect(finalState.isLoading, isFalse);
        expect(finalState.hasCompleted, isTrue);
      });

      test('handles errors during completion check', () async {
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallenge);
        when(
          () => mockRepository.hasCompletedToday('user123'),
        ).thenThrow(Exception('Database error'));

        await container.read(dailyChallengeProvider.future);

        final notifier = container.read(dailyChallengeProvider.notifier);
        await notifier.checkCompletionStatus('user123');

        final state = container.read(dailyChallengeProvider).requireValue;
        expect(state.error, contains('Database error'));
        expect(state.isLoading, isFalse);
      });

      test('clears previous errors on successful check', () async {
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallenge);

        await container.read(dailyChallengeProvider.future);

        // First call with error
        when(
          () => mockRepository.hasCompletedToday('user123'),
        ).thenThrow(Exception('Error'));

        final notifier = container.read(dailyChallengeProvider.notifier);
        await notifier.checkCompletionStatus('user123');

        expect(
          container.read(dailyChallengeProvider).requireValue.error,
          isNotNull,
        );

        // Second call succeeds
        when(
          () => mockRepository.hasCompletedToday('user123'),
        ).thenAnswer((_) async => true);

        await notifier.checkCompletionStatus('user123');

        final state = container.read(dailyChallengeProvider).requireValue;
        expect(state.error, isNull);
        expect(state.hasCompleted, isTrue);
      });
    });

    group('submitCompletion', () {
      test('successfully submits completion and refreshes', () async {
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallenge);
        when(
          () => mockRepository.submitChallengeCompletion(
            userId: 'user123',
            stars: 3,
            completionTimeMs: 30000,
          ),
        ).thenAnswer((_) async => true);

        // After submission, return completed challenge
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => completedChallenge);

        await container.read(dailyChallengeProvider.future);

        final notifier = container.read(dailyChallengeProvider.notifier);
        final result = await notifier.submitCompletion(
          userId: 'user123',
          stars: 3,
          completionTimeMs: 30000,
        );

        expect(result, isTrue);

        verify(
          () => mockRepository.submitChallengeCompletion(
            userId: 'user123',
            stars: 3,
            completionTimeMs: 30000,
          ),
        ).called(1);

        // Verify refresh was called (getTodaysChallenge called twice: init + refresh)
        verify(() => mockRepository.getTodaysChallenge()).called(2);

        final state = container.read(dailyChallengeProvider).requireValue;
        expect(state.challenge, completedChallenge);
        expect(state.hasCompleted, isTrue);
      });

      test('returns false when submission fails', () async {
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallenge);
        when(
          () => mockRepository.submitChallengeCompletion(
            userId: 'user123',
            stars: 2,
            completionTimeMs: 45000,
          ),
        ).thenAnswer((_) async => false);

        await container.read(dailyChallengeProvider.future);

        final notifier = container.read(dailyChallengeProvider.notifier);
        final result = await notifier.submitCompletion(
          userId: 'user123',
          stars: 2,
          completionTimeMs: 45000,
        );

        expect(result, isFalse);

        final state = container.read(dailyChallengeProvider).requireValue;
        expect(state.error, 'Failed to submit challenge completion');
      });

      test('handles errors during submission', () async {
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallenge);
        when(
          () => mockRepository.submitChallengeCompletion(
            userId: any(named: 'userId'),
            stars: any(named: 'stars'),
            completionTimeMs: any(named: 'completionTimeMs'),
          ),
        ).thenThrow(Exception('Network failure'));

        await container.read(dailyChallengeProvider.future);

        final notifier = container.read(dailyChallengeProvider.notifier);
        final result = await notifier.submitCompletion(
          userId: 'user123',
          stars: 3,
          completionTimeMs: 30000,
        );

        expect(result, isFalse);

        final state = container.read(dailyChallengeProvider).requireValue;
        expect(state.error, contains('Network failure'));
      });

      test('completes submission without errors', () async {
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallenge);
        when(
          () => mockRepository.submitChallengeCompletion(
            userId: any(named: 'userId'),
            stars: any(named: 'stars'),
            completionTimeMs: any(named: 'completionTimeMs'),
          ),
        ).thenAnswer((_) async => true);

        await container.read(dailyChallengeProvider.future);

        final notifier = container.read(dailyChallengeProvider.notifier);

        // Perform submission
        final result = await notifier.submitCompletion(
          userId: 'user123',
          stars: 3,
          completionTimeMs: 30000,
        );

        expect(result, isTrue);
      });

      test('validates different star values', () async {
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallenge);

        for (var stars in [1, 2, 3]) {
          when(
            () => mockRepository.submitChallengeCompletion(
              userId: 'user123',
              stars: stars,
              completionTimeMs: 30000,
            ),
          ).thenAnswer((_) async => true);

          await container.read(dailyChallengeProvider.future);

          final notifier = container.read(dailyChallengeProvider.notifier);
          final result = await notifier.submitCompletion(
            userId: 'user123',
            stars: stars,
            completionTimeMs: 30000,
          );

          expect(result, isTrue);
          verify(
            () => mockRepository.submitChallengeCompletion(
              userId: 'user123',
              stars: stars,
              completionTimeMs: 30000,
            ),
          ).called(1);
        }
      });
    });

    group('DailyChallengeState', () {
      test('copyWith updates fields correctly', () {
        const state = DailyChallengeState(
          challenge: null,
          isLoading: false,
          error: 'Old error',
          hasCompleted: false,
        );

        final updated = state.copyWith(
          isLoading: true,
          hasCompleted: true,
          clearError: true,
        );

        expect(updated.isLoading, isTrue);
        expect(updated.hasCompleted, isTrue);
        expect(updated.error, isNull);
      });

      test('copyWith preserves fields when not specified', () {
        final state = DailyChallengeState(
          challenge: testChallenge,
          isLoading: false,
          error: 'Error message',
          hasCompleted: true,
        );

        final updated = state.copyWith(isLoading: true);

        expect(updated.challenge, testChallenge);
        expect(updated.error, 'Error message');
        expect(updated.hasCompleted, isTrue);
        expect(updated.isLoading, isTrue);
      });

      test('copyWith clears challenge when clearChallenge is true', () {
        final state = DailyChallengeState(
          challenge: testChallenge,
          isLoading: false,
          hasCompleted: false,
        );

        final updated = state.copyWith(clearChallenge: true);

        expect(updated.challenge, isNull);
      });
    });
  });

  group('dailyChallengeRepositoryProvider', () {
    test('throws UnimplementedError when not overridden', () {
      final bareContainer = ProviderContainer();

      expect(
        () => bareContainer.read(dailyChallengeRepositoryProvider),
        throwsA(isA<UnimplementedError>()),
      );

      bareContainer.dispose();
    });

    test('returns overridden repository', () {
      final repository = container.read(dailyChallengeRepositoryProvider);
      expect(repository, mockRepository);
    });
  });
}
