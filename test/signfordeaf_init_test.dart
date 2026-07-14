import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_sign_language_translation/mobile_sign_language_translation.dart';
import 'package:mobile_sign_language_translation/src/signfordeaf_floating_button.dart';

void main() {
  group('SignForDeafInit', () {
    testWidgets('above MaterialApp: no crash, of() works, autoEnable shows button',
        (tester) async {
      SignForDeafController? captured;
      await tester.pumpWidget(
        SignForDeafInit(
          config: const SignForDeafConfig(apiKey: 'k', apiUrl: 'https://u'),
          autoEnable: true,
          builder: (context, child) => MaterialApp(
            home: Builder(
              builder: (ctx) {
                captured = SignForDeaf.of(ctx);
                return const Scaffold(body: Text('home'));
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(captured, isNotNull);
      expect(captured!.isEnabled, isTrue); // autoEnable
      // The floating button renders (SDK active on the screen).
      expect(find.byType(SignForDeafFloatingButton), findsOneWidget);
    });

    testWidgets('SignForDeaf.of works on a pushed route (router-agnostic)',
        (tester) async {
      SignForDeafController? onSecond;
      await tester.pumpWidget(
        SignForDeafInit(
          config: const SignForDeafConfig(apiKey: 'k', apiUrl: 'https://u'),
          builder: (_, __) => MaterialApp(
            home: Builder(
              builder: (ctx) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).push(
                      MaterialPageRoute(
                        builder: (c) {
                          onSecond = SignForDeaf.of(c);
                          return const Scaffold(body: Text('second'));
                        },
                      ),
                    ),
                    child: const Text('go'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text('second'), findsOneWidget);
      expect(onSecond, isNotNull);
    });
  });
}
