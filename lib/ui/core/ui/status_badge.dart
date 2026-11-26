import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/motion.dart';
import '../themes/theme.dart';

/// The four status meanings used across the app. Each one has its own
/// colour, shape and glyph, so a status never relies on colour alone:
///
/// | Status  | Means             | Shape          | Glyph |
/// |---------|-------------------|----------------|-------|
/// | success | active, paid      | circle         | check |
/// | warning | pending, near     | triangle       | !     |
/// | danger  | failed, over      | octagon        | ×     |
/// | neutral | draft, not started| dashed ring    | –     |
enum StatusTone { success, warning, danger, neutral }

extension StatusToneColors on StatusTone {
  /// Strong colour for the mark and label.
  Color strong(AppPalette c) => switch (this) {
    StatusTone.success => c.success,
    StatusTone.warning => c.warning,
    StatusTone.danger => c.error,
    StatusTone.neutral => c.neutral,
  };

  /// Soft background the strong colour passes 4.5:1 on.
  Color soft(AppPalette c) => switch (this) {
    StatusTone.success => c.successSoft,
    StatusTone.warning => c.warningSoft,
    StatusTone.danger => c.errorSoft,
    StatusTone.neutral => c.neutralSoft,
  };
}

/// A soft pill with a [StatusMark] and a label, e.g. "On track".
///
/// When the tone or label changes, the old badge fades out and the new one
/// pops in, so status changes never cut abruptly.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.tone, required this.label});

  final StatusTone tone;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strong = tone.strong(colors);
    return AnimatedSwitcher(
      duration: AppMotion.medium,
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: AppMotion.fadeThroughOutReverse,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: Semantics(
        key: ValueKey((tone, label)),
        label: 'Status: $label',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            Dimens.gapXs + 2,
            Dimens.gapXs,
            Dimens.gapS + 2,
            Dimens.gapXs,
          ),
          decoration: ShapeDecoration(
            color: tone.soft(colors),
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusMark(tone: tone),
              const SizedBox(width: Dimens.gapXs + 2),
              Text(label, style: context.text.badge.copyWith(color: strong)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The shape-and-glyph mark for a [StatusTone], 16px by default.
class StatusMark extends StatelessWidget {
  const StatusMark({super.key, required this.tone, this.size = 16});

  final StatusTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return CustomPaint(
      size: Size.square(size),
      painter: _StatusMarkPainter(
        tone: tone,
        fill: tone.strong(colors),
        glyph: tone.soft(colors),
      ),
    );
  }
}

class _StatusMarkPainter extends CustomPainter {
  _StatusMarkPainter({
    required this.tone,
    required this.fill,
    required this.glyph,
  });

  final StatusTone tone;
  final Color fill;
  final Color glyph;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw in a 16-unit box.
    canvas.scale(size.width / 16, size.height / 16);
    const c = Offset(8, 8);
    final fillPaint = Paint()..color = fill;
    final glyphPaint = Paint()
      ..color = glyph
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (tone) {
      case StatusTone.success:
        canvas
          ..drawCircle(c, 8, fillPaint)
          ..drawPath(
            Path()
              ..moveTo(4.6, 8.2)
              ..lineTo(7, 10.6)
              ..lineTo(11.4, 5.8),
            glyphPaint,
          );
      case StatusTone.warning:
        final triangle = Path()
          ..moveTo(8, 0.8)
          ..lineTo(15.4, 14.6)
          ..lineTo(0.6, 14.6)
          ..close();
        canvas
          ..drawPath(
            triangle,
            Paint()
              ..color = fill
              ..style = PaintingStyle.fill
              ..strokeJoin = StrokeJoin.round,
          )
          ..drawPath(
            triangle,
            Paint()
              ..color = fill
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4
              ..strokeJoin = StrokeJoin.round,
          )
          ..drawLine(const Offset(8, 6), const Offset(8, 9.4), glyphPaint)
          ..drawCircle(const Offset(8, 12.2), 1, Paint()..color = glyph);
      case StatusTone.danger:
        final octagon = Path();
        for (var i = 0; i < 8; i++) {
          final angle = math.pi / 8 + i * math.pi / 4;
          final p = c + Offset(math.cos(angle), math.sin(angle)) * 8.2;
          i == 0 ? octagon.moveTo(p.dx, p.dy) : octagon.lineTo(p.dx, p.dy);
        }
        octagon.close();
        canvas
          ..drawPath(octagon, fillPaint)
          ..drawLine(
            const Offset(5.4, 5.4),
            const Offset(10.6, 10.6),
            glyphPaint,
          )
          ..drawLine(
            const Offset(10.6, 5.4),
            const Offset(5.4, 10.6),
            glyphPaint,
          );
      case StatusTone.neutral:
        // Dashed ring (no fill) with a short dash in the middle.
        final ring = Paint()
          ..color = fill
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;
        const dashes = 8;
        const sweep = 2 * math.pi / dashes;
        final rect = Rect.fromCircle(center: c, radius: 7);
        for (var i = 0; i < dashes; i++) {
          canvas.drawArc(rect, i * sweep, sweep * 0.55, false, ring);
        }
        canvas.drawLine(const Offset(5.6, 8), const Offset(10.4, 8), ring);
    }
  }

  @override
  bool shouldRepaint(_StatusMarkPainter oldDelegate) =>
      oldDelegate.tone != tone ||
      oldDelegate.fill != fill ||
      oldDelegate.glyph != glyph;
}
