import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:honeycomb_one_pass/main.dart';

void main() {
  testWidgets('App launches with game screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HoneycombApp()));

    // Verify app title is displayed
    expect(find.text('Honeycomb One Pass'), findsOneWidget);

    // Verify reset button is present in the app bar
    expect(find.byTooltip('Reset (same level)'), findsOneWidget);
  });
}
