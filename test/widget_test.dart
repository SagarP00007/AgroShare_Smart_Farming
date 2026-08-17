import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agroshare/app.dart';
import 'package:agroshare/l10n/locale_provider.dart';

void main() {
  testWidgets('AgroShare app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final localeProvider = await LocaleProvider.create();
    await tester.pumpWidget(AgroShareApp(localeProvider: localeProvider));

    // Verify that AgroShare app initializes without crashing.
    expect(find.byType(AgroShareApp), findsOneWidget);
  });
}
