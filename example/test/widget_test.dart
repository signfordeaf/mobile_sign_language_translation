// Basic smoke test for the SignForDeaf showcase example.

import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('Showcase builds and shows sections', (WidgetTester tester) async {
    await tester.pumpWidget(const SignForDeafDemoApp());
    await tester.pump();

    // Header + first section are rendered.
    expect(find.text('Sign Language Translation'), findsOneWidget);
    expect(find.text('Sign Language mode'), findsOneWidget);

    // The mode is disabled by default.
    expect(find.text('Disabled'), findsOneWidget);
  });
}
