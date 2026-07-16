import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Detector wrapped around the content while tap-to-translate mode is on. It
/// finds the text under a tap via a **hit-test** in the Dart render tree and
/// reports it through [onText].
///
/// Because Flutter draws the entire UI on a single native surface (there are no
/// per-widget native text views to attach listeners to), this is the
/// Flutter-native counterpart of the "tap anywhere to translate" behavior: the
/// plain text of the first [RenderParagraph] at the tapped point is read.
///
/// Only this detector's subtree is scanned; the floating button / hint bubble
/// above is never captured. While enabled, a top-most translucent tap-catcher
/// is laid over the content: it *wins* the tap gesture (so the underlying app
/// element does not also react — e.g. no accidental navigation while a
/// translation loads), yet it only owns taps, so scrolling still falls through
/// to the content underneath.
class TapToTranslateDetector extends StatefulWidget {
  final bool enabled;
  final ValueChanged<String> onText;
  final Widget child;

  const TapToTranslateDetector({
    super.key,
    required this.enabled,
    required this.onText,
    required this.child,
  });

  @override
  State<TapToTranslateDetector> createState() => _TapToTranslateDetectorState();
}

class _TapToTranslateDetectorState extends State<TapToTranslateDetector> {
  void _handleTap(Offset globalPosition) {
    final root = context.findRenderObject();
    if (root == null) return;
    final text = _textAt(root, globalPosition);
    if (text != null && text.trim().isNotEmpty) {
      widget.onText(text.trim());
    }
  }

  /// Returns the plain text of the deepest text render object in the [root]
  /// subtree that contains the global [target] point.
  ///
  /// Both plain [Text] ([RenderParagraph]) and selectable/editable texts
  /// ([SelectableText], [TextField] → [RenderEditable]) are supported.
  String? _textAt(RenderObject root, Offset target) {
    String? found;
    void visit(RenderObject node) {
      if (node.attached && node is RenderBox && node.hasSize) {
        String? text;
        if (node is RenderParagraph) {
          text = node.text.toPlainText();
        } else if (node is RenderEditable) {
          text = node.text?.toPlainText();
        }
        if (text != null) {
          final topLeft = node.localToGlobal(Offset.zero);
          if ((topLeft & node.size).contains(target)) {
            // Keep the deepest/topmost match.
            found = text;
          }
        }
      }
      node.visitChildren(visit);
    }

    visit(root);
    return found;
  }

  @override
  Widget build(BuildContext context) {
    // [widget.child] is the host's entire app (MaterialApp/Navigator). It must
    // ALWAYS sit at the same position in the element tree, otherwise toggling
    // `enabled` reparents it and Flutter rebuilds the whole app from scratch —
    // recreating the Navigator and resetting the route stack (and re-running the
    // app's bootstrap). So we keep this Stack mounted in both states, with the
    // child fixed at slot 0, and only add/remove the top tap-catcher.
    //
    // The tap-catcher is the top child of this Stack, so it is hit-tested first
    // and wins the tap gesture over any app element below it (the app therefore
    // does not react to the tap). It is translucent and only recognizes taps,
    // so drags/scrolls fall through to the content underneath. Because the
    // catcher shares this Stack with [widget.child], `context.findRenderObject`
    // still reaches the app subtree for text hit-testing in [_handleTap].
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (widget.enabled)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: (details) => _handleTap(details.globalPosition),
            ),
          ),
      ],
    );
  }
}
