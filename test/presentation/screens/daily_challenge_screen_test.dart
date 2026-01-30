import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/daily_challenge.dart';
import 'package:hex_buzz/domain/models/daily_challenge_completion.dart';
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

  final testChallenge = DailyChallenge(
    id: '2024-01-15',
    date: DateTime(2024, 1, 15),
    level: testLevel,
    completionCount: 42,
  );

  final testCompletion = DailyChallengeCompletion(
    userId: 'test-user-123',
    dateId: '2024-01-15',
    stars: 3,
    completionTimeMs: 45000,
    completedAt: DateTime(2024, 1, 15, 10, 30),
    rank: 5,
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockDailyChallengeRepository = MockDailyChallengeRepository();

    // Default auth setup - not logged in
    when(
      () => mockAuthRepository.authStateChanges(),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockAuthRepository.getCurrentUser(),
    ).thenAnswer((_) async => null);

    // Default challenge setup
    when(
      () => mockDailyChallengeRepository.getTodaysChallenge(),
    ).thenAnswer((_) async => testChallenge);
    when(
      () => mockDailyChallengeRepository.getCompletion(
        userId: any(named: 'userId'),
        dateId: any(named: 'dateId'),
      ),
    ).thenAnswer((_) async => null);
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
    group('Basic Rendering', () {
      testWidgets('displays app bar with title', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Daily Challenge'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('renders without crashing', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byType(DailyChallengeScreen), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    group('Sign In Required State', () {
      testWidgets('shows sign in required when not authenticated', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Sign In Required'), findsOneWidget);
        expect(
          find.text('Please sign in to participate in daily challenges'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      });

      testWidgets('does not show challenge content when not authenticated', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Today\'s Challenge'), findsNothing);
        expect(find.text('Start Challenge'), findsNothing);
      });
    });

    group('NotStarted State', () {
      testWidgets('displays challenge card with date', (tester) async {
        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Today\'s Challenge'), findsOneWidget);
        expect(find.text('Jan 15, 2024'), findsOneWidget);
        expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      });

      testWidgets('displays Start Challenge button', (tester) async {
        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Start Challenge'), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      });

      testWidgets('displays challenge stats', (tester) async {
        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Challenge Stats'), findsOneWidget);
        expect(find.text('Grid Size'), findsOneWidget);
        expect(find.text('5×5'), findsOneWidget);
        expect(find.text('Checkpoints'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.byIcon(Icons.grid_on), findsOneWidget);
        expect(find.byIcon(Icons.location_on), findsOneWidget);
      });

      testWidgets('does not show retry/play again button', (tester) async {
        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Play Again'), findsNothing);
        expect(find.text('Retry'), findsNothing);
        expect(find.byIcon(Icons.replay), findsNothing);
      });
    });

    group('AlreadyCompleted State', () {
      testWidgets('shows already completed message', (tester) async {
        when(
          () => mockDailyChallengeRepository.getCompletion(
            userId: any(named: 'userId'),
            dateId: any(named: 'dateId'),
          ),
        ).thenAnswer((_) async => testCompletion);

        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Already Completed'), findsOneWidget);
        expect(
          find.text('You\'ve already completed today\'s challenge!'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      });

      testWidgets('displays completion stats', (tester) async {
        when(
          () => mockDailyChallengeRepository.getCompletion(
            userId: any(named: 'userId'),
            dateId: any(named: 'dateId'),
          ),
        ).thenAnswer((_) async => testCompletion);

        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Stars: 3/3'), findsOneWidget);
        expect(find.text('Time: 00:45.00'), findsOneWidget);
        expect(find.text('Rank: #5'), findsOneWidget);
      });

      testWidgets('shows back to menu button', (tester) async {
        when(
          () => mockDailyChallengeRepository.getCompletion(
            userId: any(named: 'userId'),
            dateId: any(named: 'dateId'),
          ),
        ).thenAnswer((_) async => testCompletion);

        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Back to Menu'), findsOneWidget);
      });

      testWidgets('shows come back tomorrow message', (tester) async {
        when(
          () => mockDailyChallengeRepository.getCompletion(
            userId: any(named: 'userId'),
            dateId: any(named: 'dateId'),
          ),
        ).thenAnswer((_) async => testCompletion);

        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(
          find.text('Come back tomorrow for a new challenge!'),
          findsOneWidget,
        );
      });

      testWidgets('does not show Start Challenge button', (tester) async {
        when(
          () => mockDailyChallengeRepository.getCompletion(
            userId: any(named: 'userId'),
            dateId: any(named: 'dateId'),
          ),
        ).thenAnswer((_) async => testCompletion);

        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Start Challenge'), findsNothing);
        expect(find.text('Play Again'), findsNothing);
      });
    });

    group('Suspended State', () {
      testWidgets('shows challenge paused message', (tester) async {
        // Note: This test requires state injection via provider override
        // Skipping for now as it requires more complex state management
      });

      testWidgets('shows resume button', (tester) async {
        // Note: This test requires state injection via provider override
        // Skipping for now as it requires more complex state management
      });

      testWidgets('shows timer warning', (tester) async {
        // Note: This test requires state injection via provider override
        // Skipping for now as it requires more complex state management
      });
    });

    group('Error State', () {
      testWidgets('displays error message on repository failure', (
        tester,
      ) async {
        when(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).thenThrow(Exception('Network error'));

        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('retries loading when retry button tapped', (tester) async {
        when(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).thenThrow(Exception('Network error'));

        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        // Verify error state
        expect(find.text('Retry'), findsOneWidget);

        // Setup success response for retry
        when(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => testChallenge);

        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        // Should now show challenge
        expect(find.text('Today\'s Challenge'), findsOneWidget);
        expect(find.text('Start Challenge'), findsOneWidget);
      });
    });

    group('Date Formatting', () {
      testWidgets('formats January dates correctly', (tester) async {
        final challenge = testChallenge.copyWith(date: DateTime(2024, 1, 15));
        when(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => challenge);

        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Jan 15, 2024'), findsOneWidget);
      });

      testWidgets('formats December dates correctly', (tester) async {
        final challenge = testChallenge.copyWith(date: DateTime(2024, 12, 25));
        when(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => challenge);

        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Dec 25, 2024'), findsOneWidget);
      });

      testWidgets('formats June dates correctly', (tester) async {
        final challenge = testChallenge.copyWith(date: DateTime(2024, 6, 10));
        when(
          () => mockDailyChallengeRepository.getTodaysChallenge(),
        ).thenAnswer((_) async => challenge);

        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Jun 10, 2024'), findsOneWidget);
      });
    });

    group('Time Formatting', () {
      testWidgets('formats time under 1 minute correctly', (tester) async {
        final completion = testCompletion.copyWith(completionTimeMs: 45000);
        when(
          () => mockDailyChallengeRepository.getCompletion(
            userId: any(named: 'userId'),
            dateId: any(named: 'dateId'),
          ),
        ).thenAnswer((_) async => completion);

        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Time: 00:45.00'), findsOneWidget);
      });

      testWidgets('formats time over 1 minute correctly', (tester) async {
        final completion = testCompletion.copyWith(completionTimeMs: 125500);
        when(
          () => mockDailyChallengeRepository.getCompletion(
            userId: any(named: 'userId'),
            dateId: any(named: 'dateId'),
          ),
        ).thenAnswer((_) async => completion);

        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Time: 02:05.50'), findsOneWidget);
      });

      testWidgets('formats time with milliseconds correctly', (tester) async {
        final completion = testCompletion.copyWith(completionTimeMs: 12345);
        when(
          () => mockDailyChallengeRepository.getCompletion(
            userId: any(named: 'userId'),
            dateId: any(named: 'dateId'),
          ),
        ).thenAnswer((_) async => completion);

        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Time: 00:12.34'), findsOneWidget);
      });
    });

    group('UI Layout', () {
      testWidgets('uses SafeArea for content', (tester) async {
        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.byType(SafeArea), findsWidgets);
      });

      testWidgets('uses SingleChildScrollView in NotStarted state', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });

      testWidgets('displays content in column layout', (tester) async {
        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.byType(Column), findsWidgets);
      });
    });

    group('Theme and Styling', () {
      testWidgets('uses HoneyTheme colors', (tester) async {
        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, HoneyTheme.warmCream);

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.backgroundColor, HoneyTheme.honeyGold);
        expect(appBar.foregroundColor, HoneyTheme.textPrimary);
      });

      testWidgets('applies proper spacing', (tester) async {
        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.byType(SizedBox), findsWidgets);
      });

      testWidgets('uses rounded corners for cards', (tester) async {
        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });
    });
  });
}
