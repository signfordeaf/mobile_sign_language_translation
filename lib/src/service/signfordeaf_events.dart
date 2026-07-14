/// Event types emitted throughout the translation lifecycle.
enum SignForDeafEventType {
  textSelected,
  translationStart,
  translationComplete,
  translationError,
  panelOpen,
  panelClose,
  videoStart,
  videoEnd,
  videoError,
  /// Translation was blocked because the selected text contains sensitive data.
  blockedSensitive,
}

/// Error codes.
enum SignForDeafErrorCode {
  networkError,
  apiError,
  videoError,
  configurationError,
  cancelled,
  unknown,
}

/// SDK error.
class SignForDeafError {
  final SignForDeafErrorCode code;
  final String message;

  const SignForDeafError(this.code, this.message);

  @override
  String toString() => 'SignForDeafError($code): $message';
}

/// Event emitted by the controller. The payload usually carries the relevant
/// text or video URL.
class SignForDeafEvent {
  final SignForDeafEventType type;

  /// Text (textSelected/translationStart/complete) or null.
  final String? text;

  /// Video URL (translationComplete/videoStart) or null.
  final String? videoUrl;

  /// Error (translationError/videoError) or null.
  final SignForDeafError? error;

  final DateTime timestamp;

  SignForDeafEvent(
    this.type, {
    this.text,
    this.videoUrl,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
