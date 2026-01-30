import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/data/firebase/firebase_auth_repository.dart';
import 'package:hex_buzz/data/hybrid_auth_repository.dart';
import 'package:hex_buzz/data/local/local_guest_auth_repository.dart';
import 'package:hex_buzz/domain/models/auth_result.dart';
import 'package:hex_buzz/domain/models/progress_state.dart';
import 'package:hex_buzz/domain/models/user.dart';
import 'package:hex_buzz/domain/services/progress_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuthRepository extends Mock
    implements FirebaseAuthRepository {}

class MockLocalGuestAuthRepository extends Mock
    implements LocalGuestAuthRepository {}

class MockProgressRepository extends Mock implements ProgressRepository {}

void main() {
  late MockFirebaseAuthRepository mockFirebaseRepo;
  late MockLocalGuestAuthRepository mockGuestRepo;
  late MockProgressRepository mockLocalProgress;
  late MockProgressRepository mockFirestoreProgress;
  late HybridAuthRepository hybridRepo;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(const ProgressState.empty());
  });

  setUp(() {
    mockFirebaseRepo = MockFirebaseAuthRepository();
    mockGuestRepo = MockLocalGuestAuthRepository();
    mockLocalProgress = MockProgressRepository();
    mockFirestoreProgress = MockProgressRepository();

    // Setup default stubs for auth state streams
    when(
      () => mockFirebaseRepo.authStateChanges(),
    ).thenAnswer((_) => Stream.value(null));
    when(
      () => mockGuestRepo.authStateChanges(),
    ).thenAnswer((_) => Stream.value(null));
  });

  HybridAuthRepository createHybridRepo({
    ProgressRepository? localProgress,
    ProgressRepository? firestoreProgress,
  }) {
    return HybridAuthRepository(
      firebaseRepo: mockFirebaseRepo,
      guestRepo: mockGuestRepo,
      localProgress: localProgress ?? mockLocalProgress,
      firestoreProgress: firestoreProgress ?? mockFirestoreProgress,
    );
  }

  tearDown(() {
    // Dispose will be called manually in each test
  });

  group('Guest to Firebase migration', () {
    test('migrates local progress to Firestore', () async {
      // Setup guest user with local progress
      final guestUser = User.guest();
      final firebaseUser = User(
        id: 'firebase-456',
        username: 'Test User',
        createdAt: DateTime.now(),
        email: 'test@example.com',
        isGuest: false,
      );

      final localProgressState = ProgressState(
        levels: {
          0: const LevelProgress(
            completed: true,
            stars: 3,
            bestTime: Duration(seconds: 45),
          ),
          1: const LevelProgress(
            completed: true,
            stars: 2,
            bestTime: Duration(seconds: 60),
          ),
        },
      );

      // Setup mocks
      when(
        () => mockGuestRepo.getCurrentUser(),
      ).thenAnswer((_) async => guestUser);
      when(
        () => mockFirebaseRepo.signInWithGoogle(),
      ).thenAnswer((_) async => AuthSuccess(firebaseUser));
      when(
        () => mockLocalProgress.loadForUser('guest'),
      ).thenAnswer((_) async => localProgressState);
      when(
        () => mockFirestoreProgress.saveForUser(firebaseUser.id, any()),
      ).thenAnswer((_) async {});
      when(
        () => mockLeaderboard.submitScore(
          userId: firebaseUser.id,
          stars: any(named: 'stars'),
          levelId: any(named: 'levelId'),
        ),
      ).thenAnswer((_) async => true);
      when(
        () => mockLocalProgress.resetForUser('guest'),
      ).thenAnswer((_) async {});
      when(() => mockGuestRepo.signOut()).thenAnswer((_) async {});

      final hybridRepo = createHybridRepo();

      // Execute sign in
      final result = await hybridRepo.signInWithGoogle();

      // Verify success
      expect(result, isA<AuthSuccess>());
      expect((result as AuthSuccess).user.id, firebaseUser.id);

      // Verify migration steps
      verify(() => mockLocalProgress.loadForUser('guest')).called(1);
      verify(
        () => mockFirestoreProgress.saveForUser(
          firebaseUser.id,
          localProgressState,
        ),
      ).called(1);
      verify(
        () => mockLeaderboard.submitScore(
          userId: firebaseUser.id,
          stars: 5, // 3 + 2 stars
          levelId: null,
        ),
      ).called(1);
      verify(() => mockLocalProgress.resetForUser('guest')).called(1);
      verify(() => mockGuestRepo.signOut()).called(1);

      hybridRepo.dispose();
    });

    test('continues on migration failure without throwing', () async {
      final guestUser = User.guest();
      final firebaseUser = User(
        id: 'firebase-456',
        username: 'Test User',
        createdAt: DateTime.now(),
        email: 'test@example.com',
        isGuest: false,
      );

      final localProgressState = ProgressState(
        levels: {0: const LevelProgress(completed: true, stars: 3)},
      );

      when(
        () => mockGuestRepo.getCurrentUser(),
      ).thenAnswer((_) async => guestUser);
      when(
        () => mockFirebaseRepo.signInWithGoogle(),
      ).thenAnswer((_) async => AuthSuccess(firebaseUser));
      when(
        () => mockLocalProgress.loadForUser('guest'),
      ).thenAnswer((_) async => localProgressState);
      when(
        () => mockFirestoreProgress.saveForUser(any(), any()),
      ).thenThrow(Exception('Network error'));
      when(() => mockGuestRepo.signOut()).thenAnswer((_) async {});

      final hybridRepo = createHybridRepo();

      // Should not throw
      final result = await hybridRepo.signInWithGoogle();

      // User can still use app
      expect(result, isA<AuthSuccess>());
      expect((result as AuthSuccess).user.id, firebaseUser.id);

      // Local data not deleted on migration failure
      verifyNever(() => mockLocalProgress.resetForUser('guest'));

      hybridRepo.dispose();
    });

    test('skips migration when no local progress exists', () async {
      final guestUser = User.guest();
      final firebaseUser = User(
        id: 'firebase-456',
        username: 'Test User',
        createdAt: DateTime.now(),
        email: 'test@example.com',
        isGuest: false,
      );

      when(
        () => mockGuestRepo.getCurrentUser(),
      ).thenAnswer((_) async => guestUser);
      when(
        () => mockFirebaseRepo.signInWithGoogle(),
      ).thenAnswer((_) async => AuthSuccess(firebaseUser));
      when(
        () => mockLocalProgress.loadForUser('guest'),
      ).thenAnswer((_) async => const ProgressState.empty());
      when(() => mockGuestRepo.signOut()).thenAnswer((_) async {});

      final hybridRepo = createHybridRepo();
      final result = await hybridRepo.signInWithGoogle();

      expect(result, isA<AuthSuccess>());

      // Should not attempt to save or submit scores
      verifyNever(() => mockFirestoreProgress.saveForUser(any(), any()));
      verifyNever(
        () => mockLeaderboard.submitScore(
          userId: any(named: 'userId'),
          stars: any(named: 'stars'),
          levelId: any(named: 'levelId'),
        ),
      );

      // Should still clean up guest session (may be called during init too)
      verify(() => mockGuestRepo.signOut()).called(greaterThanOrEqualTo(1));

      hybridRepo.dispose();
    });

    test('skips migration when no guest user exists', () async {
      final firebaseUser = User(
        id: 'firebase-456',
        username: 'Test User',
        createdAt: DateTime.now(),
        email: 'test@example.com',
        isGuest: false,
      );

      when(() => mockGuestRepo.getCurrentUser()).thenAnswer((_) async => null);
      when(
        () => mockFirebaseRepo.signInWithGoogle(),
      ).thenAnswer((_) async => AuthSuccess(firebaseUser));

      final hybridRepo = createHybridRepo();
      final result = await hybridRepo.signInWithGoogle();

      expect(result, isA<AuthSuccess>());

      // Should not attempt any migration
      verifyNever(() => mockLocalProgress.loadForUser(any()));
      verifyNever(() => mockFirestoreProgress.saveForUser(any(), any()));
      verifyNever(
        () => mockLeaderboard.submitScore(
          userId: any(named: 'userId'),
          stars: any(named: 'stars'),
          levelId: any(named: 'levelId'),
        ),
      );

      hybridRepo.dispose();
    });

    test('handles migration without leaderboard repository', () async {
      final guestUser = User.guest();
      final firebaseUser = User(
        id: 'firebase-456',
        username: 'Test User',
        createdAt: DateTime.now(),
        email: 'test@example.com',
        isGuest: false,
      );

      final localProgressState = ProgressState(
        levels: {0: const LevelProgress(completed: true, stars: 3)},
      );

      when(
        () => mockGuestRepo.getCurrentUser(),
      ).thenAnswer((_) async => guestUser);
      when(
        () => mockFirebaseRepo.signInWithGoogle(),
      ).thenAnswer((_) async => AuthSuccess(firebaseUser));
      when(
        () => mockLocalProgress.loadForUser('guest'),
      ).thenAnswer((_) async => localProgressState);
      when(
        () => mockFirestoreProgress.saveForUser(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => mockLocalProgress.resetForUser('guest'),
      ).thenAnswer((_) async {});
      when(() => mockGuestRepo.signOut()).thenAnswer((_) async {});

      final repo = createHybridRepo();
      final result = await repo.signInWithGoogle();

      expect(result, isA<AuthSuccess>());

      // Should migrate progress (no leaderboard submission anymore)
      verify(() => mockFirestoreProgress.saveForUser(any(), any())).called(1);

      repo.dispose();
    });
  });
}
