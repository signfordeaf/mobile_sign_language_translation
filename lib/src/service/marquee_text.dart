import 'package:flutter/material.dart';

/// Displays text centered and static if it fits within its box; otherwise it
/// switches to a continuously scrolling (marquee) horizontal display.
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  /// Scroll speed (approximate pixels per second).
  final double scrollSpeed;

  const MarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.scrollSpeed = 50.0,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  AnimationController? _animationController;
  Animation<double>? _animation;

  /// Whether the text does not fit its box (i.e. scrolling is required).
  bool _needsScrolling = false;

  @override
  void initState() {
    super.initState();
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(covariant MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-measure if the text or style changed.
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      _disposeAnimation();
      _needsScrolling = false;
      _scheduleMeasure();
    }
  }

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measure();
    });
  }

  void _measure() {
    final textWidth = _textWidth();
    final containerWidth = context.size?.width ?? 0.0;
    final needs = textWidth > containerWidth + 0.5;
    if (needs == _needsScrolling) return;

    if (needs) {
      final distance = textWidth - containerWidth;
      final seconds = (textWidth / widget.scrollSpeed).round().clamp(1, 120);
      final animController = AnimationController(
        vsync: this,
        duration: Duration(seconds: seconds),
      );
      _animation = Tween<double>(begin: 0, end: distance).animate(animController)
        ..addListener(() {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_animation!.value);
          }
        })
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            animController.repeat(reverse: false);
          }
        });
      _animationController = animController;
      setState(() => _needsScrolling = true);
      animController.forward();
    } else {
      _disposeAnimation();
      setState(() => _needsScrolling = false);
    }
  }

  double _textWidth() {
    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width;
  }

  void _disposeAnimation() {
    _animationController?.dispose();
    _animationController = null;
    _animation = null;
  }

  @override
  Widget build(BuildContext context) {
    // Centered static text if it fits.
    if (!_needsScrolling) {
      return Center(
        child: Text(
          widget.text,
          style: widget.style,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
        ),
      );
    }
    // Scrolling text if it does not fit.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      child: Text(widget.text, style: widget.style, maxLines: 1, softWrap: false),
    );
  }

  @override
  void dispose() {
    _disposeAnimation();
    _scrollController.dispose();
    super.dispose();
  }
}
