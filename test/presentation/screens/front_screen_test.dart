import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/user.dart';
import 'package:hex_buzz/domain/services/auth_repository.dart';
import 'package:hex_buzz/main.dart';
import 'package:hex_buzz/presentation/providers/auth_provider.dart';
import 'package:hex_buzz/presentation/screens/front/front_screen.dart';
import 'package:hex_buzz/presentation/theme/honey_theme.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    when(
      () => mockAuthRepository.authStateChanges(),
    ).thenAnswer((_) => const Stream.empty());
  });

  Widget createTestWidget({User? currentUser}) {
    when(
      () => mockAuthRepository.getCurrentUser(),
    ).thenAnswer((_) async => currentUser);

    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepository)],
      child: MaterialApp(
        theme: HoneyTheme.lightTheme,
        initialRoute: AppRoutes.front,
        routes: {
          AppRoutes.front: (_) => const FrontScreen(),
          AppRoutes.auth: (_) => const _MockAuthScreen(),
          AppRoutes.levels: (_) => const _MockLevelSelectScreen(),
        },
      ),
    );
  }

  /// Pump widget and allow initial build (not animations).
  /// FrontScreen has a repeating pulse animation, so pumpAndSettle will never finish.
  Future<void> pumpFrontScreen(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    // Pump enough frames for auth state future to resolve
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('FrontScreen', () {
    group('renders correctly', () {
      testWidgets('displays HexBuzz title', (tester) async {
        await pumpFrontScreen(tester, createTestWidget());

        expect(find.text('HexBuzz'), findsOneWidget);
      });

      testWidgets('displays subtitle', (tester) async {
        await pumpFrontScreen(tester, createTestWidget());

        expect(find.text('One Path Challenge'), findsOneWidget);
      });

      testWidgets('displays "Tap to Start" prompt', (tester) async {
        await pumpFrontScreen(tester, createTestWidget());

        expect(find.text('Tap to Start'), findsOneWidget);
      });

      testWidgets('displays touch icon', (tester) async {
        await pumpFrontScreen(tester, createTestWidget());

        expect(find.byIcon(Icons.touch_app_outlined), findsOneWidget);
      });

      testWidgets('wraps content in GestureDetector', (tester) async {
        await pumpFrontScreen(tester, createTestWidget());

        expect(find.byType(GestureDetector), findsOneWidget);
      });

      testWidgets('wraps content in Scaffold', (tester) async {
        await pumpFrontScreen(tester, createTestWidget());

        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    group('navigation on tap', () {
      testWidgets('navigates to AuthScreen when not logged in', (tester) async {
        await pumpFrontScreen(tester, createTestWidget(currentUser: null));

        // Tap anywhere on the screen
        await tester.tap(find.byType(GestureDetector));
        await tester.pumpAndSettle();

        // Should navigate to auth screen
        expect(find.byType(_MockAuthScreen), findsOneWidget);
        expect(find.byType(FrontScreen), findsNothing);
      });

      testWidgets('tap on title area navigates correctly', (tester) async {
        await pumpFrontScreen(tester, createTestWidget(currentUser: null));

        // Tap on the title text
        await tester.tap(find.text('HexBuzz'));
        await tester.pumpAndSettle();

        // Should navigate to auth screen
        expect(find.byType(_MockAuthScreen), findsOneWidget);
      });

      testWidgets('tap on "Tap to Start" navigates correctly', (tester) async {
        await pumpFrontScreen(tester, createTestWidget(currentUser: null));

        // Tap on the prompt text
        await tester.tap(find.text('Tap to Start'));
        await tester.pumpAndSettle();

        // Should navigate to auth screen
        expect(find.byType(_MockAuthScreen), findsOneWidget);
      });

      // Note: Testing navigation to LevelSelectScreen when logged in requires
      // integration tests due to the async nature of Riverpod's AsyncNotifier.
      // The async state must be fully resolved before the tap handler reads it.
      // This is covered in integration_test/app_test.dart.
    });

    group('animation', () {
      testWidgets('has animated content for tap prompt', (tester) async {
        await pumpFrontScreen(tester, createTestWidget());

        // Verify an Opacity widget exists in the tree (used by animation)
        expect(find.byType(Opacity), findsWidgets);

        // Pump animation forward
        await tester.pump(const Duration(milliseconds: 750));

        // Should still render the tap prompt
        expect(find.text('Tap to Start'), findsOneWidget);
      });

      testWidgets('animation controller disposed on unmount', (tester) async {
        await pumpFrontScreen(tester, createTestWidget(currentUser: null));

        // Navigate away to trigger dispose
        await tester.tap(find.byType(GestureDetector));
        await tester.pumpAndSettle();

        // No exception should be thrown, screen replaced successfully
        expect(find.byType(_MockAuthScreen), findsOneWidget);
        expect(find.byType(FrontScreen), findsNothing);
      });
    });

    group('theming', () {
      testWidgets('uses gradient background', (tester) async {
        await pumpFrontScreen(tester, createTestWidget());

        // Find the container with background decoration
        final containers = tester.widgetList<Container>(find.byType(Container));

        // Look for the container with gradient decoration
        final hasGradient = containers.any((container) {
          if (container.decoration is! BoxDecoration) return false;
          final decoration = container.decoration as BoxDecoration;
          return decoration.gradient is LinearGradient;
        });

        expect(hasGradient, isTrue);
      });

      testWidgets('title has correct styling', (tester) async {
        await pumpFrontScreen(tester, createTestWidget());

        final titleText = tester.widget<Text>(find.text('HexBuzz'));
        expect(titleText.style?.fontWeight, FontWeight.bold);
      });
    });

    group('layout', () {
      testWidgets('content is centered using Center widget', (tester) async {
        await pumpFrontScreen(tester, createTestWidget());

        // There should be at least one Center widget in the tree
        expect(find.byType(Center), findsWidgets);
      });

      testWidgets('uses SafeArea for safe content placement', (tester) async {
        await pumpFrontScreen(tester, createTestWidget());

        expect(find.byType(SafeArea), findsOneWidget);
      });

      testWidgets('uses Column for vertical layout', (tester) async {
        await pumpFrontScreen(tester, createTestWidget());

        expect(find.byType(Column), findsWidgets);
      });
    });

    group('loading state', () {
      testWidgets('handles auth state still loading gracefully', (
        tester,
      ) async {
        // Simulate slow auth state loading
        when(() => mockAuthRepository.getCurrentUser()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return null;
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(mockAuthRepository),
            ],
            child: MaterialApp(
              theme: HoneyTheme.lightTheme,
              initialRoute: AppRoutes.front,
              routes: {
                AppRoutes.front: (_) => const FrontScreen(),
                AppRoutes.auth: (_) => const _MockAuthScreen(),
                AppRoutes.levels: (_) => const _MockLevelSelectScreen(),
              },
            ),
          ),
        );

        // Before auth resolves, screen should still be visible
        await tester.pump();
        expect(find.text('HexBuzz'), findsOneWidget);

        // Tap while loading - should navigate to auth (no user yet)
        await tester.tap(find.byType(GestureDetector));
        await tester.pumpAndSettle();

        // Should navigate to auth screen since user is not loaded yet
        expect(find.byType(_MockAuthScreen), findsOneWidget);
      });
    });
  });
}

/// Mock AuthScreen for navigation testing.
class _MockAuthScreen extends StatelessWidget {
  const _MockAuthScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Mock Auth Screen')));
  }
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
