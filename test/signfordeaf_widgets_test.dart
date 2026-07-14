import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_sign_language_translation/mobile_sign_language_translation.dart';
import 'package:mobile_sign_language_translation/src/service/marquee_text.dart';
import 'package:mobile_sign_language_translation/src/signfordeaf_floating_button.dart';
import 'package:mobile_sign_language_translation/src/tap_to_translate.dart';

void main() {
  group('TapToTranslateDetector', () {
    testWidgets('dokunulan yazının metnini yakalar', (tester) async {
      String? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TapToTranslateDetector(
              enabled: true,
              onText: (t) => captured = t,
              child: const Text('Merhaba dünya'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Merhaba dünya'));
      await tester.pump();

      expect(captured, 'Merhaba dünya');
    });

    testWidgets('SelectableText (RenderEditable) metnini de yakalar',
        (tester) async {
      String? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TapToTranslateDetector(
              enabled: true,
              onText: (t) => captured = t,
              child: const SelectableText('Seçilebilir yazı'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Seçilebilir yazı'));
      await tester.pump();

      expect(captured, 'Seçilebilir yazı');
    });

    testWidgets('kapalıyken yakalamaz', (tester) async {
      String? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TapToTranslateDetector(
              enabled: false,
              onText: (t) => captured = t,
              child: const Text('Selam'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Selam'));
      await tester.pump();

      expect(captured, isNull);
    });
  });

  testWidgets('overlay chrome metni hata altçizgisi (sarı) miras almaz',
      (tester) async {
    // Regresyon: floating button ipucu Overlay içinde, Scaffold'un Material'ı
    // dışında çizilir. Şeffaf Material sarmalaması olmadan kök hata stili
    // (sarı çift altçizgi) miras alınırdı.
    SignForDeafManager().setFloatingButton(const FloatingButtonConfig(
      hintMaxShows: 1,
      idleBehavior: FloatingButtonIdleBehavior.none,
    ));
    final controller = SignForDeafController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SignForDeaf(
          controller: controller,
          requestKey: 'k',
          requestUrl: 'https://u',
          child: const Scaffold(body: Text('içerik')),
        ),
      ),
    );
    await tester.pump();
    controller.enable(); // floating button yalnızca SDK aktifken görünür
    await tester.pump();
    await controller.toggleTapToTranslate(); // ipucunu göster
    await tester.pump();

    final hintRich = tester.widget<RichText>(
      find.descendant(
        of: find.byType(SignForDeafFloatingButton),
        matching: find.byType(RichText),
      ),
    );
    final style = (hintRich.text as TextSpan).style;
    expect(style?.decoration, isNot(TextDecoration.underline));
  });

  group('MarqueeText', () {
    const style = TextStyle(fontSize: 16);

    testWidgets('sığan metin ortalanır, kaymaz', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 30,
              child: MarqueeText(text: 'kısa', style: style),
            ),
          ),
        ),
      );
      await tester.pump(); // post-frame ölçüm
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.byType(Center), findsWidgets);
    });

    testWidgets('sığmayan metin kayan yazıya geçer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 80,
              height: 30,
              child: MarqueeText(
                text:
                    'çok çok çok uzun bir metin bu kesinlikle kutuya sığmayacak',
                style: style,
              ),
            ),
          ),
        ),
      );
      await tester.pump(); // post-frame ölçüm -> kaydırmaya geç
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('Seçim menüsü (SignForDeafContextMenu)', () {
    Widget wrapSelectable(SignForDeafController controller) => MaterialApp(
          home: SignForDeafScope(
            controller: controller,
            child: Scaffold(
              body: Center(
                child: SelectableText(
                  'Merhaba dünya',
                  contextMenuBuilder: controller.contextMenuBuilder,
                ),
              ),
            ),
          ),
        );

    testWidgets('SDK aktifken menüde "İşaret Dili" çıkar', (tester) async {
      SignForDeafManager().setLanguage(SignLanguage.turkish);
      final controller = SignForDeafController()..enable();
      addTearDown(controller.dispose);

      await tester.pumpWidget(wrapSelectable(controller));
      await tester.longPress(find.text('Merhaba dünya'));
      await tester.pumpAndSettle();

      expect(find.text('İşaret Dili'), findsOneWidget);
    });

    testWidgets('SDK kapalıyken menüde "İşaret Dili" çıkmaz', (tester) async {
      final controller = SignForDeafController(); // varsayılan kapalı
      addTearDown(controller.dispose);

      await tester.pumpWidget(wrapSelectable(controller));
      await tester.longPress(find.text('Merhaba dünya'));
      await tester.pumpAndSettle();

      expect(find.text('İşaret Dili'), findsNothing);
    });
  });

  group('SignForDeafFloatingButton', () {
    Widget wrap(Widget child) =>
        MaterialApp(home: Scaffold(body: Stack(children: [child])));

    testWidgets('dokunuş onPressed tetikler', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(
          SignForDeafFloatingButton(
            active: false,
            onPressed: () => taps++,
            config: const FloatingButtonConfig(
                idleBehavior: FloatingButtonIdleBehavior.none),
            primaryColor: Colors.purple,
            logoAsset: 'images/logo_kafa.png',
            hintText: 'x',
            showHint: false,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(SignForDeafFloatingButton));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('sürükleme onPressed tetiklemez', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(
          SignForDeafFloatingButton(
            active: false,
            onPressed: () => taps++,
            config: const FloatingButtonConfig(
                idleBehavior: FloatingButtonIdleBehavior.none),
            primaryColor: Colors.purple,
            logoAsset: 'images/logo_kafa.png',
            hintText: 'x',
            showHint: false,
          ),
        ),
      );
      await tester.pump();

      await tester.drag(
          find.byType(SignForDeafFloatingButton), const Offset(-120, 0));
      await tester.pumpAndSettle();

      expect(taps, 0);
    });
  });
}
