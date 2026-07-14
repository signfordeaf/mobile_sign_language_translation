import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_sign_language_translation/mobile_sign_language_translation.dart';
import 'package:mobile_sign_language_translation/src/model/sign_model.dart';
import 'package:mobile_sign_language_translation/src/service/service.dart';

/// getSignVideo'yu ağ olmadan taklit eden sahte servis.
class _FakeApi extends ApiServices {
  int calls = 0;
  @override
  Future<SignModel> getSignVideo({required String text, int retryCount = 0}) async {
    calls++;
    return SignModel(state: true, baseUrl: 'https://cdn/', name: 'v.mp4');
  }
}

void main() {
  group('SignLanguage kod haritası', () {
    test('etkin diller: tr=1, en=2, ar=6', () {
      expect(SignLanguage.turkish.apiCode, '1');
      expect(SignLanguage.english.apiCode, '2');
      expect(SignLanguage.arabic.apiCode, '6');
      // German/French/Spanish are disabled until the backend supports them.
      expect(SignLanguage.values.length, 3);
    });
  });

  group('SignForDeafManager.configure', () {
    test('tek obje tüm alanları set eder; apiUrl origin olur', () {
      SignForDeafManager().configure(
        const SignForDeafConfig(
          apiKey: 'k',
          apiUrl: 'https://u',
          language: SignLanguage.english,
          fdid: '9',
          tid: '8',
        ),
      );
      expect(SignForDeafManager().requestKey, 'k');
      expect(SignForDeafManager().requestUrl, 'https://u');
      expect(SignForDeafManager().originUrl, 'https://u');
      expect(SignForDeafManager().language, SignLanguage.english);
      expect(SignForDeafManager().fdid, '9');
      expect(SignForDeafManager().tid, '8');
    });

    test('originUrl verilirse apiUrl yerine onu kullanır', () {
      SignForDeafManager().configure(
        const SignForDeafConfig(
          apiKey: 'k',
          apiUrl: 'https://api.example',
          originUrl: 'https://myapp.example',
        ),
      );
      expect(SignForDeafManager().requestUrl, 'https://api.example');
      expect(SignForDeafManager().originUrl, 'https://myapp.example');
    });
  });

  group('SignForDeafController', () {
    test('hassas metin çeviriyi engeller; API çağrılmaz', () async {
      final api = _FakeApi();
      final controller = SignForDeafController(apiServices: api);
      addTearDown(controller.dispose);

      await controller.translate('iletisim: ali@example.com');

      expect(controller.status, SignForDeafStatus.blocked);
      expect(api.calls, 0);
    });

    test('boş metin hiçbir şey yapmaz', () async {
      final api = _FakeApi();
      final controller = SignForDeafController(apiServices: api);
      addTearDown(controller.dispose);

      await controller.translate('   ');

      expect(controller.status, SignForDeafStatus.idle);
      expect(api.calls, 0);
    });

    test('toggleTapToTranslate ipucu bütçesini uygular', () async {
      SignForDeafManager()
          .setFloatingButton(const FloatingButtonConfig(hintMaxShows: 1));
      final storage = InMemorySignForDeafStorage();
      final controller =
          SignForDeafController(apiServices: _FakeApi(), storage: storage);
      addTearDown(controller.dispose);

      await controller.toggleTapToTranslate(); // 1. açılış
      expect(controller.isTapToTranslateActive, isTrue);
      expect(controller.showHint, isTrue);

      await controller.toggleTapToTranslate(); // kapat
      expect(controller.isTapToTranslateActive, isFalse);
      expect(controller.showHint, isFalse);

      await controller.toggleTapToTranslate(); // 2. açılış -> bütçe bitti
      expect(controller.isTapToTranslateActive, isTrue);
      expect(controller.showHint, isFalse);
    });

    test('varsayılan KAPALI; enable/disable çalışır', () {
      final controller = SignForDeafController();
      addTearDown(controller.dispose);
      expect(controller.isEnabled, isFalse);
      controller.enable();
      expect(controller.isEnabled, isTrue);
      controller.disable();
      expect(controller.isEnabled, isFalse);
    });

    test('disable tap modunu da kapatır', () async {
      final controller = SignForDeafController(apiServices: _FakeApi());
      addTearDown(controller.dispose);
      await controller.toggleTapToTranslate();
      expect(controller.isTapToTranslateActive, isTrue);

      controller.disable();
      expect(controller.isEnabled, isFalse);
      expect(controller.isTapToTranslateActive, isFalse);
    });
  });
}
