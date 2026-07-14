import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:mobile_sign_language_translation/src/config/signfordeaf_config.dart';
import 'package:mobile_sign_language_translation/src/l10n/strings.dart';
import 'package:mobile_sign_language_translation/src/service/signfordeaf_events.dart';
import 'package:mobile_sign_language_translation/src/signfordeaf_controller.dart';
import 'package:mobile_sign_language_translation/src/signfordeaf_floating_button.dart';
import 'package:mobile_sign_language_translation/src/signfordeaf_manager.dart';
import 'package:mobile_sign_language_translation/src/storage/signfordeaf_storage.dart';
import 'package:mobile_sign_language_translation/src/tap_to_translate.dart';
import 'package:mobile_sign_language_translation/src/views/sign_panel.dart';

/// Shared internal engine of `SignForDeaf`, `SignForDeafArea` and
/// `SignForDeafBody`.
///
/// All the shared behavior is gathered here: state via
/// [SignForDeafController]; the selection menu + tap-to-translate + programmatic
/// translation all flow through `controller.translate`; the floating button,
/// panel, and loading/error/blocked views are rendered based on the controller
/// state. Theme and localization are applied. The existing public widgets
/// delegate to this.
class SignForDeafHost extends StatefulWidget {
  final String? requestKey;
  final String? requestUrl;
  final String? originUrl;
  final SignForDeafConfig? config;
  final SignForDeafController? controller;
  final SignLanguage? language;
  final SignForDeafTheme? theme;
  final FloatingButtonConfig? floatingButton;
  final void Function(SignForDeafEvent event)? onEvent;

  /// Whether the SDK is enabled automatically on start (defaults to false).
  final bool? autoEnable;
  final Widget? child;

  /// Logo used in the panel/loading views ('logo_kafa'/'logo_head').
  final String logoAsset;

  /// `requestKey`/`requestUrl` are required for `SignForDeaf`, but not for Area/Body.
  final bool requireCredentials;

  const SignForDeafHost({
    super.key,
    this.requestKey,
    this.requestUrl,
    this.originUrl,
    this.config,
    this.controller,
    this.language,
    this.theme,
    this.floatingButton,
    this.onEvent,
    this.autoEnable,
    required this.child,
    required this.logoAsset,
    required this.requireCredentials,
  });

  @override
  State<SignForDeafHost> createState() => _SignForDeafHostState();
}

class _SignForDeafHostState extends State<SignForDeafHost>
    with SingleTickerProviderStateMixin {
  final SignForDeafManager _manager = SignForDeafManager();
  late final SignForDeafController _controller;
  late final bool _ownsController;
  late final AnimationController _slide;
  late final Animation<Offset> _offset;
  StreamSubscription<SignForDeafEvent>? _eventsSub;

  Locale _currentLocale = const Locale('tr');

  @override
  void initState() {
    super.initState();
    _applyConfig();

    _controller = widget.controller ??
        SignForDeafController(storage: SharedPreferencesSignForDeafStorage());
    _ownsController = widget.controller == null;

    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _offset = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slide, curve: Curves.easeInOut));

    _controller.addListener(_onControllerChanged);
    if (widget.onEvent != null) {
      _eventsSub = _controller.events.listen(widget.onEvent);
    }

    // autoEnable: from the config or the direct parameter; if neither is
    // provided it defaults to off (the app behaves normally).
    final autoEnable = widget.autoEnable ?? widget.config?.autoEnable ?? false;
    if (autoEnable) _controller.enable();
  }

  void _applyConfig() {
    final config = widget.config;
    if (config != null) {
      _manager.configure(config);
      return;
    }
    if (widget.requestKey != null) _manager.setRequestKey(widget.requestKey!);
    if (widget.requestUrl != null) _manager.setRequestUrl(widget.requestUrl!);
    _manager.setOriginUrl(widget.originUrl ?? widget.requestUrl ?? '');
    if (widget.language != null) _manager.setLanguage(widget.language!);
    if (widget.theme != null) _manager.setTheme(widget.theme!);
    if (widget.floatingButton != null) {
      _manager.setFloatingButton(widget.floatingButton!);
    }
  }

  bool _wasPanelVisible = false;

  void _onControllerChanged() {
    if (!mounted) return;
    final visible = _controller.isPanelVisible;
    final a11y = _manager.accessibility;

    if (visible && !_wasPanelVisible) {
      _slide.forward();
      _announce(a11y.announceOnOpen, _strings.translationReady);
    } else if (!visible && _wasPanelVisible) {
      _announce(a11y.announceOnClose, _strings.close);
      if (_slide.value != 0) _slide.reset();
    } else if (!visible && _slide.value != 0) {
      _slide.reset();
    }
    _wasPanelVisible = visible;
  }

  /// Screen-reader announcement. Kept lazy so it performs no inherited lookups
  /// unless the panel actually opens/closes (never during initState).
  void _announce(bool enabled, String message) {
    if (!enabled || !mounted) return;
    final view = View.maybeOf(context);
    if (view == null) return;
    final dir = _manager.language == SignLanguage.arabic
        ? TextDirection.rtl
        : TextDirection.ltr;
    SemanticsService.sendAnnouncement(view, message, dir);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // maybeLocaleOf: SignForDeafInit places the SDK above MaterialApp, where no
    // Localizations ancestor exists. The config language takes priority anyway.
    _currentLocale = Localizations.maybeLocaleOf(context) ?? const Locale('tr');
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _controller.removeListener(_onControllerChanged);
    _slide.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  SignForDeafStrings get _strings {
    // Priority: config language; otherwise the active locale; otherwise Turkish.
    final lang = widget.config != null || widget.language != null
        ? _manager.language
        : (SignLanguage.fromLocale(_currentLocale) ?? _manager.language);
    return SignForDeafStrings.of(lang);
  }

  Color get _primary => _manager.theme.primaryColor;

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    if (widget.requireCredentials &&
        ((_manager.requestKey?.isEmpty ?? true) ||
            (_manager.requestUrl?.isEmpty ?? true) ||
            child == null)) {
      if (kDebugMode) {
        throw Exception('Please enter the request key or request url');
      }
      if (kReleaseMode) return child ?? const SizedBox.shrink();
    }
    if (child == null) return const SizedBox.shrink();
    if (!_manager.isSignForDeafOpen) return child;

    return SignForDeafScope(
      controller: _controller,
      child: Overlay(
        initialEntries: [
          OverlayEntry(canSizeOverlay: true, builder: (_) => _contentLayer(child)),
          OverlayEntry(builder: (_) => _floatingButtonLayer()),
          OverlayEntry(builder: (_) => _statusLayer(context)),
        ],
      ),
    );
  }

  /// Content layer. We no longer force any text to be selectable (no
  /// `SelectionArea`) — the app behaves fully natively. Only when the SDK is
  /// enabled AND tap-to-translate mode is on does a translucent detector
  /// capture the tapped text; otherwise the child is rendered as-is.
  Widget _contentLayer(Widget child) {
    return ListenableBuilder(
      listenable: _controller,
      child: child,
      builder: (_, stableChild) => TapToTranslateDetector(
        enabled: _controller.isEnabled && _controller.isTapToTranslateActive,
        onText: _controller.translate,
        child: stableChild!,
      ),
    );
  }

  Widget _floatingButtonLayer() {
    // Transparent Material: provides a proper DefaultTextStyle for text inside
    // the overlay; otherwise the root error style (yellow double underline) is
    // inherited.
    return Material(
      type: MaterialType.transparency,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (_, __) {
            final fb = _manager.floatingButton;
          if (!_controller.isEnabled || !fb.enabled) {
            return const SizedBox.shrink();
          }
          return Stack(
            children: [
              SignForDeafFloatingButton(
                active: _controller.isTapToTranslateActive,
                onPressed: _controller.toggleTapToTranslate,
                config: fb,
                primaryColor: _primary,
                logoAsset: 'images/${widget.logoAsset}.png',
                hintText: _strings.tapToTranslateHint,
                showHint: _controller.showHint,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusLayer(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (_, __) {
          switch (_controller.status) {
            case SignForDeafStatus.loading:
              return _loadingView(context);
            case SignForDeafStatus.ready:
              return _panelView(context);
            case SignForDeafStatus.error:
              return _messageView(context, _strings.error);
            case SignForDeafStatus.blocked:
              return _messageView(context, _strings.sensitiveBlocked);
            case SignForDeafStatus.idle:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _scrim(BuildContext context, {required List<Widget> children, VoidCallback? onClose}) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        Container(color: const Color(0x80000000)),
        ...children,
        if (onClose != null)
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                margin: const EdgeInsets.only(top: 60, right: 30),
                child: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ),
      ],
    );
  }

  Widget _loadingView(BuildContext context) {
    return _scrim(
      context,
      onClose: () => _controller.cancelTranslation(),
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Image.asset('images/${widget.logoAsset}.png',
                scale: 3, package: 'mobile_sign_language_translation'),
            SizedBox(
              width: MediaQuery.of(context).size.height * 0.1,
              height: MediaQuery.of(context).size.height * 0.1,
              child: CircularProgressIndicator(color: _primary, strokeWidth: 6),
            ),
          ],
        ),
      ],
    );
  }

  Widget _messageView(BuildContext context, String message) {
    return _scrim(
      context,
      onClose: () => _controller.clearError(),
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Image.asset('images/${widget.logoAsset}.png',
                scale: 1.5, package: 'mobile_sign_language_translation'),
            Transform.translate(
              offset: Offset(0, MediaQuery.of(context).size.height * 0.1),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _panelView(BuildContext context) {
    final videoController = _controller.videoController;
    if (videoController == null) return const SizedBox.shrink();
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: const Color(0x4D000000)),
        Positioned(
          bottom: 0,
          child: SlideTransition(
            position: _offset,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 2,
              child: SignPanel(
                businessName: _strings.businessName,
                controller: videoController,
                text: _controller.currentText,
                primaryColor: _primary,
                textColor: _manager.theme.textColor,
                logoAsset: 'images/${widget.logoAsset}.png',
                videoPlayerLabel:
                    _manager.accessibility.videoPlayerLabel ?? _strings.videoPlayerLabel,
                closeButtonLabel: _manager.accessibility.closeButtonLabel ?? _strings.close,
                bottomSheetHint: _manager.accessibility.bottomSheetHint,
                onClose: () => _controller.dismissPanel(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
