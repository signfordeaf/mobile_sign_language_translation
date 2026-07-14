import 'package:flutter/widgets.dart';
import 'package:mobile_sign_language_translation/src/config/signfordeaf_config.dart';
import 'package:mobile_sign_language_translation/src/service/signfordeaf_events.dart';
import 'package:mobile_sign_language_translation/src/signfordeaf_controller.dart';
import 'package:mobile_sign_language_translation/src/signfordeaf_host.dart';

/// Almost identical to [SignForDeafArea]; it only uses a different logo variant
/// (`logo_head`). Also supports the new optional parameters.
class SignForDeafBody extends StatelessWidget {
  final String? requestKey;
  final String? requestUrl;
  final String? originUrl;
  final Widget? child;

  final SignForDeafConfig? config;
  final SignForDeafController? controller;
  final SignLanguage? language;
  final SignForDeafTheme? theme;
  final FloatingButtonConfig? floatingButton;
  final void Function(SignForDeafEvent event)? onEvent;
  final bool? autoEnable;

  const SignForDeafBody({
    super.key,
    this.requestKey,
    this.requestUrl,
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
      logoAsset: 'logo_head',
      requireCredentials: false,
      child: child,
    );
  }
}
