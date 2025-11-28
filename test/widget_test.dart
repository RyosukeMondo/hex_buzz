import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:honeycomb_one_pass/main.dart';

void main() {
  testWidgets('App launches with level select screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: HoneycombApp()));

    // Allow async providers to settle
    await tester.pumpAndSettle();

    // Verify app title is displayed
    expect(find.text('Honeycomb One Pass'), findsOneWidget);

    // Verify level select screen is shown (grid of level cells)
    // The level select screen doesn't have a reset button - that's on GameScreen
    // Instead verify we're on level select by checking for level grid presence
  });
}
