import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/daily_challenge.dart';
import 'package:hex_buzz/domain/models/daily_challenge_completion.dart';
import 'package:hex_buzz/domain/models/daily_challenge_state.dart';
import 'package:hex_buzz/domain/models/hex_cell.dart';
import 'package:hex_buzz/domain/models/hex_edge.dart';
import 'package:hex_buzz/domain/models/level.dart';
import 'package:hex_buzz/domain/services/daily_challenge_repository.dart';
import 'package:hex_buzz/presentation/providers/daily_challenge_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockDailyChallengeRepository extends Mock
    implements DailyChallengeRepository {}

void main() {
  late MockDailyChallengeRepository mockRepository;
  late DailyChallengeNotifier notifier;
  const testUserId = 'test-user-id';

  setUp(() {
    mockRepository = MockDailyChallengeRepository();
    notifier = DailyChallengeNotifier(
      repository: mockRepository,
      userId: testUserId,
    );
  });

  tearDown(() {
    notifier.dispose();
  });

  group('DailyChallengeNotifier', () {
    final testLevel = Level(
      id: 'test-level-1',
      size: 3,
      cells: {
        (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
        (1, 0): const HexCell(q: 1, r: 0),
        (0, 1): const HexCell(q: 0, r: 1, checkpoint: 2),
      },
      walls: <HexEdge>{},
      checkpointCount: 2,
    );

    final testChallenge = DailyChallenge(
      id: '2024-01-30',
      date: DateTime(2024, 1, 30),
      level: testLevel,
      completionCount: 10,
    );

    final testCompletion = DailyChallengeCompletion(
      userId: testUserId,
      dateId: '2024-01-30',
      stars: 3,
      completionTimeMs: 120000,
      completedAt: DateTime(2024, 1, 30, 10, 0),
      rank: 5,
    );

    group('loadChallenge', () {
      test(
        'sets state to NotStarted when challenge exists and no completion',
        () async {
          // Arrange
          when(
            () => mockRepository.getTodaysChallenge(),
          ).thenAnswer((_) async => testChallenge);
          when(
            () => mockRepository.getCompletion(
              userId: testUserId,
              dateId: testChallenge.id,
            ),
          ).thenAnswer((_) async => null);

          // Act
          await notifier.loadChallenge();

          // Assert
          expect(notifier.state, isA<DailyChallengeStateNotStarted>());
          final notStartedState =
              notifier.state as DailyChallengeStateNotStarted;
          expect(notStartedState.challenge.id, testChallenge.id);

          verify(() => mockRepository.getTodaysChallenge()).called(1);
          verify(
            () => mockRepository.getCompletion(
              userId: testUserId,
              dateId: testChallenge.id,
            ),
          ).called(1);
        },
      );

      test('sets state to AlreadyCompleted when completion exists', () async {
        // Arrange
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallenge);
        when(
          () => mockRepository.getCompletion(
            userId: testUserId,
            dateId: testChallenge.id,
          ),
        ).thenAnswer((_) async => testCompletion);

        // Act
        await notifier.loadChallenge();

        // Assert
        expect(notifier.state, isA<DailyChallengeStateAlreadyCompleted>());
        final completedState =
            notifier.state as DailyChallengeStateAlreadyCompleted;
        expect(completedState.completion.stars, testCompletion.stars);
        expect(completedState.completion.rank, testCompletion.rank);

        verify(() => mockRepository.getTodaysChallenge()).called(1);
        verify(
          () => mockRepository.getCompletion(
            userId: testUserId,
            dateId: testChallenge.id,
          ),
        ).called(1);
      });

      test('sets state to Error when no challenge available', () async {
        // Arrange
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => null);

        // Act
        await notifier.loadChallenge();

        // Assert
        expect(notifier.state, isA<DailyChallengeStateError>());

        verify(() => mockRepository.getTodaysChallenge()).called(1);
      });

      test('sets state to Error when repository throws', () async {
        // Arrange
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenThrow(Exception('Network error'));

        // Act
        await notifier.loadChallenge();

        // Assert
        expect(notifier.state, isA<DailyChallengeStateError>());

        verify(() => mockRepository.getTodaysChallenge()).called(1);
      });
    });

    group('startChallenge', () {
      test(
        'transitions from NotStarted to Playing with current time',
        () async {
          // Arrange
          when(
            () => mockRepository.getTodaysChallenge(),
          ).thenAnswer((_) async => testChallenge);
          when(
            () => mockRepository.getCompletion(
              userId: testUserId,
              dateId: testChallenge.id,
            ),
          ).thenAnswer((_) async => null);

          await notifier.loadChallenge();

          // Act
          final beforeStart = DateTime.now();
          notifier.startChallenge();
          final afterStart = DateTime.now();

          // Assert
          expect(notifier.state, isA<DailyChallengeStatePlaying>());
          final playingState = notifier.state as DailyChallengeStatePlaying;
          expect(playingState.challenge.id, testChallenge.id);
          expect(
            playingState.startTime.isAfter(
              beforeStart.subtract(const Duration(seconds: 1)),
            ),
            true,
          );
          expect(
            playingState.startTime.isBefore(
              afterStart.add(const Duration(seconds: 1)),
            ),
            true,
          );
        },
      );

      test('does nothing when called from non-NotStarted state', () async {
        // Arrange
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallenge);
        when(
          () => mockRepository.getCompletion(
            userId: testUserId,
            dateId: testChallenge.id,
          ),
        ).thenAnswer((_) async => testCompletion);

        await notifier.loadChallenge();

        // Ensure we're in AlreadyCompleted state
        expect(notifier.state, isA<DailyChallengeStateAlreadyCompleted>());

        // Act
        notifier.startChallenge();

        // Assert - state should not change
        expect(notifier.state, isA<DailyChallengeStateAlreadyCompleted>());
      });
    });

    group('suspend', () {
      test(
        'transitions from Playing to Suspended preserving startTime',
        () async {
          // Arrange
          when(
            () => mockRepository.getTodaysChallenge(),
          ).thenAnswer((_) async => testChallenge);
          when(
            () => mockRepository.getCompletion(
              userId: testUserId,
              dateId: testChallenge.id,
            ),
          ).thenAnswer((_) async => null);

          await notifier.loadChallenge();
          notifier.startChallenge();

          final playingState = notifier.state as DailyChallengeStatePlaying;
          final originalStartTime = playingState.startTime;

          // Act
          notifier.suspend();

          // Assert
          expect(notifier.state, isA<DailyChallengeStateSuspended>());
          final suspendedState = notifier.state as DailyChallengeStateSuspended;
          expect(suspendedState.startTime, originalStartTime); // Preserved
          expect(suspendedState.challenge.id, testChallenge.id);
        },
      );

      test('does nothing when called from non-Playing state', () async {
        // Arrange
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallenge);
        when(
          () => mockRepository.getCompletion(
            userId: testUserId,
            dateId: testChallenge.id,
          ),
        ).thenAnswer((_) async => null);

        await notifier.loadChallenge();

        // We're in NotStarted state
        expect(notifier.state, isA<DailyChallengeStateNotStarted>());

        // Act
        notifier.suspend();

        // Assert - state should not change
        expect(notifier.state, isA<DailyChallengeStateNotStarted>());
      });
    });

    group('resume', () {
      test(
        'transitions from Suspended to Playing with same startTime',
        () async {
          // Arrange
          when(
            () => mockRepository.getTodaysChallenge(),
          ).thenAnswer((_) async => testChallenge);
          when(
            () => mockRepository.getCompletion(
              userId: testUserId,
              dateId: testChallenge.id,
            ),
          ).thenAnswer((_) async => null);

          await notifier.loadChallenge();
          notifier.startChallenge();

          final playingState = notifier.state as DailyChallengeStatePlaying;
          final originalStartTime = playingState.startTime;

          notifier.suspend();
          await Future.delayed(const Duration(milliseconds: 50));

          // Act
          notifier.resume();

          // Assert
          expect(notifier.state, isA<DailyChallengeStatePlaying>());
          final resumedState = notifier.state as DailyChallengeStatePlaying;
          expect(resumedState.startTime, originalStartTime); // Same startTime
          expect(resumedState.challenge.id, testChallenge.id);
        },
      );

      test(
        'preserves startTime across multiple suspend/resume cycles (no restart)',
        () async {
          // Arrange
          when(
            () => mockRepository.getTodaysChallenge(),
          ).thenAnswer((_) async => testChallenge);
          when(
            () => mockRepository.getCompletion(
              userId: testUserId,
              dateId: testChallenge.id,
            ),
          ).thenAnswer((_) async => null);

          await notifier.loadChallenge();
          notifier.startChallenge();

          final playingState = notifier.state as DailyChallengeStatePlaying;
          final originalStartTime = playingState.startTime;

          // Act - multiple suspend/resume cycles
          for (var i = 0; i < 3; i++) {
            notifier.suspend();
            await Future.delayed(const Duration(milliseconds: 10));
            notifier.resume();
            await Future.delayed(const Duration(milliseconds: 10));
          }

          // Assert
          expect(notifier.state, isA<DailyChallengeStatePlaying>());
          final finalState = notifier.state as DailyChallengeStatePlaying;
          expect(finalState.startTime, originalStartTime); // Never changed
        },
      );

      test('does nothing when called from non-Suspended state', () async {
        // Arrange
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallenge);
        when(
          () => mockRepository.getCompletion(
            userId: testUserId,
            dateId: testChallenge.id,
          ),
        ).thenAnswer((_) async => null);

        await notifier.loadChallenge();
        notifier.startChallenge();

        // We're in Playing state
        expect(notifier.state, isA<DailyChallengeStatePlaying>());

        // Act
        notifier.resume();

        // Assert - state should not change
        expect(notifier.state, isA<DailyChallengeStatePlaying>());
      });
    });

    group('updatePath', () {
      test('updates path in Playing state', () async {
        // Arrange
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallenge);
        when(
          () => mockRepository.getCompletion(
            userId: testUserId,
            dateId: testChallenge.id,
          ),
        ).thenAnswer((_) async => null);

        await notifier.loadChallenge();
        notifier.startChallenge();

        final testPath = <HexCell>[
          const HexCell(q: 0, r: 0, checkpoint: 1),
          const HexCell(q: 1, r: 0),
        ];

        // Act
        notifier.updatePath(testPath);

        // Assert
        expect(notifier.state, isA<DailyChallengeStatePlaying>());
        final playingState = notifier.state as DailyChallengeStatePlaying;
        expect(playingState.currentPath.length, 2);
      });
    });

    group('complete', () {
      test('transitions to Completed state on success', () async {
        // Arrange
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallenge);

        // First call returns null (not completed yet), second call returns completion
        var callCount = 0;
        when(
          () => mockRepository.getCompletion(
            userId: testUserId,
            dateId: testChallenge.id,
          ),
        ).thenAnswer((_) async {
          callCount++;
          return callCount == 1 ? null : testCompletion;
        });

        when(
          () => mockRepository.submitChallengeCompletion(
            userId: testUserId,
            stars: 3,
            completionTimeMs: any(named: 'completionTimeMs'),
          ),
        ).thenAnswer((_) async => true);

        await notifier.loadChallenge();
        notifier.startChallenge();

        // Act
        await notifier.complete(3);

        // Assert
        expect(notifier.state, isA<DailyChallengeStateCompleted>());
        final completedState = notifier.state as DailyChallengeStateCompleted;
        expect(completedState.completion.stars, 3);

        verify(
          () => mockRepository.submitChallengeCompletion(
            userId: testUserId,
            stars: 3,
            completionTimeMs: any(named: 'completionTimeMs'),
          ),
        ).called(1);
      });

      test('sets Error state when submission fails', () async {
        // Arrange
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallenge);
        when(
          () => mockRepository.getCompletion(
            userId: testUserId,
            dateId: testChallenge.id,
          ),
        ).thenAnswer((_) async => null);
        when(
          () => mockRepository.submitChallengeCompletion(
            userId: testUserId,
            stars: 3,
            completionTimeMs: any(named: 'completionTimeMs'),
          ),
        ).thenAnswer((_) async => false);

        await notifier.loadChallenge();
        notifier.startChallenge();

        // Act
        await notifier.complete(3);

        // Assert
        expect(notifier.state, isA<DailyChallengeStateError>());
      });

      test('does nothing when called from non-Playing state', () async {
        // Arrange
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallenge);
        when(
          () => mockRepository.getCompletion(
            userId: testUserId,
            dateId: testChallenge.id,
          ),
        ).thenAnswer((_) async => null);

        await notifier.loadChallenge();

        // We're in NotStarted state
        expect(notifier.state, isA<DailyChallengeStateNotStarted>());

        // Act
        await notifier.complete(3);

        // Assert - state should not change
        expect(notifier.state, isA<DailyChallengeStateNotStarted>());
        verifyNever(
          () => mockRepository.submitChallengeCompletion(
            userId: any(named: 'userId'),
            stars: any(named: 'stars'),
            completionTimeMs: any(named: 'completionTimeMs'),
          ),
        );
      });
    });

    group('one-attempt enforcement', () {
      test('cannot start challenge after completion', () async {
        // Arrange
        when(
          () => mockRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallenge);
        when(
          () => mockRepository.getCompletion(
            userId: testUserId,
            dateId: testChallenge.id,
          ),
        ).thenAnswer((_) async => testCompletion);

        await notifier.loadChallenge();

        // State should be AlreadyCompleted
        expect(notifier.state, isA<DailyChallengeStateAlreadyCompleted>());

        // Act - try to start
        notifier.startChallenge();

        // Assert - state should not change
        expect(notifier.state, isA<DailyChallengeStateAlreadyCompleted>());
      });
    });
  });
}
