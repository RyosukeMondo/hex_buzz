import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/daily_challenge.dart';
import 'package:hex_buzz/domain/models/hex_cell.dart';
import 'package:hex_buzz/domain/models/hex_edge.dart';
import 'package:hex_buzz/domain/models/level.dart';
import 'package:hex_buzz/domain/models/user.dart';
import 'package:hex_buzz/domain/services/auth_repository.dart';
import 'package:hex_buzz/domain/services/daily_challenge_repository.dart';
import 'package:hex_buzz/presentation/providers/auth_provider.dart';
import 'package:hex_buzz/presentation/providers/daily_challenge_provider.dart';
import 'package:hex_buzz/presentation/screens/daily_challenge/daily_challenge_screen.dart';
import 'package:hex_buzz/presentation/theme/honey_theme.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockDailyChallengeRepository extends Mock
    implements DailyChallengeRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockAuthRepository;
  late MockDailyChallengeRepository mockDailyChallengeRepository;

  final testUser = User(
    id: 'test-user-123',
    username: 'TestUser',
    createdAt: DateTime(2024, 1, 1),
    email: 'test@example.com',
    displayName: 'Test User',
    totalStars: 150,
    rank: 5,
  );

  final testCells = {
    (0, 0): HexCell(q: 0, r: 0, checkpoint: 1),
    (1, 0): HexCell(q: 1, r: 0),
    (2, 0): HexCell(q: 2, r: 0, checkpoint: 2),
    (0, 1): HexCell(q: 0, r: 1),
    (1, 1): HexCell(q: 1, r: 1, checkpoint: 3),
  };

  final testLevel = Level(
    id: 'level-1',
    size: 5,
    cells: testCells,
    walls: <HexEdge>{},
    checkpointCount: 3,
  );

  final testChallengeNotCompleted = DailyChallenge(
    id: '2024-01-15',
    date: DateTime(2024, 1, 15),
    level: testLevel,
    completionCount: 42,
  );

  final testChallengeCompleted = DailyChallenge(
    id: '2024-01-15',
    date: DateTime(2024, 1, 15),
    level: testLevel,
    completionCount: 42,
    userBestTime: 45000,
    userStars: 3,
    userRank: 5,
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockDailyChallengeRepository = MockDailyChallengeRepository();

    // Default auth setup
    when(
      () => mockAuthRepository.authStateChanges(),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockAuthRepository.getCurrentUser(),
    ).thenAnswer((_) async => null);

    // Default challenge setup
    when(
      () => mockDailyChallengeRepository.getTodaysChallenge(),
    ).thenAnswer((_) async => testChallengeNotCompleted);
  });

  Widget createTestWidget({User? currentUser}) {
    if (currentUser != null) {
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => currentUser);
      when(
        () => mockAuthRepository.authStateChanges(),
      ).thenAnswer((_) => Stream.value(currentUser));
    }

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        dailyChallengeRepositoryProvider.overrideWithValue(
          mockDailyChallengeRepository,
        ),
      ],
      child: MaterialApp(
        theme: HoneyTheme.lightTheme,
        home: const DailyChallengeScreen(),
      ),
    );
  }

  group('DailyChallengeScreen', () {
    group('renders correctly', () {
      testWidgets('displays app bar with title', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Daily Challenge'), findsOneWidget);
      });

      testWidgets('renders without crashing', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byType(DailyChallengeScreen), findsOneWidget);
      });
    });

    group('Challenge Card', () {
      testWidgets('displays challenge title and date', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Today\'s Challenge'), findsOneWidget);
        expect(find.text('Jan 15, 2024'), findsOneWidget);
      });

      testWidgets('displays calendar icon', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      });

      testWidgets('displays "Start Challenge" button when not completed', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Start Challenge'), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      });

      testWidgets('displays "Play Again" button when completed', (
        tester,
      ) async {
        when(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallengeCompleted);

        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Play Again'), findsOneWidget);
        expect(find.byIcon(Icons.replay), findsOneWidget);
      });

      testWidgets('button exists when not logged in', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Verify button text is present (button exists)
        expect(find.text('Start Challenge'), findsOneWidget);
      });

      testWidgets('shows "Sign in to participate" when not logged in', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Sign in to participate'), findsOneWidget);
      });

      testWidgets('hides "Sign in to participate" when logged in', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Sign in to participate'), findsNothing);
      });
    });

    group('Stats Card', () {
      testWidgets('displays "Challenge Stats" header', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Challenge Stats'), findsOneWidget);
      });

      testWidgets('displays completion count', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Completions'), findsOneWidget);
        expect(find.text('42'), findsOneWidget);
      });

      testWidgets('displays grid size', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Grid Size'), findsOneWidget);
        expect(find.text('5×5'), findsOneWidget);
      });

      testWidgets('displays checkpoint count', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Checkpoints'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('displays stat icons', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.people), findsOneWidget);
        expect(find.byIcon(Icons.grid_on), findsOneWidget);
        expect(find.byIcon(Icons.location_on), findsOneWidget);
      });
    });

    group('User Result Card', () {
      testWidgets('does not show when challenge not completed', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Your Best Result'), findsNothing);
      });

      testWidgets('shows when challenge is completed', (tester) async {
        when(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallengeCompleted);

        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Your Best Result'), findsOneWidget);
      });

      testWidgets('displays user rank', (tester) async {
        when(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallengeCompleted);

        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Rank'), findsOneWidget);
        expect(find.text('#5'), findsOneWidget);
      });

      testWidgets('displays user stars', (tester) async {
        when(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallengeCompleted);

        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Stars'), findsOneWidget);
        expect(find.text('3'), findsWidgets);
      });

      testWidgets('displays completion time', (tester) async {
        when(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallengeCompleted);

        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Time'), findsOneWidget);
        expect(find.text('00:45.00'), findsOneWidget);
      });

      testWidgets('displays result stat icons', (tester) async {
        when(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallengeCompleted);

        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.leaderboard), findsOneWidget);
        expect(find.byIcon(Icons.star), findsWidgets);
        expect(find.byIcon(Icons.timer), findsOneWidget);
        expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('displays error message on repository failure', (
        tester,
      ) async {
        when(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).thenThrow(Exception('Network error'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Exception: Network error'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('displays retry button on error', (tester) async {
        when(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).thenThrow(Exception('Network error'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('retries loading when retry button tapped', (tester) async {
        when(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).thenThrow(Exception('Network error'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should have called once initially
        verify(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).called(1);

        // Setup success response for retry
        when(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallengeNotCompleted);

        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        // Should call again after retry
        verify(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).called(1);

        // Error should be gone
        expect(find.text('Exception: Network error'), findsNothing);
        expect(find.text('Today\'s Challenge'), findsOneWidget);
      });
    });

    group('Empty State', () {
      testWidgets('displays empty state when no challenge available', (
        tester,
      ) async {
        when(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => null);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(
          find.text('No daily challenge available today. Check back later!'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      });
    });

    group('Pull to Refresh', () {
      testWidgets('supports pull-to-refresh', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(RefreshIndicator), findsOneWidget);
      });

      testWidgets('refreshes data when pulled', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Initial load
        verify(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).called(1);

        // Perform pull-to-refresh
        await tester.drag(
          find.text('Today\'s Challenge'),
          const Offset(0, 300),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        // Should refresh
        verify(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).called(1);
      });
    });

    group('Date Formatting', () {
      testWidgets('formats dates correctly - January', (tester) async {
        final challenge = testChallengeNotCompleted.copyWith(
          date: DateTime(2024, 1, 15),
        );
        when(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => challenge);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Jan 15, 2024'), findsOneWidget);
      });

      testWidgets('formats dates correctly - December', (tester) async {
        final challenge = testChallengeNotCompleted.copyWith(
          date: DateTime(2024, 12, 25),
        );
        when(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => challenge);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Dec 25, 2024'), findsOneWidget);
      });
    });

    group('Time Formatting', () {
      testWidgets('formats time under 1 minute correctly', (tester) async {
        final challenge = testChallengeCompleted.copyWith(userBestTime: 45000);
        when(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => challenge);

        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('00:45.00'), findsOneWidget);
      });

      testWidgets('formats time over 1 minute correctly', (tester) async {
        final challenge = testChallengeCompleted.copyWith(userBestTime: 125500);
        when(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => challenge);

        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('02:05.50'), findsOneWidget);
      });

      testWidgets('formats time with milliseconds correctly', (tester) async {
        final challenge = testChallengeCompleted.copyWith(userBestTime: 12345);
        when(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => challenge);

        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('00:12.34'), findsOneWidget);
      });
    });

    group('UI Responsiveness', () {
      testWidgets('renders correctly on different viewport sizes', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.byType(SafeArea), findsWidgets);
      });

      testWidgets('all content is scrollable', (tester) async {
        when(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallengeCompleted);

        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        // Verify SingleChildScrollView is present
        expect(find.byType(SingleChildScrollView), findsOneWidget);

        // Verify physics allows scrolling even when content fits
        final scrollView = tester.widget<SingleChildScrollView>(
          find.byType(SingleChildScrollView),
        );
        expect(scrollView.physics, isA<AlwaysScrollableScrollPhysics>());
      });
    });
  });
}
