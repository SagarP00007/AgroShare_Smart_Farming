import 'package:flutter_test/flutter_test.dart';

import 'package:agroshare/app.dart';

void main() {
  testWidgets('AgroShare app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AgroShareApp());

    // Verify that AgroShare title is displayed.
    expect(find.text('AgroShare'), findsOneWidget);
    expect(find.text('Explore Equipment'), findsOneWidget);
  });
}
