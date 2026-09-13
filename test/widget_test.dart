import 'package:flutter_test/flutter_test.dart';

import 'package:sports_shop/main.dart';

void main() {
  testWidgets('App boots and shows the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('SPORTTECH'), findsOneWidget);
    expect(find.text('SHOP. TRAIN. PERFORM.'), findsOneWidget);

    // Let the splash screen's auto-navigation timer resolve so no timer is
    // left pending when the test ends.
    await tester.pumpAndSettle(const Duration(milliseconds: 2500));
  });
}
