import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Drives the showcase into a few representative states and captures a
/// screenshot of each. Run with:
///
/// flutter drive \
///   --driver=test_driver/screenshots_driver.dart \
///   --target=integration_test/screenshots_test.dart \
///   -d `ios-simulator-id`
Future<void> main() async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture README screenshots', (tester) async {
    await tester.pumpWidget(const SignForDeafDemoApp());
    await tester.pumpAndSettle();

    // 1) Home — SDK disabled by default (app behaves natively).
    await binding.takeScreenshot('01-home');

    // 2) Enable the SDK → the floating tap-to-translate button appears.
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('02-enabled');

    // 3) Sensitive-data protection — translating a card number is blocked.
    final cardButton = find.text('Try to translate the card number');
    await tester.scrollUntilVisible(
      cardButton,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(cardButton);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('03-sensitive-blocked');
  });
}
