import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_sign_language_translation/src/config/signfordeaf_config.dart';

/// Draggable, edge-snapping logo button that toggles the tap-to-translate
/// mode.
///
/// Starts as a flat "tab" in the middle of the right edge; the user drags it
/// anywhere, and on release it springs to the nearest left/right edge. If left
/// untouched for a while (idle) it partially slides off the edge ("peek") and
/// fades slightly; a touch wakes it. If movement is less than [_tapThreshold]
/// it counts as a tap and toggles the mode.
class SignForDeafFloatingButton extends StatefulWidget {
  final bool active;
  final VoidCallback onPressed;
  final FloatingButtonConfig config;
  final Color primaryColor;
  final String logoAsset;
  final String hintText;
  final bool showHint;

  const SignForDeafFloatingButton({
    super.key,
    required this.active,
    required this.onPressed,
    required this.config,
    required this.primaryColor,
    required this.logoAsset,
    required this.hintText,
    required this.showHint,
  });

  @override
  State<SignForDeafFloatingButton> createState() =>
      _SignForDeafFloatingButtonState();
}

/// Movement threshold (px): below this it counts as a tap rather than a drag.
const double _tapThreshold = 6;
const double _idleOpacity = 0.55;
const double _peekHiddenFraction = 0.35;

enum _Side { left, right }

class _SignForDeafFloatingButtonState extends State<SignForDeafFloatingButton>
    with SingleTickerProviderStateMixin {
  Offset _pos = Offset.zero;
  _Side? _restingSide = _Side.right;
  bool _isTop = false;
  bool _isPeeked = false;
  double _opacity = 1;
  bool _initialized = false;

  double _dragDistance = 0;
  bool _wasPeekedOnGrant = false;

  Timer? _idleTimer;
  late final AnimationController _anim;
  Animation<Offset>? _posAnim;
  Animation<double>? _opacityAnim;

  double get _size => widget.config.size;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        setState(() {
          if (_posAnim != null) _pos = _posAnim!.value;
          if (_opacityAnim != null) _opacity = _opacityAnim!.value;
        });
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final b = _bounds;
      _pos = Offset(b.right, (b.top + b.bottom) / 2);
      _initialized = true;
      _scheduleIdle();
    }
  }

  /// Screen bounds for the button's top-left corner (respects the safe area).
  ({double left, double right, double top, double bottom}) get _bounds {
    final media = MediaQuery.of(context);
    final size = media.size;
    final pad = media.padding;
    final maxX = (size.width - _size).clamp(0.0, double.infinity);
    final minY = pad.top;
    final maxY =
        (size.height - _size - pad.bottom).clamp(minY, double.infinity);
    return (left: 0.0, right: maxX, top: minY, bottom: maxY);
  }

  double _clamp(double v, double min, double max) =>
      v < min ? min : (v > max ? max : v);

  void _clearIdle() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  void _scheduleIdle() {
    _clearIdle();
    if (widget.config.idleBehavior == FloatingButtonIdleBehavior.none) return;
    _idleTimer = Timer(
      Duration(milliseconds: widget.config.idleDelayMs),
      _runIdle,
    );
  }

  void _runIdle() {
    if (_restingSide == null) return; // only while resting at an edge
    _isPeeked = true;
    final b = _bounds;
    Offset target = _pos;
    if (widget.config.idleBehavior == FloatingButtonIdleBehavior.peek) {
      final hidden = _size * _peekHiddenFraction;
      target = _restingSide == _Side.left
          ? Offset(b.left - hidden, _pos.dy)
          : Offset(b.right + hidden, _pos.dy);
    }
    _animateTo(target, _idleOpacity);
  }

  void _animateTo(Offset target, double opacity) {
    _posAnim = Tween<Offset>(begin: _pos, end: target)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutBack));
    _opacityAnim = Tween<double>(begin: _opacity, end: opacity)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim
      ..reset()
      ..forward();
  }

  void _settleAt(Offset target, _Side side, bool isTop) {
    _restingSide = side;
    _isTop = isTop;
    _isPeeked = false;
    _animateTo(target, 1);
    _scheduleIdle();
  }

  ({Offset target, _Side side, bool isTop}) _computeSnap(Offset from) {
    final b = _bounds;
    final x = _clamp(from.dx, b.left, b.right);
    final y = _clamp(from.dy, b.top, b.bottom);
    final isLeft = x + _size / 2 < (b.left + b.right + _size) / 2;
    final isTop = y + _size / 2 < (b.top + b.bottom + _size) / 2;
    return (
      target: Offset(isLeft ? b.left : b.right, y),
      side: isLeft ? _Side.left : _Side.right,
      isTop: isTop,
    );
  }

  void _onPointerDown(PointerDownEvent _) {
    _clearIdle();
    _anim.stop();
    _wasPeekedOnGrant = _isPeeked;
    _dragDistance = 0;
    setState(() {
      _isPeeked = false;
      _opacity = 1;
      // NB: keep the current resting side here so a plain tap does not flash the
      // full-circle shape. We only switch to a circle once a real drag begins
      // (see _onPointerMove).
    });
  }

  void _onPointerMove(PointerMoveEvent details) {
    _dragDistance += details.delta.distance;
    setState(() {
      _pos += details.delta;
      // Full circle only while actually dragging, not on a simple tap.
      if (_restingSide != null && _dragDistance > _tapThreshold) {
        _restingSide = null;
      }
    });
  }

  void _onPointerUp(PointerUpEvent _) {
    if (_dragDistance <= _tapThreshold) {
      // Tap.
      if (_wasPeekedOnGrant) {
        // The first tap on a peeked button only wakes it (mode does not change).
        final snap = _computeSnap(_pos);
        _settleAt(snap.target, snap.side, snap.isTop);
      } else {
        final snap = _computeSnap(_pos);
        _restingSide = snap.side;
        widget.onPressed();
        _scheduleIdle();
      }
      return;
    }
    final snap = _computeSnap(_pos);
    _settleAt(snap.target, snap.side, snap.isTop);
  }

  @override
  void dispose() {
    _clearIdle();
    _anim.dispose();
    super.dispose();
  }

  BorderRadius _radii() {
    final r = Radius.circular(_size / 2);
    switch (_restingSide) {
      case _Side.left:
        return BorderRadius.only(topRight: r, bottomRight: r);
      case _Side.right:
        return BorderRadius.only(topLeft: r, bottomLeft: r);
      case null:
        return BorderRadius.all(r);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;
    final primary = widget.primaryColor;

    // The SDK sits above the host MaterialApp, so Theme.of(context) is not the
    // app's theme; platformBrightness is the reliable ambient signal. We derive
    // brightness-aware DEFAULTS so the closed (OFF) and open (ON) states always
    // contrast — OFF stays outlined, ON stays solid. Any color the host set on
    // FloatingButtonConfig still wins (each default is behind `?? cfg.<field>`).
    final isDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final bg =
        cfg.backgroundColor ?? (isDark ? const Color(0xFF2A2A2A) : Colors.white);
    final activeBg = cfg.activeBackgroundColor ?? primary;
    final iconColor = cfg.iconColor ?? (isDark ? Colors.white : primary);
    final activeIconColor =
        cfg.activeIconColor ?? (isDark ? Colors.black : Colors.white);
    final borderColor = cfg.borderColor ?? (isDark ? Colors.white : primary);

    final button = Opacity(
      opacity: _opacity,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        child: Semantics(
          button: true,
          selected: widget.active,
          label: 'İşaret dili çeviri modu',
          child: Container(
            width: _size,
            height: _size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.active ? activeBg : bg,
              borderRadius: _radii(),
              border: widget.active
                  ? null
                  : Border.all(color: borderColor, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Image.asset(
              widget.logoAsset,
              package: 'mobile_sign_language_translation',
              width: _size * 0.6,
              height: _size * 0.6,
              color: widget.active ? activeIconColor : iconColor,
            ),
          ),
        ),
      ),
    );

    final showHintBubble = widget.active && widget.showHint && !_isPeeked;

    // The hint bubble is a fixed-width box laid out in this Column. Anchoring
    // only by `left` makes it grow rightward, so when the button is docked to
    // the right edge the bubble (and, via crossAxisAlignment.end, the button
    // itself) spills off-screen. When right-docked, anchor the right edge
    // instead so the bubble grows leftward into visible space.
    final screenW = MediaQuery.sizeOf(context).width;
    final rightDocked = _restingSide == _Side.right;

    return Positioned(
      left: rightDocked ? null : _pos.dx,
      right: rightDocked ? (screenW - _pos.dx - _size) : null,
      top: _pos.dy,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            _restingSide == _Side.left ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          if (showHintBubble && _isTop) ...[
            button,
            const SizedBox(height: 8),
            _hint(),
          ] else if (showHintBubble) ...[
            _hint(),
            const SizedBox(height: 8),
            button,
          ] else
            button,
        ],
      ),
    );
  }

  Widget _hint() {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xCC000000),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.hintText,
        maxLines: 2,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}
