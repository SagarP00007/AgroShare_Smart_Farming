import 'package:flutter_test/flutter_test.dart';

import 'package:agroshare/app.dart';
import 'package:agroshare/l10n/locale_provider.dart';

void main() {
  testWidgets('AgroShare app smoke test', (WidgetTester tester) async {
    final localeProvider = await LocaleProvider.create();
    await tester.pumpWidget(AgroShareApp(localeProvider: localeProvider));

    // Verify that AgroShare title is displayed.
    expect(find.text('AgroShare'), findsOneWidget);
    expect(find.text('Explore Equipment'), findsOneWidget);
  });
}
