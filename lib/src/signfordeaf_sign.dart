import 'package:flutter/widgets.dart';
import 'package:mobile_sign_language_translation/src/config/signfordeaf_config.dart';
import 'package:mobile_sign_language_translation/src/service/signfordeaf_events.dart';
import 'package:mobile_sign_language_translation/src/signfordeaf_controller.dart';
import 'package:mobile_sign_language_translation/src/signfordeaf_host.dart';

/// State enum kept for backward compatibility. Internal state is now managed
/// via [SignForDeafController]/[SignForDeafStatus].
enum SignForDeafState {
  initial,
  loading,
  ready,
  error,
  cancelled,
  blocked,
  none,
}

/// Main widget that wraps the app (usually inside `MaterialApp.builder`).
///
/// Legacy usage (`requestKey`/`requestUrl`) works unchanged. For the new
/// features, optional [config] (single object), [language],
/// [theme], [floatingButton], [controller] and [onEvent] parameters were added.
/// When enabled, a tap-to-translate floating button is shown; text selection +
/// its menu continue to work.
class SignForDeaf extends StatelessWidget {
  final String requestKey;
  final String requestUrl;
  final String? originUrl;
  final Widget? child;

  /// Single-object configuration. If provided, it is used instead of
  /// [requestKey]/[requestUrl]/[originUrl].
  final SignForDeafConfig? config;

  /// Provide an external controller if you want (to share state). If not
  /// provided, one is created internally.
  final SignForDeafController? controller;

  final SignLanguage? language;
  final SignForDeafTheme? theme;
  final FloatingButtonConfig? floatingButton;

  /// Translation lifecycle events.
  final void Function(SignForDeafEvent event)? onEvent;

  /// Whether the SDK is enabled automatically on start. Defaults to `false` —
  /// the app behaves normally; call `SignForDeaf.of(context).enable()` /
  /// `disable()` from a settings switch, or pass `autoEnable: true` depending
  /// on the profile.
  final bool? autoEnable;

  const SignForDeaf({
    super.key,
    this.requestKey = '',
    this.requestUrl = '',
    this.originUrl,
    required this.child,
    this.config,
    this.controller,
    this.language,
    this.theme,
    this.floatingButton,
    this.onEvent,
    this.autoEnable,
  });

  /// Access to the nearest controller in the tree.
  static SignForDeafController of(BuildContext context) =>
      SignForDeafScope.of(context);

  static SignForDeafController? maybeOf(BuildContext context) =>
      SignForDeafScope.maybeOf(context);

  @override
  Widget build(BuildContext context) {
    return SignForDeafHost(
      requestKey: requestKey,
      requestUrl: requestUrl,
      originUrl: originUrl,
      config: config,
      controller: controller,
      language: language,
      theme: theme,
      floatingButton: floatingButton,
      onEvent: onEvent,
      autoEnable: autoEnable,
      logoAsset: 'logo_kafa',
      requireCredentials: config == null,
      child: child,
    );
  }
}
