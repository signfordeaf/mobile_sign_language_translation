import 'package:flutter/material.dart';

class SignForDeafManager {
  /// A static variable that holds the Singleton instance.
  static final SignForDeafManager _instance = SignForDeafManager._internal();

  /// A variable that keeps the packet open and closed status.
  bool _isSignOpen = true;

  /// The private constructor that initializes the package.
  String? _requestKey;
  String? _requestUrl;

  /// Special configurator.
  SignForDeafManager._internal();

  /// The factory constructor that provides access to the singleton object.
  factory SignForDeafManager() {
    return _instance;
  }

  bool get isSignForDeafOpen => _isSignOpen;
  String? get requestKey => _requestKey;
  String? get requestUrl => _requestUrl;

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
}
