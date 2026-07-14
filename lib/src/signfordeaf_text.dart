import 'package:flutter/material.dart';
import 'package:mobile_sign_language_translation/src/signfordeaf_controller.dart';

/// Reliable, opt-in text component for tap-to-translate. Use it where the
/// global hit-test may be unreliable (custom painting, transforms, etc.): while
/// tap mode is on, tapping this text translates [data] directly.
///
/// While tap mode is off it behaves like an ordinary [Text]; the text also
/// remains selectable (the existing selection + menu flow keeps working).
class SignForDeafText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const SignForDeafText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      data,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );

    final controller = SignForDeafScope.maybeOf(context);
    if (controller == null || !controller.isTapToTranslateActive) {
      return text;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => controller.translate(data),
      child: text,
    );
  }
}
