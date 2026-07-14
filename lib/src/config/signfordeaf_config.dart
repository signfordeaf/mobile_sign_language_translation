import 'package:flutter/material.dart';

/// Languages available for sign language translation. Each language has a
/// numeric code sent to the API and a corresponding [Locale] for localization
/// (tr=1 … ar=6).
enum SignLanguage {
  turkish('1', 'tr'),
  english('2', 'en'),
  // Not yet supported by the backend — re-enable (and their strings in
  // SignForDeafStrings) once available.
  // german('3', 'de'),
  // french('4', 'fr'),
  // spanish('5', 'es'),
  arabic('6', 'ar');

  const SignLanguage(this.apiCode, this.localeCode);

  /// Code sent as the `language` parameter of the `/Translate` request.
  final String apiCode;

  /// ISO language code (used for locale mapping).
  final String localeCode;

  /// Finds the closest [SignLanguage] for a [Locale]; returns `null` if none match.
  static SignLanguage? fromLocale(Locale locale) {
    for (final lang in SignLanguage.values) {
      if (lang.localeCode == locale.languageCode) return lang;
    }
    return null;
  }
}

/// Theme that adapts the bottom sheet / floating button appearance to your
/// brand (only two fields since v0.1.4).
@immutable
class SignForDeafTheme {
  /// Primary color for the logo, title, close button, loading indicator and
  /// active floating button fill.
  final Color primaryColor;

  /// Color of the text shown in the bottom sheet.
  final Color textColor;

  const SignForDeafTheme({
    this.primaryColor = const Color(0xFF6750A4),
    this.textColor = const Color(0xFF1C1B1F),
  });

  SignForDeafTheme copyWith({Color? primaryColor, Color? textColor}) {
    return SignForDeafTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      textColor: textColor ?? this.textColor,
    );
  }
}

/// Accessibility settings.
@immutable
class SignForDeafAccessibility {
  /// Whether to announce to the screen reader when the panel opens.
  final bool announceOnOpen;

  /// Whether to announce to the screen reader when the panel closes.
  final bool announceOnClose;

  /// Custom accessibility label for the video player (falls back to the
  /// localized default if not provided).
  final String? videoPlayerLabel;

  /// Custom label for the close button.
  final String? closeButtonLabel;

  /// Custom accessibility hint for the panel.
  final String? bottomSheetHint;

  const SignForDeafAccessibility({
    this.announceOnOpen = true,
    this.announceOnClose = false,
    this.videoPlayerLabel,
    this.closeButtonLabel,
    this.bottomSheetHint,
  });
}

/// What the floating button does while idle.
enum FloatingButtonIdleBehavior {
  /// Partially slides off the nearest edge and fades slightly.
  peek,

  /// Only fades, staying fully on screen.
  fade,

  /// Stays fully visible.
  none,
}

/// Settings for the tap-to-translate floating button.
@immutable
class FloatingButtonConfig {
  /// Whether the button is shown while the SDK is enabled.
  final bool enabled;

  /// Behavior after `idleDelay` ms of inactivity.
  final FloatingButtonIdleBehavior idleBehavior;

  /// Inactivity duration before the idle behavior kicks in (ms).
  final int idleDelayMs;

  /// How many times the tap-to-translate hint bubble is shown before being
  /// hidden permanently.
  final int hintMaxShows;

  /// Button diameter (pt).
  final double size;

  /// Fill color while the mode is OFF (defaults to white).
  final Color? backgroundColor;

  /// Fill color while the mode is ON (defaults to the theme primaryColor).
  final Color? activeBackgroundColor;

  /// Logo tint while the mode is OFF (defaults to the theme primaryColor).
  final Color? iconColor;

  /// Logo tint while the mode is ON (defaults to white).
  final Color? activeIconColor;

  /// Border color (drawn only while the mode is off; defaults to primaryColor).
  final Color? borderColor;

  const FloatingButtonConfig({
    this.enabled = true,
    this.idleBehavior = FloatingButtonIdleBehavior.peek,
    this.idleDelayMs = 2500,
    this.hintMaxShows = 2,
    this.size = 44,
    this.backgroundColor,
    this.activeBackgroundColor,
    this.iconColor,
    this.activeIconColor,
    this.borderColor,
  });
}

/// SDK configuration. Gathers API credentials, language, theme and floating
/// button settings into a single object.
///
/// Note: [apiUrl] is the base URL of the API. The origin sent to the backend
/// (the `Origin` header and the `url` query parameter, used to identify the
/// calling app/site) defaults to [apiUrl]; override it with [originUrl] when
/// your integration requires a distinct origin.
@immutable
class SignForDeafConfig {
  /// SignForDeaf API key (`rk` parameter).
  final String apiKey;

  /// Base URL of the translation API (e.g. `https://kor01rp02.signfordeaf.com`).
  final String apiUrl;

  /// Origin identifying the calling app/site — sent as the `Origin` header and
  /// the `url` query parameter on every request. Defaults to [apiUrl] when null.
  final String? originUrl;

  /// Translation language (defaults to Turkish).
  final SignLanguage language;

  /// Dictionary/domain identifier (`fdid`, defaults to '16').
  final String fdid;

  /// Translator identifier (`tid`, defaults to '23').
  final String tid;

  /// Theme customization.
  final SignForDeafTheme theme;

  /// Floating tap-to-translate button settings.
  final FloatingButtonConfig floatingButton;

  /// Accessibility settings.
  final SignForDeafAccessibility accessibility;

  /// Whether the SDK is enabled automatically on start. Defaults to `false` —
  /// the app behaves normally; the client calls [enable]/[disable] from a
  /// settings switch, or passes `autoEnable: true` depending on the profile.
  final bool autoEnable;

  const SignForDeafConfig({
    required this.apiKey,
    required this.apiUrl,
    this.originUrl,
    this.language = SignLanguage.turkish,
    this.fdid = '16',
    this.tid = '23',
    this.theme = const SignForDeafTheme(),
    this.floatingButton = const FloatingButtonConfig(),
    this.accessibility = const SignForDeafAccessibility(),
    this.autoEnable = false,
  });
}
