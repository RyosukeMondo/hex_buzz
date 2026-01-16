import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/auth_result.dart';
import 'package:hex_buzz/presentation/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

import 'auth_test_helpers.dart';

void main() {
  late MockAuthRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockAuthRepository();

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
    test('successful Google sign-in updates state with user', () async {
      when(() => mockRepository.getCurrentUser()).thenAnswer((_) async => null);
      when(
        () => mockRepository.signInWithGoogle(),
      ).thenAnswer((_) async => AuthSuccess(testUser));

      await container.read(authProvider.future);

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.signInWithGoogle();

      expect(result, isA<AuthSuccess>());
      final user = (result as AuthSuccess).user;
      expect(user, testUser);

      final state = container.read(authProvider);
      expect(state.value, testUser);
    });

    test('failed Google sign-in sets state to null', () async {
      when(() => mockRepository.getCurrentUser()).thenAnswer((_) async => null);
      when(
        () => mockRepository.signInWithGoogle(),
      ).thenAnswer((_) async => const AuthFailure('Google sign-in cancelled'));

      await container.read(authProvider.future);

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.signInWithGoogle();

      expect(result, isA<AuthFailure>());
      final error = (result as AuthFailure).error;
      expect(error, 'Google sign-in cancelled');

      final state = container.read(authProvider);
      expect(state.value, isNull);
    });

    test('Google sign-in handles network errors gracefully', () async {
      when(() => mockRepository.getCurrentUser()).thenAnswer((_) async => null);
      when(() => mockRepository.signInWithGoogle()).thenAnswer(
        (_) async => const AuthFailure('Network error during sign-in'),
      );

      await container.read(authProvider.future);

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.signInWithGoogle();

      expect(result, isA<AuthFailure>());
      final error = (result as AuthFailure).error;
      expect(error, 'Network error during sign-in');

      final state = container.read(authProvider);
      expect(state.value, isNull);
    });

    test('signInWithGoogle sets loading state during operation', () async {
      when(() => mockRepository.getCurrentUser()).thenAnswer((_) async => null);
      when(() => mockRepository.signInWithGoogle()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return AuthSuccess(testUser);
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
      expect(finalState.value, testUser);
    });

    test('signInWithGoogle calls repository method', () async {
      when(() => mockRepository.getCurrentUser()).thenAnswer((_) async => null);
      when(
        () => mockRepository.signInWithGoogle(),
      ).thenAnswer((_) async => AuthSuccess(testUser));

      await container.read(authProvider.future);

      final notifier = container.read(authProvider.notifier);
      await notifier.signInWithGoogle();

      verify(() => mockRepository.signInWithGoogle()).called(1);
    });
  });
}
