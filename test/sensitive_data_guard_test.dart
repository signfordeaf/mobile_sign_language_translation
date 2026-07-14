import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_sign_language_translation/src/service/sensitive_data_guard.dart';
import 'package:mobile_sign_language_translation/src/signfordeaf_manager.dart';

void main() {
  group('SensitiveDataGuard.isSensitive', () {
    test('geçerli T.C. Kimlik No engellenir', () {
      // Checksum'ı geçerli örnek TCKN'ler.
      expect(SensitiveDataGuard.isSensitive('10000000146'), isTrue);
      expect(SensitiveDataGuard.isSensitive('TCKN: 10000000146'), isTrue);
    });

    test('geçersiz 11 haneli sayı engellenmez (yanlış-pozitif kontrolü)', () {
      // Checksum tutmayan rastgele 11 hane.
      expect(SensitiveDataGuard.isSensitive('12345678901'), isFalse);
      expect(SensitiveDataGuard.isSensitive('Bu butona 12345678901 kez bastınız'), isFalse);
    });

    test('Luhn geçerli kredi kartı engellenir', () {
      expect(SensitiveDataGuard.isSensitive('4242 4242 4242 4242'), isTrue);
      expect(SensitiveDataGuard.isSensitive('Kart: 4111-1111-1111-1111'), isTrue);
    });

    test('Luhn geçersiz kart numarası engellenmez', () {
      expect(SensitiveDataGuard.isSensitive('1234 5678 9012 3456'), isFalse);
    });

    test('IBAN (TR) engellenir', () {
      expect(SensitiveDataGuard.isSensitive('TR33 0006 1005 1978 6457 8413 26'), isTrue);
    });

    test('e-posta engellenir', () {
      expect(SensitiveDataGuard.isSensitive('iletisim: ali@example.com'), isTrue);
    });

    test('GSM telefon engellenir', () {
      expect(SensitiveDataGuard.isSensitive('0532 123 45 67'), isTrue);
      expect(SensitiveDataGuard.isSensitive('+90 532 123 45 67'), isTrue);
    });

    test('düz metin engellenmez', () {
      expect(SensitiveDataGuard.isSensitive('Merhaba dünya'), isFalse);
      expect(SensitiveDataGuard.isSensitive('You have pushed the button this many times'), isFalse);
    });

    test('boş / null metin engellenmez', () {
      expect(SensitiveDataGuard.isSensitive(''), isFalse);
      expect(SensitiveDataGuard.isSensitive('   '), isFalse);
      expect(SensitiveDataGuard.isSensitive(null), isFalse);
    });

    test('registry ile işaretlenmiş metin engellenir', () {
      final manager = SignForDeafManager();
      manager.registerSensitive('Gizli Not');
      addTearDown(() => manager.unregisterSensitive('Gizli Not'));

      // Tam eşleşme, alt küme ve üst küme örtüşmeleri.
      expect(SensitiveDataGuard.isSensitive('Gizli Not'), isTrue);
      expect(SensitiveDataGuard.isSensitive('Gizli'), isTrue);
      expect(SensitiveDataGuard.isSensitive('Çok Gizli Not içeriği'), isTrue);

      manager.unregisterSensitive('Gizli Not');
      expect(SensitiveDataGuard.isSensitive('Gizli Not'), isFalse);
    });
  });
}
