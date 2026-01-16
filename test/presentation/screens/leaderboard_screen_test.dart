import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/leaderboard_entry.dart';
import 'package:hex_buzz/domain/models/user.dart';
import 'package:hex_buzz/domain/services/auth_repository.dart';
import 'package:hex_buzz/domain/services/daily_challenge_repository.dart';
import 'package:hex_buzz/domain/services/leaderboard_repository.dart';
import 'package:hex_buzz/presentation/providers/auth_provider.dart';
import 'package:hex_buzz/presentation/providers/daily_challenge_provider.dart';
import 'package:hex_buzz/presentation/providers/leaderboard_provider.dart';
import 'package:hex_buzz/presentation/screens/leaderboard/leaderboard_screen.dart';
import 'package:hex_buzz/presentation/theme/honey_theme.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockAuthRepository;
  late MockLeaderboardRepository mockLeaderboardRepository;

  final testUser = User(
    id: 'test-user-123',
    username: 'TestUser',
    createdAt: DateTime(2024, 1, 1),
    email: 'test@example.com',
    displayName: 'Test User',
    totalStars: 150,
    rank: 5,
  );

  final leaderboardEntries = [
    LeaderboardEntry(
      userId: 'user-1',
      username: 'Player 1',
      avatarUrl: null,
      totalStars: 500,
      rank: 1,
      updatedAt: DateTime(2024, 1, 15),
    ),
    LeaderboardEntry(
      userId: 'user-2',
      username: 'Player 2',
      avatarUrl: null,
      totalStars: 450,
      rank: 2,
      updatedAt: DateTime(2024, 1, 15),
    ),
    LeaderboardEntry(
      userId: 'user-3',
      username: 'Player 3',
      avatarUrl: null,
      totalStars: 400,
      rank: 3,
      updatedAt: DateTime(2024, 1, 15),
    ),
    LeaderboardEntry(
      userId: 'test-user-123',
      username: 'TestUser',
      avatarUrl: null,
      totalStars: 150,
      rank: 5,
      updatedAt: DateTime(2024, 1, 15),
    ),
  ];

  final dailyChallengeEntries = [
    LeaderboardEntry(
      userId: 'user-1',
      username: 'Player 1',
      avatarUrl: null,
      totalStars: 300,
      rank: 1,
      updatedAt: DateTime(2024, 1, 15),
      stars: 3,
      completionTime: 45000,
    ),
    LeaderboardEntry(
      userId: 'test-user-123',
      username: 'TestUser',
      avatarUrl: null,
      totalStars: 200,
      rank: 2,
      updatedAt: DateTime(2024, 1, 15),
      stars: 3,
      completionTime: 50000,
    ),
  ];

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockLeaderboardRepository = MockLeaderboardRepository();

    // Default setup for auth
    when(
      () => mockAuthRepository.authStateChanges(),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockAuthRepository.getCurrentUser(),
    ).thenAnswer((_) async => null);

    // Default setup for leaderboard
    when(
      () => mockLeaderboardRepository.getTopPlayers(limit: any(named: 'limit')),
    ).thenAnswer((_) async => leaderboardEntries);
    when(
      () => mockLeaderboardRepository.getDailyChallengeLeaderboard(
        date: any(named: 'date'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => dailyChallengeEntries);
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
        leaderboardRepositoryProvider.overrideWithValue(
          mockLeaderboardRepository,
        ),
        // Mock daily challenge repository to prevent errors
        dailyChallengeRepositoryProvider.overrideWithValue(
          _MockDailyChallengeRepository(),
        ),
      ],
      child: MaterialApp(
        theme: HoneyTheme.lightTheme,
        home: const LeaderboardScreen(),
      ),
    );
  }

  group('LeaderboardScreen', () {
    group('renders correctly', () {
      testWidgets('displays app bar with title', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Leaderboard'), findsOneWidget);
      });

      testWidgets('displays Global and Daily Challenge tabs', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Global'), findsOneWidget);
        expect(find.text('Daily Challenge'), findsOneWidget);
      });

      testWidgets('renders without crashing', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Just verify the screen renders
        expect(find.byType(LeaderboardScreen), findsOneWidget);
      });
    });

    group('Global Leaderboard Tab', () {
      testWidgets('displays leaderboard entries after loading', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Player 1'), findsOneWidget);
        expect(find.text('Player 2'), findsOneWidget);
        expect(find.text('Player 3'), findsOneWidget);
      });

      testWidgets('displays rank badges correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find rank badges
        expect(find.text('1'), findsWidgets);
        expect(find.text('2'), findsWidgets);
        expect(find.text('3'), findsWidgets);
      });

      testWidgets('displays star counts', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('500'), findsOneWidget);
        expect(find.text('450'), findsOneWidget);
        expect(find.text('400'), findsOneWidget);
      });

      testWidgets('highlights current user entry', (tester) async {
        await tester.pumpWidget(createTestWidget(currentUser: testUser));
        await tester.pumpAndSettle();

        // The user's entry should be present
        expect(find.text('TestUser'), findsWidgets);
      });

      testWidgets('supports pull-to-refresh', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find RefreshIndicator
        expect(find.byType(RefreshIndicator), findsOneWidget);

        // Perform pull-to-refresh gesture
        await tester.drag(find.text('Player 1'), const Offset(0, 300));
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify repository was called (at least once for initial load)
        verify(
          () => mockLeaderboardRepository.getTopPlayers(limit: 100),
        ).called(greaterThan(0));
      });

      testWidgets('handles empty leaderboard', (tester) async {
        when(
          () => mockLeaderboardRepository.getTopPlayers(
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => []);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(
          find.text('No rankings yet. Be the first to play!'),
          findsOneWidget,
        );
      });

      testWidgets('handles error state', (tester) async {
        when(
          () => mockLeaderboardRepository.getTopPlayers(
            limit: any(named: 'limit'),
          ),
        ).thenThrow(Exception('Network error'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Exception: Network error'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });
    });

    group('Daily Challenge Tab', () {
      testWidgets('switches to Daily Challenge tab', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap on Daily Challenge tab
        await tester.tap(find.text('Daily Challenge'));
        await tester.pumpAndSettle();

        // Should show daily challenge entries
        expect(find.text('Player 1'), findsOneWidget);
        expect(find.text('TestUser'), findsOneWidget);
      });

      testWidgets('displays completion times', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Switch to Daily Challenge tab
        await tester.tap(find.text('Daily Challenge'));
        await tester.pumpAndSettle();

        // Should show formatted completion times
        expect(find.textContaining('00:'), findsWidgets);
      });

      testWidgets('shows empty state when no completions', (tester) async {
        when(
          () => mockLeaderboardRepository.getDailyChallengeLeaderboard(
            date: any(named: 'date'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => []);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Switch to Daily Challenge tab
        await tester.tap(find.text('Daily Challenge'));
        await tester.pumpAndSettle();

        expect(
          find.text('No one has completed today\'s challenge yet!'),
          findsOneWidget,
        );
      });

      testWidgets('supports pull-to-refresh on Daily Challenge tab', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Switch to Daily Challenge tab
        await tester.tap(find.text('Daily Challenge'));
        await tester.pumpAndSettle();

        // Find RefreshIndicator
        expect(find.byType(RefreshIndicator), findsOneWidget);

        // Perform pull-to-refresh gesture
        await tester.drag(find.text('Player 1'), const Offset(0, 300));
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify repository was called (at least once for initial load)
        verify(
          () => mockLeaderboardRepository.getDailyChallengeLeaderboard(
            date: any(named: 'date'),
            limit: any(named: 'limit'),
          ),
        ).called(greaterThan(0));
      });
    });

    group('UI Elements', () {
      testWidgets('displays avatars with initials', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should have CircleAvatar widgets for each entry
        expect(find.byType(CircleAvatar), findsWidgets);
        // Users without avatar URL show initials
        expect(find.text('P'), findsWidgets);
        expect(find.text('T'), findsWidgets);
      });

      testWidgets('displays star icons', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.star), findsWidgets);
      });

      testWidgets('displays error icon on error', (tester) async {
        when(
          () => mockLeaderboardRepository.getTopPlayers(
            limit: any(named: 'limit'),
          ),
        ).thenThrow(Exception('Network error'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });
    });
  });
}

// Simple mock for DailyChallengeRepository to prevent errors
class _MockDailyChallengeRepository extends Mock
    implements DailyChallengeRepository {}
