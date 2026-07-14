import 'package:mobile_sign_language_translation/src/config/signfordeaf_config.dart';

/// Localized strings for a single language.
class SignForDeafStrings {
  final String menuTitle;
  final String businessName;
  final String loading;
  final String error;
  final String close;
  final String videoPlayerLabel;
  final String translationReady;
  final String tapToTranslateHint;
  final String sensitiveBlocked;

  const SignForDeafStrings({
    required this.menuTitle,
    required this.businessName,
    required this.loading,
    required this.error,
    required this.close,
    required this.videoPlayerLabel,
    required this.translationReady,
    required this.tapToTranslateHint,
    required this.sensitiveBlocked,
  });

  /// Returns the strings for a given [SignLanguage].
  static SignForDeafStrings of(SignLanguage language) =>
      _byLanguage[language] ?? _byLanguage[SignLanguage.english]!;

  static const Map<SignLanguage, SignForDeafStrings> _byLanguage = {
    SignLanguage.turkish: SignForDeafStrings(
      menuTitle: 'İşaret Dili',
      businessName: 'Engelsiz Çeviri',
      loading: 'Çeviriliyor...',
      error:
          'Çeviri işlemi şu anda gerçekleştirilemiyor. Lütfen daha sonra tekrar deneyiniz.',
      close: 'Kapat',
      videoPlayerLabel: 'İşaret dili videosu oynatılıyor',
      translationReady: 'İşaret dili çevirisi hazır',
      tapToTranslateHint: 'Çevirmek için bir yazıya dokunun',
      sensitiveBlocked:
          'Bu içerik hassas veri içerdiği için işaret diline çevrilemez.',
    ),
    SignLanguage.english: SignForDeafStrings(
      menuTitle: 'Sign Language',
      businessName: 'SignForDeaf',
      loading: 'Translating...',
      error:
          'Translation is not available at the moment. Please try again later.',
      close: 'Close',
      videoPlayerLabel: 'Sign language video is playing',
      translationReady: 'Sign language translation is ready',
      tapToTranslateHint: 'Tap on any text to translate it',
      sensitiveBlocked:
          'This content contains sensitive data and cannot be translated.',
    ),
    // German/French/Spanish are not yet supported by the backend. Re-enable
    // together with their SignLanguage enum values when available.
    // SignLanguage.german: SignForDeafStrings(
    //   menuTitle: 'Gebärdensprache',
    //   businessName: 'SignForDeaf',
    //   loading: 'Übersetzen...',
    //   error:
    //       'Die Übersetzung ist derzeit nicht verfügbar. Bitte versuchen Sie es später erneut.',
    //   close: 'Schließen',
    //   videoPlayerLabel: 'Gebärdensprachvideo wird abgespielt',
    //   translationReady: 'Gebärdensprachübersetzung ist bereit',
    //   tapToTranslateHint: 'Tap on any text to translate it',
    //   sensitiveBlocked:
    //       'Dieser Inhalt enthält sensible Daten und kann nicht übersetzt werden.',
    // ),
    // SignLanguage.french: SignForDeafStrings(
    //   menuTitle: 'Langue des signes',
    //   businessName: 'SignForDeaf',
    //   loading: 'Traduction en cours...',
    //   error:
    //       'La traduction n\'est pas disponible pour le moment. Veuillez réessayer plus tard.',
    //   close: 'Fermer',
    //   videoPlayerLabel: 'Vidéo en langue des signes en cours de lecture',
    //   translationReady: 'Traduction en langue des signes prête',
    //   tapToTranslateHint: 'Tap on any text to translate it',
    //   sensitiveBlocked:
    //       'Ce contenu contient des données sensibles et ne peut pas être traduit.',
    // ),
    // SignLanguage.spanish: SignForDeafStrings(
    //   menuTitle: 'Lengua de señas',
    //   businessName: 'SignForDeaf',
    //   loading: 'Traduciendo...',
    //   error:
    //       'La traducción no está disponible en este momento. Por favor, inténtelo de nuevo más tarde.',
    //   close: 'Cerrar',
    //   videoPlayerLabel: 'Se está reproduciendo el video en lengua de señas',
    //   translationReady: 'La traducción en lengua de señas está lista',
    //   tapToTranslateHint: 'Tap on any text to translate it',
    //   sensitiveBlocked:
    //       'Este contenido contiene datos sensibles y no se puede traducir.',
    // ),
    SignLanguage.arabic: SignForDeafStrings(
      menuTitle: 'لغة الإشارة',
      businessName: 'SignForDeaf',
      loading: 'جارٍ الترجمة...',
      error:
          'لا يمكن إجراء عملية الترجمة في الوقت الحالي. يرجى المحاولة مرة أخرى في وقت لاحق.',
      close: 'إغلاق',
      videoPlayerLabel: 'يتم تشغيل فيديو لغة الإشارة',
      translationReady: 'ترجمة لغة الإشارة جاهزة',
      tapToTranslateHint: 'انقر على أي نص لترجمته',
      sensitiveBlocked: 'يحتوي هذا المحتوى على بيانات حساسة ولا يمكن ترجمته.',
    ),
  };
}
