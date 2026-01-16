import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/auth_result.dart';
import 'package:hex_buzz/domain/models/user.dart';
import 'package:hex_buzz/presentation/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

import 'auth_test_helpers.dart';

/// Tests for Google Sign-In functionality in AuthProvider.
///
/// Separated from main auth_provider_test.dart to comply with
/// 500 LOC file size limit.
void main() {
  late MockAuthRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockAuthRepository();

    // Default behavior for authStateChanges
    when(
      () => mockRepository.authStateChanges(),
    ).thenAnswer((_) => const Stream.empty());

    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthNotifier - signInWithGoogle', () {
    test('successful Google Sign-In updates state with user', () async {
      final googleUser = User(
        id: 'google-id',
        username: 'googleuser',
        createdAt: DateTime(2024, 1, 1),
        isGuest: false,
        uid: 'google-uid-123',
        email: 'user@gmail.com',
        displayName: 'Google User',
        photoURL: 'https://example.com/photo.jpg',
      );

      when(() => mockRepository.getCurrentUser()).thenAnswer((_) async => null);
      when(
        () => mockRepository.signInWithGoogle(),
      ).thenAnswer((_) async => AuthSuccess(googleUser));

      await container.read(authProvider.future);

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.signInWithGoogle();

      expect(result, isA<AuthSuccess>());
      final user = (result as AuthSuccess).user;
      expect(user, googleUser);
      expect(user.email, 'user@gmail.com');
      expect(user.displayName, 'Google User');

      final state = container.read(authProvider);
      expect(state.value, googleUser);
      verify(() => mockRepository.signInWithGoogle()).called(1);
    });

    test('failed Google Sign-In sets state to null', () async {
      when(() => mockRepository.getCurrentUser()).thenAnswer((_) async => null);
      when(
        () => mockRepository.signInWithGoogle(),
      ).thenAnswer((_) async => const AuthFailure('User cancelled sign-in'));

      await container.read(authProvider.future);

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.signInWithGoogle();

      expect(result, isA<AuthFailure>());
      final error = (result as AuthFailure).error;
      expect(error, 'User cancelled sign-in');

      final state = container.read(authProvider);
      expect(state.value, isNull);
    });

    test('Google Sign-In handles network error', () async {
      when(() => mockRepository.getCurrentUser()).thenAnswer((_) async => null);
      when(
        () => mockRepository.signInWithGoogle(),
      ).thenAnswer((_) async => const AuthFailure('Network error'));

      await container.read(authProvider.future);

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.signInWithGoogle();

      expect(result, isA<AuthFailure>());
      final error = (result as AuthFailure).error;
      expect(error, 'Network error');
    });

    test('signInWithGoogle sets loading state during operation', () async {
      final googleUser = User(
        id: 'google-id',
        username: 'googleuser',
        createdAt: DateTime(2024, 1, 1),
        isGuest: false,
        uid: 'google-uid-123',
        email: 'user@gmail.com',
      );

      when(() => mockRepository.getCurrentUser()).thenAnswer((_) async => null);
      when(() => mockRepository.signInWithGoogle()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return AuthSuccess(googleUser);
      });

      await container.read(authProvider.future);

      final notifier = container.read(authProvider.notifier);

      // Start sign-in but don't await
      final future = notifier.signInWithGoogle();

      // Check loading state immediately
      await Future.delayed(Duration.zero);
      final loadingState = container.read(authProvider);
      expect(loadingState.isLoading, isTrue);

      // Wait for completion
      await future;

      final finalState = container.read(authProvider);
      expect(finalState.isLoading, isFalse);
      expect(finalState.value, googleUser);
    });

    test('signInWithGoogle calls repository method', () async {
      final googleUser = User(
        id: 'google-id',
        username: 'googleuser',
        createdAt: DateTime(2024, 1, 1),
        isGuest: false,
        uid: 'google-uid-123',
        email: 'user@gmail.com',
      );

      when(() => mockRepository.getCurrentUser()).thenAnswer((_) async => null);
      when(
        () => mockRepository.signInWithGoogle(),
      ).thenAnswer((_) async => AuthSuccess(googleUser));

      await container.read(authProvider.future);

      final notifier = container.read(authProvider.notifier);
      await notifier.signInWithGoogle();

      verify(() => mockRepository.signInWithGoogle()).called(1);
    });

    test('Google Sign-In after guest session works correctly', () async {
      final googleUser = User(
        id: 'google-id',
        username: 'googleuser',
        createdAt: DateTime(2024, 1, 1),
        isGuest: false,
        uid: 'google-uid-123',
        email: 'user@gmail.com',
        displayName: 'Google User',
      );

      when(() => mockRepository.getCurrentUser()).thenAnswer((_) async => null);
      when(
        () => mockRepository.loginAsGuest(),
      ).thenAnswer((_) async => AuthSuccess(guestUser));
      when(() => mockRepository.logout()).thenAnswer((_) async {});
      when(
        () => mockRepository.signInWithGoogle(),
      ).thenAnswer((_) async => AuthSuccess(googleUser));

      await container.read(authProvider.future);
      final notifier = container.read(authProvider.notifier);

      // Play as guest
      await notifier.playAsGuest();
      expect(container.read(authProvider).value!.isGuest, isTrue);

      // Logout guest
      await notifier.logout();
      expect(container.read(authProvider).value, isNull);

      // Sign in with Google
      await notifier.signInWithGoogle();
      expect(container.read(authProvider).value!.isGuest, isFalse);
      expect(container.read(authProvider).value!.email, 'user@gmail.com');
      expect(container.read(authProvider).value!.displayName, 'Google User');
    });
  });
}
