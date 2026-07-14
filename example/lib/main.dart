import 'package:flutter/material.dart';
import 'package:mobile_sign_language_translation/mobile_sign_language_translation.dart';

import 'showcase_page.dart';

/// 👉 Replace these with your SignForDeaf credentials to enable real
/// sign-language video translations.
///
/// Every other flow in this demo (enable/disable, tap-to-translate, the
/// selection menu, sensitive-data blocking, theming, language, event log) works
/// without them — only the actual video translation needs a valid key/URL.
const String kApiKey = 'YOUR_API_KEY';
const String kApiUrl = 'YOUR_API_URL';

void main() => runApp(const SignForDeafDemoApp());

class SignForDeafDemoApp extends StatefulWidget {
  const SignForDeafDemoApp({super.key});

  @override
  State<SignForDeafDemoApp> createState() => _SignForDeafDemoAppState();
}

class _SignForDeafDemoAppState extends State<SignForDeafDemoApp> {
  // A single controller shared across the app (like RN's useSignLanguageContext).
  final SignForDeafController _controller = SignForDeafController(
    storage: SharedPreferencesSignForDeafStorage(),
  );

  // Live-editable personalization, driven by the "Personalization" section.
  SignLanguage _language = SignLanguage.turkish;
  Color _primaryColor = const Color(0xFF6750A4);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ScreenUtilInit-style root initialization: wrap once at the very top and
    // the SDK is active on every screen, for any router. Re-keyed so a
    // language/color change re-applies the config (the controller is external,
    // so its state is preserved).
    return SignForDeafInit(
      key: ValueKey(Object.hash(_language, _primaryColor)),
      controller: _controller,
      config: SignForDeafConfig(
        apiKey: kApiKey,
        apiUrl: kApiUrl,
        language: _language,
        theme: SignForDeafTheme(primaryColor: _primaryColor),
        floatingButton: const FloatingButtonConfig(hintMaxShows: 2),
        accessibility: const SignForDeafAccessibility(announceOnOpen: true),
      ),
      onEvent: (e) => debugPrint('SignForDeaf event: ${e.type}'),
      builder: (context, child) => MaterialApp(
        title: 'SignForDeaf Example',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: _primaryColor),
          useMaterial3: true,
        ),
        home: ShowcasePage(
          controller: _controller,
          apiConfigured: kApiKey != 'YOUR_API_KEY',
          language: _language,
          onLanguageChanged: (l) => setState(() => _language = l),
          primaryColor: _primaryColor,
          onPrimaryColorChanged: (c) => setState(() => _primaryColor = c),
        ),
      ),
    );
  }
}
