import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mobile_sign_language_translation/src/service/sensitive_data_guard.dart';
import 'package:mobile_sign_language_translation/src/service/service.dart';
import 'package:mobile_sign_language_translation/src/service/signfordeaf_events.dart';
import 'package:mobile_sign_language_translation/src/signfordeaf_manager.dart';
import 'package:mobile_sign_language_translation/src/storage/signfordeaf_storage.dart';
import 'package:video_player/video_player.dart';

/// Current state of the panel/translation.
enum SignForDeafStatus { idle, loading, ready, error, blocked }

/// The single source of truth for all SDK state and actions. Every translation
/// (selection/tap/programmatic) flows through here; it manages the video
/// lifecycle and the event stream.
///
/// Provided to the tree via [SignForDeafScope] and read via
/// `SignForDeaf.of(context)`.
class SignForDeafController extends ChangeNotifier {
  SignForDeafController({
    ApiServices? apiServices,
    SignForDeafStorage? storage,
  })  : _api = apiServices ?? ApiServices(),
        _storage = storage ?? InMemorySignForDeafStorage();

  final ApiServices _api;
  final SignForDeafStorage _storage;

  static const String hintCountStorageKey = 'hint_shown_count';

  // ---- State ----
  // Disabled by default: until the SDK is explicitly enable()d (or autoEnable),
  // the app behaves fully natively — no text is forced to be selectable and the
  // floating button is hidden.
  bool _isEnabled = false;
  bool _isTapToTranslateActive = false;
  SignForDeafStatus _status = SignForDeafStatus.idle;
  String? _currentText;
  SignForDeafError? _error;
  VideoPlayerController? _videoController;

  bool _showHint = false;
  int _hintShownCount = 0;
  bool _hintRestored = false;

  bool get isEnabled => _isEnabled;
  bool get isTapToTranslateActive => _isTapToTranslateActive;
  SignForDeafStatus get status => _status;
  bool get isLoading => _status == SignForDeafStatus.loading;
  bool get isPanelVisible => _status == SignForDeafStatus.ready;
  String? get currentText => _currentText;
  SignForDeafError? get error => _error;
  VideoPlayerController? get videoController => _videoController;
  bool get showHint => _showHint;

  // ---- Events ----
  final StreamController<SignForDeafEvent> _events =
      StreamController<SignForDeafEvent>.broadcast();

  /// Translation lifecycle event stream.
  Stream<SignForDeafEvent> get events => _events.stream;

  void _emit(SignForDeafEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  // ---- Actions ----

  void enable() {
    if (_isEnabled) return;
    _isEnabled = true;
    notifyListeners();
  }

  void disable() {
    if (!_isEnabled && !_isTapToTranslateActive) return;
    _isEnabled = false;
    _isTapToTranslateActive = false;
    _showHint = false;
    notifyListeners();
  }

  /// Called by the floating button. Toggles the mode and manages the hint
  /// budget (the hint is shown on the first [FloatingButtonConfig.hintMaxShows]
  /// activations).
  Future<void> toggleTapToTranslate() async {
    _isTapToTranslateActive = !_isTapToTranslateActive;
    if (_isTapToTranslateActive) {
      await _restoreHintCount();
      final maxShows = SignForDeafManager().floatingButton.hintMaxShows;
      if (_hintShownCount < maxShows) {
        _showHint = true;
        _hintShownCount++;
        unawaited(
          _storage.setItem(hintCountStorageKey, '$_hintShownCount'),
        );
      } else {
        _showHint = false;
      }
    } else {
      _showHint = false;
    }
    notifyListeners();
  }

  Future<void> _restoreHintCount() async {
    if (_hintRestored) return;
    _hintRestored = true;
    final value = await _storage.getItem(hintCountStorageKey);
    final parsed = value == null ? 0 : int.tryParse(value);
    if (parsed != null) _hintShownCount = parsed;
  }

  /// Translates the text: sensitive data check → API → video. All paths
  /// (selection/tap/programmatic) converge here.
  Future<void> translate(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Sensitive data protection (runs first): no request is sent.
    if (SensitiveDataGuard.isSensitive(trimmed)) {
      _status = SignForDeafStatus.blocked;
      _currentText = trimmed;
      notifyListeners();
      _emit(SignForDeafEvent(SignForDeafEventType.blockedSensitive, text: trimmed));
      return;
    }

    _emit(SignForDeafEvent(SignForDeafEventType.textSelected, text: trimmed));
    _status = SignForDeafStatus.loading;
    _currentText = trimmed;
    _error = null;
    notifyListeners();
    _emit(SignForDeafEvent(SignForDeafEventType.translationStart, text: trimmed));

    try {
      final signModel = await _api.getSignVideo(text: trimmed);
      if (signModel.cid == 'cancelled') {
        _status = SignForDeafStatus.idle;
        notifyListeners();
        _emit(SignForDeafEvent(SignForDeafEventType.translationError,
            error: const SignForDeafError(
                SignForDeafErrorCode.cancelled, 'Translation cancelled')));
        return;
      }
      if (signModel.state == null || signModel.baseUrl == null) {
        _fail(SignForDeafErrorCode.apiError, 'Translation is not available');
        return;
      }
      final url = '${signModel.baseUrl}${signModel.name}'
          .replaceFirst('http:', 'https:');
      await _initVideo(url, trimmed);
    } catch (e) {
      _fail(SignForDeafErrorCode.networkError, e.toString());
    }
  }

  Future<void> _initVideo(String url, String text) async {
    await _disposeVideo();
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      _status = SignForDeafStatus.ready;
      notifyListeners();
      _emit(SignForDeafEvent(SignForDeafEventType.panelOpen, text: text));
      _emit(SignForDeafEvent(SignForDeafEventType.videoStart,
          text: text, videoUrl: url));
      _emit(SignForDeafEvent(SignForDeafEventType.translationComplete,
          text: text, videoUrl: url));
    } catch (e) {
      _fail(SignForDeafErrorCode.videoError, e.toString());
    }
  }

  void _fail(SignForDeafErrorCode code, String message) {
    _error = SignForDeafError(code, message);
    _status = SignForDeafStatus.error;
    notifyListeners();
    _emit(SignForDeafEvent(SignForDeafEventType.translationError, error: _error));
  }

  /// Closes the panel and releases the video.
  Future<void> dismissPanel() async {
    final wasVisible = _status == SignForDeafStatus.ready;
    await _disposeVideo();
    _status = SignForDeafStatus.idle;
    notifyListeners();
    if (wasVisible) {
      _emit(SignForDeafEvent(SignForDeafEventType.panelClose));
    }
  }

  /// Cancels the in-progress translation.
  Future<void> cancelTranslation() async {
    _api.cancelRequest();
    await _disposeVideo();
    _status = SignForDeafStatus.idle;
    notifyListeners();
  }

  /// Dismisses the error/blocked notice.
  void clearError() {
    if (_status == SignForDeafStatus.error ||
        _status == SignForDeafStatus.blocked) {
      _status = SignForDeafStatus.idle;
      _error = null;
      notifyListeners();
    }
  }

  Future<void> _disposeVideo() async {
    final controller = _videoController;
    _videoController = null;
    if (controller != null) {
      await controller.pause();
      await controller.dispose();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _videoController = null;
    _events.close();
    super.dispose();
  }
}

/// InheritedNotifier that provides the controller to the widget tree.
/// `SignForDeaf.of(context)` reads it.
class SignForDeafScope extends InheritedNotifier<SignForDeafController> {
  const SignForDeafScope({
    super.key,
    required SignForDeafController controller,
    required super.child,
  }) : super(notifier: controller);

  static SignForDeafController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SignForDeafScope>()
        ?.notifier;
  }

  static SignForDeafController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'No SignForDeafScope found in context');
    return controller!;
  }
}
