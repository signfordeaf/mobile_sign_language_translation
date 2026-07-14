import 'package:flutter/material.dart';
import 'package:mobile_sign_language_translation/src/signfordeaf_manager.dart';

/// Wrapper for marking sensitive content.
///
/// Marks the texts ([Text], [SelectableText], [RichText]) in the subtree it
/// wraps as "sensitive". The inner text remains visible on screen and
/// selectable; however, when the user selects this text and taps "Sign
/// Language", no translation request is sent — because the guard matches the
/// selection against the marked texts and blocks it.
///
/// Example:
/// ```dart
/// SignForDeafSensitive(
///   child: Text('T.C. Kimlik No: 12345678901'),
/// )
/// ```
class SignForDeafSensitive extends StatefulWidget {
  /// Subtree holding the content to be treated as sensitive.
  final Widget child;

  const SignForDeafSensitive({super.key, required this.child});

  @override
  State<SignForDeafSensitive> createState() => _SignForDeafSensitiveState();
}

class _SignForDeafSensitiveState extends State<SignForDeafSensitive> {
  final SignForDeafManager _manager = SignForDeafManager();

  /// Texts added to the registry by this widget. On dispose / update we only
  /// clear these.
  final Set<String> _registered = <String>{};

  @override
  void initState() {
    super.initState();
    _scheduleCollect();
  }

  @override
  void didUpdateWidget(covariant SignForDeafSensitive oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The subtree may have changed; collect again.
    _clearRegistered();
    _scheduleCollect();
  }

  void _scheduleCollect() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _collectAndRegister();
    });
  }

  /// Walks the subtree and adds the content of text-carrying widgets to the registry.
  void _collectAndRegister() {
    final texts = <String>{};
    void visitor(Element element) {
      final widget = element.widget;
      String? text;
      if (widget is Text) {
        text = widget.data ?? widget.textSpan?.toPlainText();
      } else if (widget is SelectableText) {
        text = widget.data ?? widget.textSpan?.toPlainText();
      } else if (widget is RichText) {
        text = widget.text.toPlainText();
      }
      if (text != null && text.trim().isNotEmpty) {
        texts.add(text.trim());
      }
      element.visitChildren(visitor);
    }

    context.visitChildElements(visitor);

    for (final text in texts) {
      _manager.registerSensitive(text);
      _registered.add(text);
    }
  }

  void _clearRegistered() {
    for (final text in _registered) {
      _manager.unregisterSensitive(text);
    }
    _registered.clear();
  }

  @override
  void dispose() {
    _clearRegistered();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
