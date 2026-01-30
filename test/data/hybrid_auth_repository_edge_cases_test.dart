import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/data/hybrid_auth_repository.dart';
import 'package:hex_buzz/domain/models/auth_result.dart';
import 'package:hex_buzz/domain/models/user.dart';
import 'package:hex_buzz/domain/services/auth_repository.dart';
import 'package:hex_buzz/domain/services/progress_repository.dart';
import 'package:hex_buzz/domain/models/progress_state.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuthRepository extends Mock implements AuthRepository {}

class MockGuestAuthRepository extends Mock implements AuthRepository {}

class MockLocalProgressRepository extends Mock implements ProgressRepository {}

class MockFirestoreProgressRepository extends Mock
    implements ProgressRepository {}

void main() {
  group('HybridAuthRepository Edge Cases', () {
    late MockFirebaseAuthRepository mockFirebaseRepo;
    late MockGuestAuthRepository mockGuestRepo;
    late MockLocalProgressRepository mockLocalProgress;
    late MockFirestoreProgressRepository mockFirestoreProgress;
    late HybridAuthRepository hybridRepo;

    setUp(() {
      mockFirebaseRepo = MockFirebaseAuthRepository();
      mockGuestRepo = MockGuestAuthRepository();
      mockLocalProgress = MockLocalProgressRepository();
      mockFirestoreProgress = MockFirestoreProgressRepository();

      hybridRepo = HybridAuthRepository(
        firebaseRepo: mockFirebaseRepo,
        guestRepo: mockGuestRepo,
        localProgress: mockLocalProgress,
        firestoreProgress: mockFirestoreProgress,
      );

      // Setup default behaviors
      when(
        () => mockFirebaseRepo.authStateChanges(),
      ).thenAnswer((_) => Stream.value(null));
      when(
        () => mockGuestRepo.authStateChanges(),
      ).thenAnswer((_) => Stream.value(null));
    });

    test(
      'signInWithGoogle migrates guest progress to firebase on success',
      () async {
        final guestUser = User(
          id: 'guest-123',
          username: 'Guest',
          createdAt: DateTime.now(),
          isGuest: true,
        );

        final firebaseUser = User(
          id: 'firebase-456',
          username: 'Test User',
          createdAt: DateTime.now(),
          isGuest: false,
          uid: 'firebase-456',
          email: 'test@example.com',
        );

        final guestProgress = ProgressState(
          completedLevels: {'level-1', 'level-2'},
          levelProgress: {
            'level-1': (stars: 3, bestTime: 10000),
            'level-2': (stars: 2, bestTime: 25000),
          },
        );

        when(
          () => mockGuestRepo.getCurrentUser(),
        ).thenAnswer((_) async => guestUser);
        when(
          () => mockFirebaseRepo.signInWithGoogle(),
        ).thenAnswer((_) async => AuthSuccess(firebaseUser));
        when(
          () => mockLocalProgress.getProgress(),
        ).thenAnswer((_) async => guestProgress);
        when(
          () => mockFirestoreProgress.saveProgress(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockLeaderboard.migrateGuestProgress(any(), any()),
        ).thenAnswer((_) async => true);
        when(() => mockGuestRepo.logout()).thenAnswer((_) async {});

        final result = await hybridRepo.signInWithGoogle();

        expect(result, isA<AuthSuccess>());
        expect((result as AuthSuccess).user.id, firebaseUser.id);

        // Verify migration happened
        verify(
          () => mockFirestoreProgress.saveProgress(guestProgress),
        ).called(1);
        verify(
          () => mockLeaderboard.migrateGuestProgress(
            guestUser.id,
            firebaseUser.id,
          ),
        ).called(1);
        verify(() => mockGuestRepo.logout()).called(1);
      },
    );

    test('signInWithGoogle does not migrate when no guest user', () async {
      final firebaseUser = User(
        id: 'firebase-456',
        username: 'Test User',
        createdAt: DateTime.now(),
        isGuest: false,
        uid: 'firebase-456',
        email: 'test@example.com',
      );

      when(() => mockGuestRepo.getCurrentUser()).thenAnswer((_) async => null);
      when(
        () => mockFirebaseRepo.signInWithGoogle(),
      ).thenAnswer((_) async => AuthSuccess(firebaseUser));

      final result = await hybridRepo.signInWithGoogle();

      expect(result, isA<AuthSuccess>());

      // Verify no migration
      verifyNever(() => mockFirestoreProgress.saveProgress(any()));
      verifyNever(() => mockLeaderboard.migrateGuestProgress(any(), any()));
    });

    test('signInWithGoogle handles migration errors gracefully', () async {
      final guestUser = User(
        id: 'guest-123',
        username: 'Guest',
        createdAt: DateTime.now(),
        isGuest: true,
      );

      final firebaseUser = User(
        id: 'firebase-456',
        username: 'Test User',
        createdAt: DateTime.now(),
        isGuest: false,
        uid: 'firebase-456',
        email: 'test@example.com',
      );

      final guestProgress = ProgressState(
        completedLevels: {'level-1'},
        levelProgress: {'level-1': (stars: 3, bestTime: 10000)},
      );

      when(
        () => mockGuestRepo.getCurrentUser(),
      ).thenAnswer((_) async => guestUser);
      when(
        () => mockFirebaseRepo.signInWithGoogle(),
      ).thenAnswer((_) async => AuthSuccess(firebaseUser));
      when(
        () => mockLocalProgress.getProgress(),
      ).thenAnswer((_) async => guestProgress);
      when(
        () => mockFirestoreProgress.saveProgress(any()),
      ).thenThrow(Exception('Firestore error'));
      when(
        () => mockLeaderboard.migrateGuestProgress(any(), any()),
      ).thenThrow(Exception('Leaderboard error'));
      when(() => mockGuestRepo.logout()).thenAnswer((_) async {});

      // Should still succeed even if migration fails
      final result = await hybridRepo.signInWithGoogle();

      expect(result, isA<AuthSuccess>());
      verify(() => mockGuestRepo.logout()).called(1);
    });

    test('loginAsGuest delegates to guest repository', () async {
      final guestUser = User(
        id: 'guest-123',
        username: 'Guest',
        createdAt: DateTime.now(),
        isGuest: true,
      );

      when(
        () => mockGuestRepo.loginAsGuest(),
      ).thenAnswer((_) async => AuthSuccess(guestUser));

      final result = await hybridRepo.loginAsGuest();

      expect(result, isA<AuthSuccess>());
      expect((result as AuthSuccess).user.isGuest, true);
      verify(() => mockGuestRepo.loginAsGuest()).called(1);
    });

    test('logout signs out from both repositories', () async {
      when(() => mockFirebaseRepo.logout()).thenAnswer((_) async {});
      when(() => mockGuestRepo.logout()).thenAnswer((_) async {});

      await hybridRepo.logout();

      verify(() => mockFirebaseRepo.logout()).called(1);
      verify(() => mockGuestRepo.logout()).called(1);
    });

    test('getCurrentUser returns Firebase user when available', () async {
      final firebaseUser = User(
        id: 'firebase-456',
        username: 'Test User',
        createdAt: DateTime.now(),
        isGuest: false,
        uid: 'firebase-456',
        email: 'test@example.com',
      );

      when(
        () => mockFirebaseRepo.getCurrentUser(),
      ).thenAnswer((_) async => firebaseUser);
      when(() => mockGuestRepo.getCurrentUser()).thenAnswer((_) async => null);

      final user = await hybridRepo.getCurrentUser();

      expect(user, firebaseUser);
      expect(user?.isGuest, false);
    });

    test('getCurrentUser returns guest user when no Firebase user', () async {
      final guestUser = User(
        id: 'guest-123',
        username: 'Guest',
        createdAt: DateTime.now(),
        isGuest: true,
      );

      when(
        () => mockFirebaseRepo.getCurrentUser(),
      ).thenAnswer((_) async => null);
      when(
        () => mockGuestRepo.getCurrentUser(),
      ).thenAnswer((_) async => guestUser);

      final user = await hybridRepo.getCurrentUser();

      expect(user, guestUser);
      expect(user?.isGuest, true);
    });

    test('getCurrentUser returns null when no user signed in', () async {
      when(
        () => mockFirebaseRepo.getCurrentUser(),
      ).thenAnswer((_) async => null);
      when(() => mockGuestRepo.getCurrentUser()).thenAnswer((_) async => null);

      final user = await hybridRepo.getCurrentUser();

      expect(user, isNull);
    });

    test('signOut clears both auth states', () async {
      when(() => mockFirebaseRepo.signOut()).thenAnswer((_) async {});
      when(() => mockGuestRepo.signOut()).thenAnswer((_) async {});

      await hybridRepo.signOut();

      verify(() => mockFirebaseRepo.signOut()).called(1);
      verify(() => mockGuestRepo.signOut()).called(1);
    });

    test('login and register are not supported', () async {
      final loginResult = await hybridRepo.login('user', 'pass');
      expect(loginResult, isA<AuthFailure>());
      expect((loginResult as AuthFailure).error, contains('not supported'));

      final registerResult = await hybridRepo.register('user', 'pass');
      expect(registerResult, isA<AuthFailure>());
      expect((registerResult as AuthFailure).error, contains('not supported'));
    });

    test('authStateChanges emits Firebase user when available', () async {
      final firebaseUser = User(
        id: 'firebase-456',
        username: 'Test User',
        createdAt: DateTime.now(),
        isGuest: false,
        uid: 'firebase-456',
      );

      when(
        () => mockFirebaseRepo.authStateChanges(),
      ).thenAnswer((_) => Stream.value(firebaseUser));
      when(
        () => mockGuestRepo.authStateChanges(),
      ).thenAnswer((_) => Stream.value(null));

      final user = await hybridRepo.authStateChanges().first;

      expect(user, firebaseUser);
    });

    test('authStateChanges emits guest user when no Firebase user', () async {
      final guestUser = User(
        id: 'guest-123',
        username: 'Guest',
        createdAt: DateTime.now(),
        isGuest: true,
      );

      when(
        () => mockFirebaseRepo.authStateChanges(),
      ).thenAnswer((_) => Stream.value(null));
      when(
        () => mockGuestRepo.authStateChanges(),
      ).thenAnswer((_) => Stream.value(guestUser));

      final user = await hybridRepo.authStateChanges().first;

      expect(user, guestUser);
    });
  });
}
