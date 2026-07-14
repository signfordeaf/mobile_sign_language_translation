import 'package:mobile_sign_language_translation/src/signfordeaf_manager.dart';

/// UI-independent, pure Dart helper that decides whether the selected text
/// contains sensitive data before it is sent to the server.
///
/// It is the "automatic detection" layer of a two-layer defense:
///   1. Searches for Turkey-specific + general PII (personal data) patterns
///      via regular expressions.
///   2. Checks for overlap with texts manually marked by [SignForDeafSensitive]
///      widgets in [SignForDeafManager].
///
/// If either matches, the text is treated as sensitive and no translation
/// request is ever sent.
class SensitiveDataGuard {
  const SensitiveDataGuard._();

  /// Email address.
  static final RegExp _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+');

  /// Turkish IBAN (TR + 24 digits, may contain spaces).
  static final RegExp _ibanTr =
      RegExp(r'\bTR\d{2}(?:[ ]?\d{4}){5}[ ]?\d{2}\b', caseSensitive: false);

  /// Turkish mobile number: optional +90 / 0, followed by 5xx xxx xx xx.
  static final RegExp _gsm =
      RegExp(r'(?:\+90|0)?[ ]?5\d{2}[ ]?\d{3}[ ]?\d{2}[ ]?\d{2}');

  /// 11-digit candidate sequence (Turkish national ID candidate). Validated
  /// via checksum in [_isValidTckn].
  static final RegExp _elevenDigits = RegExp(r'\b\d{11}\b');

  /// 13-19 digit candidate sequence, possibly containing spaces/dashes (credit
  /// card candidate). Validated in [_passesLuhn].
  static final RegExp _cardCandidate = RegExp(r'\b(?:\d[ -]?){12,18}\d\b');

  /// Returns `true` if [text] contains sensitive data.
  static bool isSensitive(String? text) {
    if (text == null) return false;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    // 1) Overlap with manually marked (registered) texts.
    if (SignForDeafManager().isRegisteredSensitive(trimmed)) return true;

    // 2) Direct pattern matches.
    if (_email.hasMatch(trimmed)) return true;
    if (_ibanTr.hasMatch(trimmed)) return true;
    if (_gsm.hasMatch(trimmed)) return true;

    // 3) Patterns that require checksum validation.
    for (final match in _elevenDigits.allMatches(trimmed)) {
      if (_isValidTckn(match.group(0)!)) return true;
    }
    for (final match in _cardCandidate.allMatches(trimmed)) {
      final digits = match.group(0)!.replaceAll(RegExp(r'[ -]'), '');
      if (digits.length >= 13 && digits.length <= 19 && _passesLuhn(digits)) {
        return true;
      }
    }

    return false;
  }

  /// Turkish national ID (T.C. Kimlik No) checksum validation.
  ///
  /// Rules: 11 digits, first digit cannot be 0; the 10th digit is
  /// `((sum of odd-indexed) * 7 - (sum of even-indexed)) % 10`;
  /// the 11th digit is the sum of the first 10 digits mod 10.
  static bool _isValidTckn(String value) {
    if (value.length != 11) return false;
    final d = value.split('').map(int.parse).toList();
    if (d[0] == 0) return false;

    final oddSum = d[0] + d[2] + d[4] + d[6] + d[8];
    final evenSum = d[1] + d[3] + d[5] + d[7];
    final tenth = ((oddSum * 7) - evenSum) % 10;
    if (tenth != d[9]) return false;

    final firstTenSum = d.take(10).fold<int>(0, (a, b) => a + b);
    return firstTenSum % 10 == d[10];
  }

  /// Credit card number validation using the Luhn algorithm.
  static bool _passesLuhn(String digits) {
    var sum = 0;
    var alternate = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var n = digits.codeUnitAt(i) - 48; // '0' == 48
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }
}
