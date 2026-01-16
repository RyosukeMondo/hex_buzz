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
    group('renders correctly in login mode', () {
      testWidgets('displays "Welcome Back!" header', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Welcome Back!'), findsOneWidget);
      });

      testWidgets('displays HexBuzz title', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('HexBuzz'), findsOneWidget);
      });

      testWidgets('displays username field', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);
      });

      testWidgets('displays password field', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      });

      testWidgets('does not display confirm password field', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(
          find.widgetWithText(TextFormField, 'Confirm Password'),
          findsNothing,
        );
      });

      testWidgets('displays Log In button', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Log In'), findsOneWidget);
      });

      testWidgets('displays toggle to register mode', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text("Don't have an account? Register"), findsOneWidget);
      });

      testWidgets('displays guest mode section', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Play as Guest'), findsOneWidget);
        expect(find.text('Progress saved locally only'), findsOneWidget);
      });
    });

    group('mode switching', () {
      testWidgets('switches to register mode on toggle', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap the toggle button
        await tester.tap(find.text("Don't have an account? Register"));
        await tester.pumpAndSettle();

        // Verify we're now in register mode
        expect(find.text('Create Account'), findsWidgets);
        expect(
          find.widgetWithText(TextFormField, 'Confirm Password'),
          findsOneWidget,
        );
      });

      testWidgets('switches back to login mode', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Switch to register mode
        await tester.tap(find.text("Don't have an account? Register"));
        await tester.pumpAndSettle();

        // Switch back to login mode
        await tester.tap(find.text('Already have an account? Log In'));
        await tester.pumpAndSettle();

        // Verify we're back in login mode
        expect(find.text('Welcome Back!'), findsOneWidget);
        expect(
          find.widgetWithText(TextFormField, 'Confirm Password'),
          findsNothing,
        );
      });
    });

    group('form validation', () {
      testWidgets('shows error for empty username', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Try to submit with empty form
        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();

        expect(find.text('Username is required'), findsOneWidget);
      });

      testWidgets('shows error for short username', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter short username
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'),
          'ab',
        );
        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();

        expect(
          find.text('Username must be at least 3 characters'),
          findsOneWidget,
        );
      });

      testWidgets('shows error for empty password', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter valid username
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'),
          'testuser',
        );
        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();

        expect(find.text('Password is required'), findsOneWidget);
      });

      testWidgets('shows error for short password', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter valid username and short password
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'),
          'testuser',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          '12345',
        );
        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();

        expect(
          find.text('Password must be at least 6 characters'),
          findsOneWidget,
        );
      });

      testWidgets('shows error for mismatched passwords in register mode', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Switch to register mode
        await tester.tap(find.text("Don't have an account? Register"));
        await tester.pumpAndSettle();

        // Enter valid username and password, mismatched confirm
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'),
          'testuser',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'),
          'different123',
        );

        // Find the Create Account button in ElevatedButton
        await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
        await tester.pumpAndSettle();

        expect(find.text('Passwords do not match'), findsOneWidget);
      });
    });

    group('password visibility toggle', () {
      testWidgets('password is obscured by default', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final passwordField = tester.widget<EditableText>(
          find.descendant(
            of: find.widgetWithText(TextFormField, 'Password'),
            matching: find.byType(EditableText),
          ),
        );

        expect(passwordField.obscureText, isTrue);
      });

      testWidgets('can toggle password visibility', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find visibility toggle by icon (visibility_off initially)
        final visibilityToggle = find.byIcon(Icons.visibility_off).first;

        // Tap to show password
        await tester.tap(visibilityToggle);
        await tester.pumpAndSettle();

        final passwordField = tester.widget<EditableText>(
          find.descendant(
            of: find.widgetWithText(TextFormField, 'Password'),
            matching: find.byType(EditableText),
          ),
        );

        expect(passwordField.obscureText, isFalse);
      });
    });

    group('login functionality', () {
      testWidgets('calls login on repository with valid credentials', (
        tester,
      ) async {
        when(
          () => mockAuthRepository.login('testuser', 'password123'),
        ).thenAnswer((_) async => AuthSuccess(testUser));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'),
          'testuser',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password123',
        );

        // Submit
        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();

        verify(
          () => mockAuthRepository.login('testuser', 'password123'),
        ).called(1);
      });

      testWidgets('shows error message on login failure', (tester) async {
        when(
          () => mockAuthRepository.login('testuser', 'wrongpassword'),
        ).thenAnswer((_) async => AuthFailure('Invalid username or password'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'),
          'testuser',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'wrongpassword',
        );

        // Submit
        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();

        expect(find.text('Invalid username or password'), findsOneWidget);
      });
    });

    group('register functionality', () {
      testWidgets('calls register on repository with valid credentials', (
        tester,
      ) async {
        when(
          () => mockAuthRepository.register('newuser', 'password123'),
        ).thenAnswer((_) async => AuthSuccess(testUser));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Switch to register mode
        await tester.tap(find.text("Don't have an account? Register"));
        await tester.pumpAndSettle();

        // Enter credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'),
          'newuser',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'),
          'password123',
        );

        // Submit
        await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
        await tester.pumpAndSettle();

        verify(
          () => mockAuthRepository.register('newuser', 'password123'),
        ).called(1);
      });

      testWidgets('shows error message on registration failure', (
        tester,
      ) async {
        when(
          () => mockAuthRepository.register('existinguser', 'password123'),
        ).thenAnswer((_) async => AuthFailure('Username already exists'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Switch to register mode
        await tester.tap(find.text("Don't have an account? Register"));
        await tester.pumpAndSettle();

        // Enter credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'),
          'existinguser',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'),
          'password123',
        );

        // Submit
        await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
        await tester.pumpAndSettle();

        expect(find.text('Username already exists'), findsOneWidget);
      });
    });

    group('guest mode', () {
      testWidgets('calls loginAsGuest on repository', (tester) async {
        final guestUser = User.guest();
        when(
          () => mockAuthRepository.loginAsGuest(),
        ).thenAnswer((_) async => AuthSuccess(guestUser));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap play as guest
        await tester.tap(find.text('Play as Guest'));
        await tester.pumpAndSettle();

        verify(() => mockAuthRepository.loginAsGuest()).called(1);
      });

      testWidgets('shows disclaimer about guest progress', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Progress saved locally only'), findsOneWidget);
      });
    });

    group('layout and theming', () {
      testWidgets('uses Scaffold', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('uses SafeArea', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(SafeArea), findsOneWidget);
      });

      testWidgets('uses SingleChildScrollView for scrolling', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });

      testWidgets('displays form in styled container', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find container with BoxDecoration
        final containers = tester.widgetList<Container>(find.byType(Container));
        final hasStyledContainer = containers.any((container) {
          if (container.decoration is! BoxDecoration) return false;
          final decoration = container.decoration as BoxDecoration;
          return decoration.borderRadius != null ||
              decoration.border != null ||
              decoration.color != null;
        });

        expect(hasStyledContainer, isTrue);
      });
    });

    group('loading state', () {
      testWidgets('shows loading indicator during login', (tester) async {
        // Use a Completer to control when the login completes
        final loginCompleter = Completer<AuthResult>();
        when(
          () => mockAuthRepository.login(any(), any()),
        ).thenAnswer((_) => loginCompleter.future);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'),
          'testuser',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password123',
        );

        // Submit and check for loading indicator
        await tester.tap(find.text('Log In'));
        await tester.pump();

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Complete the login to clean up
        loginCompleter.complete(AuthSuccess(testUser));
        await tester.pumpAndSettle();
      });
    });
  });
}

/// Mock LevelSelectScreen for navigation testing.
class _MockLevelSelectScreen extends StatelessWidget {
  const _MockLevelSelectScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Mock Level Select Screen')),
    );
  }
}
