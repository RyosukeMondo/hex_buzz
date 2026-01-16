import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/auth_result.dart';
import 'package:hex_buzz/domain/models/user.dart';
import 'package:hex_buzz/presentation/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

import 'auth_test_helpers.dart';

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

  group('AuthNotifier', () {
    group('build', () {
      test('loads current user on initialization', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => testUser);

        // Access the provider to trigger build
        container.read(authProvider);

        // Wait for async initialization
        await container.read(authProvider.future);

        // Verify getCurrentUser was called
        verify(() => mockRepository.getCurrentUser()).called(1);

        // Check final state
        final state = container.read(authProvider);
        expect(state.value, testUser);
      });

      test('returns null when no user is logged in', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);

        await container.read(authProvider.future);

        final state = container.read(authProvider);
        expect(state.value, isNull);
      });
    });

    group('login', () {
      test('successful login updates state with user', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);
        when(
          () => mockRepository.login('testuser', 'password123'),
        ).thenAnswer((_) async => AuthSuccess(testUser));

        // Initialize
        await container.read(authProvider.future);

        // Perform login
        final notifier = container.read(authProvider.notifier);
        final result = await notifier.login('testuser', 'password123');

        expect(result, isA<AuthSuccess>());
        final user = (result as AuthSuccess).user;
        expect(user, testUser);

        final state = container.read(authProvider);
        expect(state.value, testUser);
      });

      test('failed login sets state to null', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);
        when(
          () => mockRepository.login('testuser', 'wrongpassword'),
        ).thenAnswer((_) async => const AuthFailure('Invalid password'));

        await container.read(authProvider.future);

        final notifier = container.read(authProvider.notifier);
        final result = await notifier.login('testuser', 'wrongpassword');

        expect(result, isA<AuthFailure>());
        final error = (result as AuthFailure).error;
        expect(error, 'Invalid password');

        final state = container.read(authProvider);
        expect(state.value, isNull);
      });

      test('login returns error message on failure', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);
        when(
          () => mockRepository.login('nonexistent', 'password123'),
        ).thenAnswer((_) async => const AuthFailure('User not found'));

        await container.read(authProvider.future);

        final notifier = container.read(authProvider.notifier);
        final result = await notifier.login('nonexistent', 'password123');

        expect(result, isA<AuthFailure>());
        final error = (result as AuthFailure).error;
        expect(error, 'User not found');
      });

      test('login sets loading state during operation', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);
        when(() => mockRepository.login(any(), any())).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return AuthSuccess(testUser);
        });

        await container.read(authProvider.future);

        final notifier = container.read(authProvider.notifier);

        // Start login but don't await
        final future = notifier.login('testuser', 'password123');

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
    });

    group('register', () {
      test('successful registration updates state with user', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);
        when(
          () => mockRepository.register('newuser', 'password123'),
        ).thenAnswer((_) async => AuthSuccess(testUser));

        await container.read(authProvider.future);

        final notifier = container.read(authProvider.notifier);
        final result = await notifier.register('newuser', 'password123');

        expect(result, isA<AuthSuccess>());
        final user = (result as AuthSuccess).user;
        expect(user, testUser);

        final state = container.read(authProvider);
        expect(state.value, testUser);
      });

      test('failed registration sets state to null', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);
        when(
          () => mockRepository.register('existinguser', 'password123'),
        ).thenAnswer((_) async => const AuthFailure('Username already taken'));

        await container.read(authProvider.future);

        final notifier = container.read(authProvider.notifier);
        final result = await notifier.register('existinguser', 'password123');

        expect(result, isA<AuthFailure>());
        final error = (result as AuthFailure).error;
        expect(error, 'Username already taken');

        final state = container.read(authProvider);
        expect(state.value, isNull);
      });

      test('registration validates username length', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);
        when(() => mockRepository.register('ab', 'password123')).thenAnswer(
          (_) async =>
              const AuthFailure('Username must be at least 3 characters'),
        );

        await container.read(authProvider.future);

        final notifier = container.read(authProvider.notifier);
        final result = await notifier.register('ab', 'password123');

        expect(result, isA<AuthFailure>());
        final error = (result as AuthFailure).error;
        expect(error, 'Username must be at least 3 characters');
      });

      test('registration validates password length', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);
        when(() => mockRepository.register('testuser', '12345')).thenAnswer(
          (_) async =>
              const AuthFailure('Password must be at least 6 characters'),
        );

        await container.read(authProvider.future);

        final notifier = container.read(authProvider.notifier);
        final result = await notifier.register('testuser', '12345');

        expect(result, isA<AuthFailure>());
        final error = (result as AuthFailure).error;
        expect(error, 'Password must be at least 6 characters');
      });

      test('register sets loading state during operation', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);
        when(() => mockRepository.register(any(), any())).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return AuthSuccess(testUser);
        });

        await container.read(authProvider.future);

        final notifier = container.read(authProvider.notifier);

        // Start register but don't await
        final future = notifier.register('newuser', 'password123');

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
    });

    group('logout', () {
      test('logout clears user state', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => testUser);
        when(() => mockRepository.logout()).thenAnswer((_) async {});

        await container.read(authProvider.future);

        // Verify user is logged in
        expect(container.read(authProvider).value, testUser);

        // Perform logout
        final notifier = container.read(authProvider.notifier);
        await notifier.logout();

        verify(() => mockRepository.logout()).called(1);

        final state = container.read(authProvider);
        expect(state.value, isNull);
      });

      test('logout is idempotent (no error when not logged in)', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);
        when(() => mockRepository.logout()).thenAnswer((_) async {});

        await container.read(authProvider.future);

        final notifier = container.read(authProvider.notifier);
        await notifier.logout();

        verify(() => mockRepository.logout()).called(1);

        final state = container.read(authProvider);
        expect(state.value, isNull);
      });

      test('logout sets loading state during operation', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => testUser);
        when(() => mockRepository.logout()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
        });

        await container.read(authProvider.future);

        final notifier = container.read(authProvider.notifier);

        // Start logout but don't await
        final future = notifier.logout();

        // Check loading state immediately
        await Future.delayed(Duration.zero);
        final loadingState = container.read(authProvider);
        expect(loadingState.isLoading, isTrue);

        // Wait for completion
        await future;

        final finalState = container.read(authProvider);
        expect(finalState.isLoading, isFalse);
        expect(finalState.value, isNull);
      });
    });

    group('signOut', () {
      test('signOut clears user state', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => testUser);
        when(() => mockRepository.signOut()).thenAnswer((_) async {});

        await container.read(authProvider.future);

        // Verify user is logged in
        expect(container.read(authProvider).value, testUser);

        // Perform signOut
        final notifier = container.read(authProvider.notifier);
        await notifier.signOut();

        verify(() => mockRepository.signOut()).called(1);

        final state = container.read(authProvider);
        expect(state.value, isNull);
      });

      test('signOut is idempotent (no error when not logged in)', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);
        when(() => mockRepository.signOut()).thenAnswer((_) async {});

        await container.read(authProvider.future);

        final notifier = container.read(authProvider.notifier);
        await notifier.signOut();

        verify(() => mockRepository.signOut()).called(1);

        final state = container.read(authProvider);
        expect(state.value, isNull);
      });

      test('signOut sets loading state during operation', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => testUser);
        when(() => mockRepository.signOut()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
        });

        await container.read(authProvider.future);

        final notifier = container.read(authProvider.notifier);

        // Start signOut but don't await
        final future = notifier.signOut();

        // Check loading state immediately
        await Future.delayed(Duration.zero);
        final loadingState = container.read(authProvider);
        expect(loadingState.isLoading, isTrue);

        // Wait for completion
        await future;

        final finalState = container.read(authProvider);
        expect(finalState.isLoading, isFalse);
        expect(finalState.value, isNull);
      });
    });

    group('playAsGuest', () {
      test('playAsGuest creates guest user session', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);
        when(
          () => mockRepository.loginAsGuest(),
        ).thenAnswer((_) async => AuthSuccess(guestUser));

        await container.read(authProvider.future);

        final notifier = container.read(authProvider.notifier);
        final result = await notifier.playAsGuest();

        expect(result, isA<AuthSuccess>());
        final user = (result as AuthSuccess).user;
        expect(user.isGuest, isTrue);

        final state = container.read(authProvider);
        expect(state.value!.isGuest, isTrue);
        expect(state.value!.username, 'Guest');
      });

      test('playAsGuest sets loading state during operation', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);
        when(() => mockRepository.loginAsGuest()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return AuthSuccess(guestUser);
        });

        await container.read(authProvider.future);

        final notifier = container.read(authProvider.notifier);

        // Start playAsGuest but don't await
        final future = notifier.playAsGuest();

        // Check loading state immediately
        await Future.delayed(Duration.zero);
        final loadingState = container.read(authProvider);
        expect(loadingState.isLoading, isTrue);

        // Wait for completion
        await future;

        final finalState = container.read(authProvider);
        expect(finalState.isLoading, isFalse);
        expect(finalState.value!.isGuest, isTrue);
      });

      test('playAsGuest handles failure gracefully', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);
        when(
          () => mockRepository.loginAsGuest(),
        ).thenAnswer((_) async => const AuthFailure('Guest mode unavailable'));

        await container.read(authProvider.future);

        final notifier = container.read(authProvider.notifier);
        final result = await notifier.playAsGuest();

        expect(result, isA<AuthFailure>());
        final error = (result as AuthFailure).error;
        expect(error, 'Guest mode unavailable');

        final state = container.read(authProvider);
        expect(state.value, isNull);
      });
    });

    group('state transitions', () {
      test('login after logout works correctly', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => testUser);
        when(() => mockRepository.logout()).thenAnswer((_) async {});
        when(
          () => mockRepository.login('testuser', 'password123'),
        ).thenAnswer((_) async => AuthSuccess(testUser));

        await container.read(authProvider.future);
        final notifier = container.read(authProvider.notifier);

        // Logout
        await notifier.logout();
        expect(container.read(authProvider).value, isNull);

        // Login again
        await notifier.login('testuser', 'password123');
        expect(container.read(authProvider).value, testUser);
      });

      test('register after failed login works correctly', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);
        when(
          () => mockRepository.login('nonexistent', 'password'),
        ).thenAnswer((_) async => const AuthFailure('User not found'));
        when(
          () => mockRepository.register('newuser', 'password123'),
        ).thenAnswer((_) async => AuthSuccess(testUser));

        await container.read(authProvider.future);
        final notifier = container.read(authProvider.notifier);

        // Failed login
        await notifier.login('nonexistent', 'password');
        expect(container.read(authProvider).value, isNull);

        // Successful registration
        await notifier.register('newuser', 'password123');
        expect(container.read(authProvider).value, testUser);
      });

      test('switching from guest to registered user', () async {
        final registeredUser = User(
          id: 'registered-id',
          username: 'registereduser',
          createdAt: DateTime(2024, 1, 1),
          isGuest: false,
        );

        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);
        when(
          () => mockRepository.loginAsGuest(),
        ).thenAnswer((_) async => AuthSuccess(guestUser));
        when(() => mockRepository.logout()).thenAnswer((_) async {});
        when(
          () => mockRepository.register('registereduser', 'password123'),
        ).thenAnswer((_) async => AuthSuccess(registeredUser));

        await container.read(authProvider.future);
        final notifier = container.read(authProvider.notifier);

        // Play as guest
        await notifier.playAsGuest();
        expect(container.read(authProvider).value!.isGuest, isTrue);

        // Logout guest
        await notifier.logout();
        expect(container.read(authProvider).value, isNull);

        // Register new account
        await notifier.register('registereduser', 'password123');
        expect(container.read(authProvider).value!.isGuest, isFalse);
        expect(container.read(authProvider).value!.username, 'registereduser');
      });
    });

    group('repository calls', () {
      test('login calls repository with correct parameters', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);
        when(
          () => mockRepository.login(any(), any()),
        ).thenAnswer((_) async => AuthSuccess(testUser));

        await container.read(authProvider.future);

        final notifier = container.read(authProvider.notifier);
        await notifier.login('myusername', 'mypassword');

        verify(
          () => mockRepository.login('myusername', 'mypassword'),
        ).called(1);
      });

      test('register calls repository with correct parameters', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);
        when(
          () => mockRepository.register(any(), any()),
        ).thenAnswer((_) async => AuthSuccess(testUser));

        await container.read(authProvider.future);

        final notifier = container.read(authProvider.notifier);
        await notifier.register('newusername', 'newpassword');

        verify(
          () => mockRepository.register('newusername', 'newpassword'),
        ).called(1);
      });

      test('logout calls repository logout method', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => testUser);
        when(() => mockRepository.logout()).thenAnswer((_) async {});

        await container.read(authProvider.future);

        final notifier = container.read(authProvider.notifier);
        await notifier.logout();

        verify(() => mockRepository.logout()).called(1);
      });

      test('playAsGuest calls repository loginAsGuest method', () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);
        when(
          () => mockRepository.loginAsGuest(),
        ).thenAnswer((_) async => AuthSuccess(guestUser));

        await container.read(authProvider.future);

        final notifier = container.read(authProvider.notifier);
        await notifier.playAsGuest();

        verify(() => mockRepository.loginAsGuest()).called(1);
      });
    });
  });

  group('authRepositoryProvider', () {
    test('throws UnimplementedError when not overridden', () {
      final bareContainer = ProviderContainer();

      expect(
        () => bareContainer.read(authRepositoryProvider),
        throwsA(isA<UnimplementedError>()),
      );

      bareContainer.dispose();
    });

    test('returns overridden repository', () {
      final repository = container.read(authRepositoryProvider);
      expect(repository, mockRepository);
    });
  });
}
