import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../themes/motion.dart';

/// Press feedback for buttons: [child] shrinks to [AppMotion.pressScale]
/// while a finger is down, then springs back to full size when released.
///
/// It only listens to raw pointer events, so the child's own gesture
/// handling (an [InkWell] ripple, for example) works as usual. A quick tap
/// still shows the full shrink before the spring back.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.enabled = true});

  final Widget child;

  /// When false, presses do nothing, matching a disabled button.
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  bool _pressed = false;
  bool _shrinking = false;

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  void _onDown(PointerDownEvent event) {
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) return;
    _pressed = true;
    _shrinking = true;
    _scale
        .animateTo(
          AppMotion.pressScale,
          duration: AppMotion.pressDown,
          curve: Curves.easeOut,
        )
        .whenCompleteOrCancel(() {
          _shrinking = false;
          if (!_pressed && mounted) _springBack();
        });
  }

  void _onUp(PointerEvent event) {
    if (!_pressed) return;
    _pressed = false;
    if (!_shrinking) _springBack();
  }

  void _springBack() {
    _scale.animateWith(
      SpringSimulation(AppMotion.pressSpring, _scale.value, 1, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onDown,
      onPointerUp: _onUp,
      onPointerCancel: _onUp,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
