import 'package:flutter/material.dart';
import 'package:mobile_sign_language_translation/src/config/signfordeaf_config.dart';
import 'package:mobile_sign_language_translation/src/service/signfordeaf_events.dart';
import 'package:mobile_sign_language_translation/src/signfordeaf_controller.dart';
import 'package:mobile_sign_language_translation/src/signfordeaf_sign.dart';

/// Root initializer that wraps your app once — the same ergonomics as
/// `ScreenUtilInit`. Place it at the very top and return your app from
/// [builder]; the SDK (floating button, tap-to-translate, selection menu, and
/// `SignForDeaf.of(context)`) is then active on every screen.
///
/// Because it sits **above** the app, it is router-agnostic: it works
/// identically with `MaterialApp`, `MaterialApp.router`, go_router, auto_route
/// and nested navigators — it never touches the router's builder, observers or
/// route structure.
///
/// ```dart
/// void main() => runApp(
///   SignForDeafInit(
///     config: SignForDeafConfig(apiKey: '...', apiUrl: '...'),
///     autoEnable: true,
///     builder: (context, child) => MaterialApp.router(
///       routerConfig: appRouter,
///     ),
///   ),
/// );
/// ```
///
/// Can be freely nested with `ScreenUtilInit` (either order).
class SignForDeafInit extends StatelessWidget {
  /// Builds your app. Return a `MaterialApp` / `MaterialApp.router` (or any
  /// root widget). The optional [child] is passed through as the second
  /// argument, mirroring `ScreenUtilInit`.
  final Widget Function(BuildContext context, Widget? child) builder;

  /// Optional stable child forwarded to [builder] (e.g. a home page).
  final Widget? child;

  /// SDK configuration (API key/URL, language, theme, floating button…).
  final SignForDeafConfig? config;

  /// Optional external controller to share state; created internally otherwise.
  final SignForDeafController? controller;

  /// Whether the SDK is enabled automatically on start (defaults to false).
  final bool? autoEnable;

  /// Translation lifecycle events.
  final void Function(SignForDeafEvent event)? onEvent;

  const SignForDeafInit({
    super.key,
    required this.builder,
    this.child,
    this.config,
    this.controller,
    this.autoEnable,
    this.onEvent,
  });

  @override
  Widget build(BuildContext context) {
    Widget tree = SignForDeaf(
      config: config,
      controller: controller,
      autoEnable: autoEnable,
      onEvent: onEvent,
      child: Builder(builder: (ctx) => builder(ctx, child)),
    );

    // The SDK renders real UI (floating button/panel) above the app, so it
    // needs a Directionality and a MediaQuery — which do not exist above
    // MaterialApp. Provide sensible fallbacks only when they are missing.
    if (Directionality.maybeOf(context) == null) {
      final rtl = config?.language == SignLanguage.arabic;
      tree = Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: tree,
      );
    }
    if (MediaQuery.maybeOf(context) == null) {
      tree = MediaQuery(
        data: MediaQueryData.fromView(View.of(context)),
        child: tree,
      );
    }
    return tree;
  }
}
