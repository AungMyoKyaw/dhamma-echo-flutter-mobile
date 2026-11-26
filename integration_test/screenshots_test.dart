import 'dart:io';

import 'package:dhamma_echo/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture App Store screenshots on iOS Simulator', (tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
    }

    await binding.takeScreenshot('ios-home');

    // Browse -> Audio
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await binding.takeScreenshot('ios-browse');

    // Browse -> eBooks Shelf
    await tester.tap(find.text('eBooks'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await binding.takeScreenshot('ios-ebooks');

    // Browse -> Teachers & Sources
    await tester.tap(find.text('Teachers'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await binding.takeScreenshot('ios-teachers');

    // Search -> Myanmar query
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ပဋ္ဌာန်း');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await binding.takeScreenshot('ios-search');

    // Library
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await binding.takeScreenshot('ios-library');

    // Settings
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Settings',
      ),
    );
    await tester.pumpAndSettle();
    await binding.takeScreenshot('ios-settings');
  });
}
