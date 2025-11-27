import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:honeycomb_one_pass/main.dart';

void main() {
  testWidgets('App launches with placeholder screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HoneycombApp()));

    expect(find.text('Honeycomb One Pass'), findsOneWidget);
    expect(find.text('Project initialized.\nGame screen will be implemented in later tasks.'), findsOneWidget);
  });
}
