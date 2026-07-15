## 1.1.1

- **Localizations crash fix.** The SDK mounts its own `Overlay` above the host `MaterialApp`; a `TextField`'s `SystemContextMenu` selection toolbar attaching to that overlay could throw `No WidgetsLocalizations found`. The overlay is now wrapped in a `Localizations` with the framework's default widgets/material/cupertino delegates.
- **Dark-mode aware floating button.** The floating button now derives contrast-safe defaults from the ambient `platformBrightness`, so its open (solid) and closed (outlined) states stay distinguishable — and its logo tint stays visible — in both light and dark themes. Explicit `FloatingButtonConfig` colors still override.
- **Themed logo everywhere.** The panel header, loading and error/message views now tint the logo with `primaryColor` (previously only the floating button was themed).
- **Onboarding hint no longer overflows.** When the button is docked to the right edge, the "tap to translate" hint bubble now anchors to the right edge and grows leftward instead of pushing the button off-screen.
- **Floating button shape fix.** The button only becomes a full circle while it is actually being dragged; a plain tap keeps its docked half-pill shape (no more circle flash).
- **Tap in translate mode no longer leaks to the app.** While tap-to-translate is active, a tap on interactive content (link/button) is captured for translation only and no longer also triggers the app's own handler (e.g. accidental navigation). Scrolling still works.

## 1.1.0

- Major feature update — a full configuration and interaction layer:
  - **`SignForDeafInit`** — a single, top-level root initializer (same ergonomics as `ScreenUtilInit`): wrap once with `builder: (context, child) => MaterialApp(...)` and the SDK is active on every screen. It sits above `MaterialApp`, so it is **router-agnostic** — works identically with `MaterialApp`, `MaterialApp.router`, go_router, auto_route and nested navigators, and can be nested with `ScreenUtilInit`. The classic `MaterialApp.builder` + `SignForDeaf` pattern remains supported.
  - **Floating button + tap-to-translate**: a draggable, edge-sticky logo button toggles a "tap-to-translate" mode; while active, a single tap on any text translates it instantly. The button peeks off-screen when idle and shows a localized, persisted onboarding hint (`SignForDeafFloatingButton`, `FloatingButtonConfig`).
  - **Tap capture in pure Dart**: tapping is resolved by hit-testing the render tree for the `RenderParagraph` under the finger (`TapToTranslateDetector`), with an opt-in `SignForDeafText` wrapper as a reliable fallback. (Flutter draws to a single surface, so there are no per-widget native text views.)
  - **Config object + controller**: new `SignForDeafConfig` (apiKey, apiUrl, language, fdid, tid, theme, floatingButton) and `SignForDeafController` (a `ChangeNotifier` exposing `state`, `enable/disable/toggleTapToTranslate/translate/dismissPanel/cancelTranslation`), shared via `SignForDeafScope` / `SignForDeaf.of(context)`.
  - **Theming** (`SignForDeafTheme`: primaryColor/textColor — applied to the panel header/close/text, floating button, and loading spinner), **localization** (tr/en/ar; de/fr/es coming soon), **programmatic `translate(text)`**, and a **lifecycle event stream** (`SignForDeafEvent`).
  - **Accessibility personalization** (`SignForDeafAccessibility`): `announceOnOpen` / `announceOnClose` (screen-reader announcements on panel open/close), plus `videoPlayerLabel`, `closeButtonLabel`, `bottomSheetHint` semantics on the panel.
  - **Optional persistence** via `SignForDeafStorage` (in-memory or `shared_preferences`).
  - Language is now mapped to the API code (tr=1 … ar=6) instead of hard-coded `1`.
  - Translation retry is now bounded (30 attempts, 1s apart) with 30s network timeouts, instead of unbounded recursion.
- **Behavior change — no more always-on text selection.** The package no longer wraps your app in a `SelectionArea` that forces every `Text` to be selectable (it disrupted normal scrolling/UX). The app now behaves 100% natively when the SDK is off.
  - **On/off gating.** The SDK is **disabled by default**. Turn it on via `SignForDeaf.of(context).enable()` / `.disable()` (wire it to a settings switch) or `SignForDeafConfig(autoEnable: true)` / the `autoEnable` prop (e.g. based on user profile). While off: no floating button, no tap-to-translate, no menu item.
  - **Sign-language menu is now opt-in per selectable widget.** For text your app already makes selectable (`TextField`, `SelectableText`), add `contextMenuBuilder: SignForDeaf.of(context).contextMenuBuilder` — the "İşaret Dili" item then appears in that native selection menu, but only while the SDK is enabled. (Flutter has no global selection-menu hook, so this is per-widget.)
- **Sensitive-data protection** — personal data is never sent to the translation server.
  - New `SignForDeafSensitive` widget: wrap any text-bearing subtree; its text stays visible, but requesting a sign-language translation for it is blocked — no request is sent.
  - Automatic PII safety net: even without marking, selected text that matches a T.C. Kimlik No (checksum-validated), credit card (Luhn-validated), Turkish IBAN, e-mail, or GSM phone number is blocked before any request leaves the device.
  - When blocked, a short warning is shown instead of calling `/Translate`; the selected text never reaches the server or its access logs.
  - Registry API on `SignForDeafManager` (`registerSensitive` / `unregisterSensitive` / `isRegisteredSensitive`).
- Preserved: the `SignForDeaf` / `SignForDeafArea` / `SignForDeafBody` constructors (new params are optional).
- Fixed the same `LateInitializationError` on `dispose` for `SignForDeafArea` / `SignForDeafBody` that 1.0.5 fixed for `SignForDeaf` (the widgets now delegate to a shared host).

## 1.0.5

- Fixed `LateInitializationError` thrown from `SignForDeaf.dispose` when the widget was disposed before a translation was ever requested (the `_videoController` late field was never assigned). Disposal now guards on an initialization flag.

## 1.0.3

- Added iOS and macOS Podfile configuration for CocoaPods dependency management
- Updated xcconfig files to include Pods configuration for iOS and macOS
- Added `originUrl` parameter support in `SignForDeafArea`, `SignForDeafBody`, and `SignForDeafManager`
- Added `Origin` header to API requests in `ApiServices`
- Updated dependencies: dio, video_player, flutter_animate, flick_video_player, fading_edge_scrollview
- Improved UI components for better readability and consistency

## 1.0.2

- HTTPS clear text protocol bug fix

## 1.0.1

- image asset bug fix

## 1.0.0

- SignForDeaf Sign Language Translate initial release.
