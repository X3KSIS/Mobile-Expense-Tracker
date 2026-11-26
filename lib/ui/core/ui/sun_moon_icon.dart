import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/motion.dart';

/// An outline sun that morphs into a crescent moon, and back.
///
/// As it turns to the moon, the rays swirl and retract into the body, the
/// body swells, a second circle slides in to bite out the crescent, and a
/// small star twinkles into the gap. Reversing plays the same morph
/// backwards. Wrap it in a button with a tooltip; it has no label itself.
class SunMoonIcon extends StatelessWidget {
  const SunMoonIcon({
    super.key,
    required this.isMoon,
    this.size = Dimens.iconSize,
    this.color,
  });

  /// Shows the moon when true, the sun when false.
  final bool isMoon;
  final double size;

  /// Defaults to the primary text colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.colors.textPrimary;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: isMoon ? 1 : 0),
      duration: reduceMotion ? Duration.zero : AppMotion.morph,
      curve: Curves.easeInOutCubic,
      builder: (context, t, _) => CustomPaint(
        size: Size.square(size),
        painter: SunMoonPainter(progress: t, color: color),
      ),
    );
  }
}

/// Paints the [SunMoonIcon] at [progress] 0 (sun) to 1 (moon) in a
/// 24-unit box, with an outline stroke of 1.8.
class SunMoonPainter extends CustomPainter {
  SunMoonPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  static const double _stroke = 1.8;
  static const double _sunRadius = 4.4;
  static const double _moonRadius = 8;
  static const int _rays = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.clamp(0.0, 1.0);
    canvas.scale(size.width / 24, size.height / 24);
    const center = Offset(12, 12);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Body: a circle with a second circle sliding in from the top-right to
    // cut out the crescent. At t = 0 the cutter is far outside the body.
    final r = lerpDouble(_sunRadius, _moonRadius, t)!;
    final cutterRadius = r * 0.78;
    final cutterCenter =
        center +
        Offset(
          lerpDouble(r * 2.6, r * 0.42, t)!,
          -lerpDouble(r * 2.6, r * 0.38, t)!,
        );
    final body = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: center, radius: r)),
      Path()
        ..addOval(Rect.fromCircle(center: cutterCenter, radius: cutterRadius)),
    );
    canvas.drawPath(body, paint);

    // Rays swirl a quarter turn while retracting into the body.
    final rayLength = lerpDouble(2.4, 0, Curves.easeIn.transform(t))!;
    if (rayLength > 0.05) {
      final rayPaint = Paint()
        ..color = color.withValues(alpha: color.a * (1 - t))
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round;
      final inner = _sunRadius + 2.6 + t * 1.5;
      final swirl = t * math.pi / 2;
      for (var i = 0; i < _rays; i++) {
        final angle = i * 2 * math.pi / _rays + swirl;
        final dir = Offset(math.cos(angle), math.sin(angle));
        canvas.drawLine(
          center + dir * inner,
          center + dir * (inner + rayLength),
          rayPaint,
        );
      }
    }

    // A small star twinkles into the crescent's gap in the second half.
    final star = Curves.easeOutBack.transform(((t - 0.55) / 0.45).clamp(0, 1));
    if (star > 0.01) {
      final starPaint = Paint()
        ..color = color.withValues(alpha: color.a * star.clamp(0, 1))
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke * 0.85
        ..strokeCap = StrokeCap.round;
      const starCenter = Offset(18.6, 5.4);
      final arm = 1.7 * star;
      canvas
        ..drawLine(
          starCenter - Offset(0, arm),
          starCenter + Offset(0, arm),
          starPaint,
        )
        ..drawLine(
          starCenter - Offset(arm, 0),
          starCenter + Offset(arm, 0),
          starPaint,
        );
    }
  }

  @override
  bool shouldRepaint(SunMoonPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
