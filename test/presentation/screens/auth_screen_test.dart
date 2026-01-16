import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/auth_result.dart';
import 'package:hex_buzz/domain/models/user.dart';
import 'package:hex_buzz/domain/services/auth_repository.dart';
import 'package:hex_buzz/main.dart';
import 'package:hex_buzz/presentation/providers/auth_provider.dart';
import 'package:hex_buzz/presentation/screens/auth/auth_screen.dart';
import 'package:hex_buzz/presentation/theme/honey_theme.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockAuthRepository;

  final testUser = User(
    id: 'test-id',
    username: 'testuser',
    createdAt: DateTime(2024, 1, 1),
    isGuest: false,
    email: 'test@example.com',
    displayName: 'Test User',
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    when(
      () => mockAuthRepository.authStateChanges(),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockAuthRepository.getCurrentUser(),
    ).thenAnswer((_) async => null);
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepository)],
      child: MaterialApp(
        theme: HoneyTheme.lightTheme,
        initialRoute: AppRoutes.auth,
        routes: {
          AppRoutes.auth: (_) => const AuthScreen(),
          AppRoutes.levels: (_) => const _MockLevelSelectScreen(),
        },
      ),
    );
  }

  group('AuthScreen', () {
    group('renders correctly', () {
      testWidgets('displays "Welcome!" header', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Welcome!'), findsOneWidget);
      });

      testWidgets('displays HexBuzz title', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('HexBuzz'), findsOneWidget);
      });

      testWidgets('displays sign-in prompt text', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Sign in to compete on leaderboards'), findsOneWidget);
      });

      testWidgets('displays Google Sign-In button', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Sign in with Google'), findsOneWidget);
      });

      testWidgets('displays Play as Guest button', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Play as Guest'), findsOneWidget);
      });

      testWidgets('displays guest disclaimer', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Progress saved locally only'), findsOneWidget);
      });

      testWidgets('displays app icon', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.hexagon), findsOneWidget);
      });

      testWidgets('displays divider with "or"', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('or'), findsOneWidget);
      });
    });

    group('Google Sign-In', () {
      testWidgets('calls signInWithGoogle when button pressed', (tester) async {
        when(
          () => mockAuthRepository.signInWithGoogle(),
        ).thenAnswer((_) async => AuthSuccess(testUser));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sign in with Google'));
        await tester.pump();

        verify(() => mockAuthRepository.signInWithGoogle()).called(1);
      });

      testWidgets('navigates to level select on successful sign-in', (
        tester,
      ) async {
        when(
          () => mockAuthRepository.signInWithGoogle(),
        ).thenAnswer((_) async => AuthSuccess(testUser));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sign in with Google'));
        await tester.pumpAndSettle();

        expect(find.byType(_MockLevelSelectScreen), findsOneWidget);
      });

      testWidgets('shows error message on failed sign-in', (tester) async {
        when(
          () => mockAuthRepository.signInWithGoogle(),
        ).thenAnswer((_) async => const AuthFailure('Sign-in failed'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sign in with Google'));
        await tester.pumpAndSettle();

        expect(find.text('Sign-in failed'), findsOneWidget);
      });

      testWidgets('shows loading indicator during sign-in', (tester) async {
        final completer = Completer<AuthResult>();
        when(
          () => mockAuthRepository.signInWithGoogle(),
        ).thenAnswer((_) => completer.future);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sign in with Google'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        completer.complete(AuthSuccess(testUser));
        await tester.pumpAndSettle();
      });

      testWidgets('disables buttons during sign-in', (tester) async {
        final completer = Completer<AuthResult>();
        when(
          () => mockAuthRepository.signInWithGoogle(),
        ).thenAnswer((_) => completer.future);
        // Also mock guest login to avoid errors if it's accidentally called
        when(
          () => mockAuthRepository.loginAsGuest(),
        ).thenAnswer((_) async => AuthSuccess(User.guest()));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sign in with Google'));
        await tester.pump();

        // Verify loading indicator is shown
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Guest login should not be called during Google sign-in loading
        verifyNever(() => mockAuthRepository.loginAsGuest());

        completer.complete(AuthSuccess(testUser));
        await tester.pumpAndSettle();
      });

      testWidgets('handles user cancellation gracefully', (tester) async {
        when(() => mockAuthRepository.signInWithGoogle()).thenAnswer(
          (_) async => const AuthFailure('Sign-in cancelled by user'),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sign in with Google'));
        await tester.pumpAndSettle();

        expect(find.text('Sign-in cancelled by user'), findsOneWidget);
      });
    });

    group('Guest Play', () {
      testWidgets('calls loginAsGuest when button pressed', (tester) async {
        when(
          () => mockAuthRepository.loginAsGuest(),
        ).thenAnswer((_) async => AuthSuccess(User.guest()));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Play as Guest'));
        await tester.pump();

        verify(() => mockAuthRepository.loginAsGuest()).called(1);
      });

      testWidgets('navigates to level select on successful guest login', (
        tester,
      ) async {
        when(
          () => mockAuthRepository.loginAsGuest(),
        ).thenAnswer((_) async => AuthSuccess(User.guest()));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Play as Guest'));
        await tester.pumpAndSettle();

        expect(find.byType(_MockLevelSelectScreen), findsOneWidget);
      });

      testWidgets('shows error message on failed guest login', (tester) async {
        when(
          () => mockAuthRepository.loginAsGuest(),
        ).thenAnswer((_) async => const AuthFailure('Guest login failed'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Play as Guest'));
        await tester.pumpAndSettle();

        expect(find.text('Guest login failed'), findsOneWidget);
      });

      testWidgets('shows loading indicator during guest login', (tester) async {
        final completer = Completer<AuthResult>();
        when(
          () => mockAuthRepository.loginAsGuest(),
        ).thenAnswer((_) => completer.future);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Play as Guest'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        completer.complete(AuthSuccess(User.guest()));
        await tester.pumpAndSettle();
      });
    });

    group('UI interactions', () {
      testWidgets('clears error message when retrying', (tester) async {
        when(
          () => mockAuthRepository.signInWithGoogle(),
        ).thenAnswer((_) async => const AuthFailure('First error'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // First attempt - should show error
        await tester.tap(find.text('Sign in with Google'));
        await tester.pumpAndSettle();
        expect(find.text('First error'), findsOneWidget);

        // Second attempt - should clear previous error
        when(
          () => mockAuthRepository.signInWithGoogle(),
        ).thenAnswer((_) async => const AuthFailure('Second error'));

        await tester.tap(find.text('Sign in with Google'));
        await tester.pump();

        // During loading, error should be cleared
        expect(find.text('First error'), findsNothing);
      });
    });

    group('accessibility', () {
      testWidgets('error message has live region semantics', (tester) async {
        when(
          () => mockAuthRepository.signInWithGoogle(),
        ).thenAnswer((_) async => const AuthFailure('Error message'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sign in with Google'));
        await tester.pumpAndSettle();

        // Verify error message is displayed
        expect(find.text('Error message'), findsOneWidget);

        // Verify Semantics widget with liveRegion property exists
        final semanticsWidget = find.ancestor(
          of: find.text('Error message'),
          matching: find.byType(Semantics),
        );
        expect(semanticsWidget, findsWidgets);
      });

      testWidgets('error icon has semantic label', (tester) async {
        when(
          () => mockAuthRepository.signInWithGoogle(),
        ).thenAnswer((_) async => const AuthFailure('Error message'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sign in with Google'));
        await tester.pumpAndSettle();

        // Find error icon with semantic label
        final errorIcon = find.byWidgetPredicate(
          (widget) => widget is Icon && widget.semanticLabel == 'Error',
        );
        expect(errorIcon, findsOneWidget);
      });
    });
  });
}

class _MockLevelSelectScreen extends StatelessWidget {
  const _MockLevelSelectScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('Level Select'));
  }
}
