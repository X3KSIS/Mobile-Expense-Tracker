import 'package:flutter/widgets.dart';

import '../themes/motion.dart';

/// Reveals [child] by growing from zero height when [expanded], and folds
/// it away again when not, over [AppMotion.expand] with an ease-out curve.
/// The content fades ahead of the height so it never appears squashed.
///
/// The child is only built while it is at least partly visible.
class ExpandableSection extends StatelessWidget {
  const ExpandableSection({
    super.key,
    required this.expanded,
    required this.child,
  });

  final bool expanded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: expanded ? 1 : 0),
      duration: AppMotion.expand,
      curve: AppMotion.expandCurve,
      child: child,
      builder: (context, t, child) {
        if (t == 0) return const SizedBox(width: double.infinity);
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: t,
            // Content fades faster than the height moves: it is nearly gone
            // before a fold gets short, and appears once an unfold has
            // room, so folding sections never show a squashed stack.
            child: Opacity(opacity: t * t * t, child: child),
          ),
        );
      },
    );
  }
}
