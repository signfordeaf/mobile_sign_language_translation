import 'package:flutter/material.dart';

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
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
  late ScrollController _scrollController;
  AnimationController?
      _animationController; // Make AnimationController nullable
  Animation<double>? _animation; // Make Animation nullable
  bool _needsScrolling = false; // Flag to check if scrolling is needed

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      double textWidth = _getTextWidth();
      double containerWidth = context.size?.width ?? 0.0;

      // Check if scrolling is needed
      if (textWidth > containerWidth) {
        _needsScrolling = true;
        _animationController = AnimationController(
          vsync: this,
          duration: Duration(seconds: (textWidth / widget.scrollSpeed).round()),
        );
        _animation = Tween<double>(begin: 0, end: textWidth - containerWidth)
            .animate(_animationController!)
          ..addListener(() {
            _scrollController.jumpTo(_animation!.value);
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _animationController!.repeat(reverse: false);
            }
          });
        _animationController!.forward();
      }
    });
  }

  double _getTextWidth() {
    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.width;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      child: Text(widget.text, style: widget.style),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (_needsScrolling) {
      _animationController?.dispose();
    }
    super.dispose();
  }
}
