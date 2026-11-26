import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/motion.dart';

/// Pull-to-refresh in slow motion. A drop-in replacement for
/// [RefreshIndicator] around a vertical scrollable.
///
/// Pulling down past the top drags the content with it and reveals a
/// round indicator whose coral ring fills as you pull. Past the trigger
/// point the arrow flips and the phone ticks. Let go and the content eases
/// to a resting gap while the ring spins slowly; once [onRefresh] finishes
/// (and at least [minimumHold] has passed), everything glides back over
/// [AppMotion.refreshSettle].
class SlowRefresh extends StatefulWidget {
  const SlowRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.minimumHold = const Duration(milliseconds: 1200),
  });

  final Future<void> Function() onRefresh;

  /// A vertical scrollable. Give it [AlwaysScrollableScrollPhysics] so it
  /// can be pulled even when its content is short.
  final Widget child;

  /// The indicator stays at least this long, so a quick refresh still
  /// plays out calmly instead of flickering.
  final Duration minimumHold;

  @override
  State<SlowRefresh> createState() => _SlowRefreshState();
}

enum _Phase { idle, dragging, refreshing, settling }

class _SlowRefreshState extends State<SlowRefresh>
    with TickerProviderStateMixin {
  /// Height of the gap above the content, in logical pixels.
  late final AnimationController _extent = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: AppMotion.refreshSpin,
  );

  static const double _trigger = 72;
  static const double _maxExtent = 124;
  static const double _indicatorSize = 40;

  _Phase _phase = _Phase.idle;
  double _drag = 0;
  bool _armed = false;

  @override
  void dispose() {
    _extent.dispose();
    _spin.dispose();
    super.dispose();
  }

  /// Rubber-band: the gap grows quickly at first, then resists.
  double _extentFor(double drag) =>
      _maxExtent * (1 - math.exp(-drag / _maxExtent));

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    if (_phase == _Phase.refreshing || _phase == _Phase.settling) {
      return false;
    }
    if (n is ScrollStartNotification &&
        n.dragDetails != null &&
        n.metrics.extentBefore == 0) {
      _phase = _Phase.dragging;
      _drag = 0;
      _armed = false;
    } else if (_phase == _Phase.dragging) {
      if (n is OverscrollNotification && n.overscroll < 0) {
        _drag -= n.overscroll;
      } else if (n is ScrollUpdateNotification && n.dragDetails != null) {
        // Pushing back up shrinks the pull before the content scrolls.
        _drag -= n.scrollDelta ?? 0;
      } else if (n is ScrollEndNotification ||
          (n is ScrollUpdateNotification && n.dragDetails == null)) {
        _release();
        return false;
      }
      _drag = math.max(0, _drag);
      _extent.value = _extentFor(_drag);
      final armed = _extent.value >= _trigger;
      if (armed != _armed) {
        setState(() => _armed = armed);
        if (armed) HapticFeedback.selectionClick();
      }
    }
    return false;
  }

  bool _onOverscrollIndicator(OverscrollIndicatorNotification n) {
    // The pull replaces the platform's glow or stretch at the top.
    if (n.leading && _phase != _Phase.idle) n.disallowIndicator();
    return false;
  }

  Future<void> _release() async {
    if (!_armed) {
      _settle();
      return;
    }
    setState(() => _phase = _Phase.refreshing);
    HapticFeedback.lightImpact();
    _spin.repeat();
    _extent.animateTo(
      _trigger,
      duration: AppMotion.long,
      curve: AppMotion.slowMotion,
    );
    try {
      await Future.wait([
        widget.onRefresh(),
        Future.delayed(widget.minimumHold),
      ]);
    } finally {
      if (mounted) _settle();
    }
  }

  Future<void> _settle() async {
    if (_extent.value <= 0.5) {
      _extent.value = 0;
      _spin.stop();
      setState(() {
        _phase = _Phase.idle;
        _armed = false;
      });
      return;
    }
    setState(() {
      _phase = _Phase.settling;
      _armed = false;
    });
    await _extent
        .animateTo(
          0,
          duration: AppMotion.refreshSettle,
          curve: AppMotion.slowMotion,
        )
        .orCancel
        .catchError((_) {});
    if (!mounted) return;
    _spin.stop();
    setState(() => _phase = _Phase.idle);
  }

  @override
  Widget build(BuildContext context) {
    final refreshing = _phase == _Phase.refreshing;
    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: _onOverscrollIndicator,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ScrollConfiguration(
          // Clamping physics on every platform, so the pull is measured the
          // same way everywhere and the content never double-bounces.
          behavior: ScrollConfiguration.of(context)
              .copyWith(physics: const ClampingScrollPhysics()),
          child: AnimatedBuilder(
            animation: _extent,
            child: widget.child,
            builder: (context, child) {
              final extent = math.max(0.0, _extent.value);
              return Stack(
                children: [
                  Transform.translate(offset: Offset(0, extent), child: child),
                  if (extent > 0.5)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: extent,
                      child: Center(
                        child: _Indicator(
                          pull: (extent / _trigger).clamp(0.0, 1.0),
                          armed: _armed || refreshing,
                          refreshing: refreshing,
                          spin: _spin,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.pull,
    required this.armed,
    required this.refreshing,
    required this.spin,
  });

  /// 0 when hidden, 1 at the trigger point.
  final double pull;
  final bool armed;
  final bool refreshing;
  final Animation<double> spin;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final appear = Curves.easeOut.transform(pull);
    return Semantics(
      liveRegion: true,
      label: refreshing ? 'Refreshing' : 'Pull to refresh',
      child: Opacity(
        opacity: appear,
        child: Transform.scale(
          scale: 0.6 + 0.4 * appear,
          child: Container(
            width: _SlowRefreshState._indicatorSize,
            height: _SlowRefreshState._indicatorSize,
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: colors.border),
              boxShadow: context.shadows.soft,
            ),
            child: AnimatedBuilder(
              animation: spin,
              builder: (context, _) => CustomPaint(
                painter: _RingPainter(
                  // While refreshing a short arc circles slowly; while
                  // pulling the ring fills with the pull.
                  sweep: refreshing ? 0.3 : pull,
                  rotation: refreshing ? spin.value : pull * 0.25,
                  track: colors.surfaceMuted,
                  color: colors.accent,
                ),
                child: Center(
                  child: AnimatedRotation(
                    turns: armed ? 0.5 : 0,
                    duration: AppMotion.long,
                    curve: AppMotion.slowMotion,
                    child: Icon(
                      Icons.arrow_downward_rounded,
                      size: Dimens.iconSizeSmall,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.sweep,
    required this.rotation,
    required this.track,
    required this.color,
  });

  /// Fraction of the ring that is filled.
  final double sweep;

  /// Start angle in turns.
  final double rotation;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(6);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    if (sweep <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2 + rotation * math.pi * 2,
      sweep * math.pi * 2,
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.sweep != sweep ||
      old.rotation != rotation ||
      old.track != track ||
      old.color != color;
}
