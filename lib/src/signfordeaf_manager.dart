import 'package:flutter/material.dart';
import 'package:mobile_sign_language_translation/src/config/signfordeaf_config.dart';

class SignForDeafManager {
  /// A static variable that holds the Singleton instance.
  static final SignForDeafManager _instance = SignForDeafManager._internal();

  /// A variable that keeps the packet open and closed status.
  bool _isSignOpen = true;

  /// The private constructor that initializes the package.
  String? _requestKey;
  String? _requestUrl;
  String? _originUrl;

  /// New optional settings (legacy usage leaves these at their defaults).
  /// Populated via [configure] or the corresponding setters.
  SignLanguage _language = SignLanguage.turkish;
  String _fdid = '16';
  String _tid = '23';
  SignForDeafTheme _theme = const SignForDeafTheme();
  FloatingButtonConfig _floatingButton = const FloatingButtonConfig();
  SignForDeafAccessibility _accessibility = const SignForDeafAccessibility();

  /// Manually marked (sensitive) texts. [SignForDeafSensitive] widgets register
  /// here when mounted and are removed when disposed. The guard checks whether
  /// the selected text overlaps with any text in this set.
  final Set<String> _sensitiveTexts = <String>{};

  /// Special configurator.
  SignForDeafManager._internal();

  /// The factory constructor that provides access to the singleton object.
  factory SignForDeafManager() {
    return _instance;
  }

  bool get isSignForDeafOpen => _isSignOpen;
  String? get requestKey => _requestKey;
  String? get requestUrl => _requestUrl;
  String? get originUrl => _originUrl;
  SignLanguage get language => _language;
  String get fdid => _fdid;
  String get tid => _tid;
  SignForDeafTheme get theme => _theme;
  FloatingButtonConfig get floatingButton => _floatingButton;
  SignForDeafAccessibility get accessibility => _accessibility;

  /// Single-object configuration. Sets all fields at once without breaking the
  /// existing setters. The origin defaults to [SignForDeafConfig.apiUrl] unless
  /// [SignForDeafConfig.originUrl] is provided.
  void configure(SignForDeafConfig config) {
    _requestKey = config.apiKey;
    _requestUrl = config.apiUrl;
    _originUrl = config.originUrl ?? config.apiUrl;
    _language = config.language;
    _fdid = config.fdid;
    _tid = config.tid;
    _theme = config.theme;
    _floatingButton = config.floatingButton;
    _accessibility = config.accessibility;
  }

  void setLanguage(SignLanguage language) => _language = language;
  void setFdid(String fdid) => _fdid = fdid;
  void setTid(String tid) => _tid = tid;
  void setTheme(SignForDeafTheme theme) => _theme = theme;
  void setFloatingButton(FloatingButtonConfig config) =>
      _floatingButton = config;
  void setAccessibility(SignForDeafAccessibility config) =>
      _accessibility = config;

  /// The function of initializing (opening) the package. Optionally, it provides the user with a return value and prints the status with debugPrint.
  T? active<T>({T Function()? onOpen}) {
    if (!_isSignOpen) {
      _isSignOpen = true;

      debugPrint('SignForDeaf: The SignForDeaf was actived');

      // If onOpen callback is provided, return the return value.
      return onOpen?.call();
    } else {
      debugPrint('SignForDeaf: The SignForDeaf is already active');
      return null;
    }
  }

  /// The function of stopping (closing) the package. Optionally, it provides the user with a return value and prints the status with debugPrint.
  T? deactive<T>({T Function()? onClose}) {
    if (_isSignOpen) {
      _isSignOpen = false;

      debugPrint('SignForDeaf: The SignForDeaf is deactived');

      /// If onClose callback is provided, return the return value.
      return onClose?.call();
    } else {
      debugPrint('SignForDeaf: The SignForDeaf is already deactive');
      return null;
    }
  }

  /// The function that set the request key.
  void setRequestKey(String requestKey) {
    _requestKey = requestKey;
  }

  /// The function that set the request url.
  void setRequestUrl(String requestUrl) {
    _requestUrl = requestUrl;
  }

  /// The function that set the origin url.
  void setOriginUrl(String originUrl) {
    _originUrl = originUrl;
  }

  /// Marks (registers) a text as sensitive. Empty/whitespace texts are ignored;
  /// the text is normalized (trimmed) before being stored.
  void registerSensitive(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return;
    _sensitiveTexts.add(normalized);
  }

  /// Removes a text previously added via [registerSensitive].
  void unregisterSensitive(String text) {
    _sensitiveTexts.remove(text.trim());
  }

  /// Does the [selected] text overlap with any of the marked sensitive texts?
  ///
  /// The user may have selected all, part, or more than the marked region, so a
  /// two-way `contains` comparison is performed.
  bool isRegisteredSensitive(String selected) {
    final normalized = selected.trim();
    if (normalized.isEmpty || _sensitiveTexts.isEmpty) return false;
    for (final sensitive in _sensitiveTexts) {
      if (normalized.contains(sensitive) || sensitive.contains(normalized)) {
        return true;
      }
    }
    return false;
  }
}
