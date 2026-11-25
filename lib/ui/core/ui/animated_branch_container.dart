import 'package:flutter/material.dart';

/// Holds the main tabs' navigators and cross-fades between them, with a
/// slight upward slide, instead of switching instantly.
///
/// Every branch stays mounted so its state survives tab switches. The tab
/// being left stays visible only until its fade-out ends, then goes
/// offstage (no painting, no tickers, no hit testing).
class AnimatedBranchContainer extends StatefulWidget {
  const AnimatedBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  static const Duration duration = Duration(milliseconds: 280);

  @override
  State<AnimatedBranchContainer> createState() =>
      _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<AnimatedBranchContainer> {
  /// Branches that are fading out.
  final Set<int> _leaving = {};

  @override
  void didUpdateWidget(covariant AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _leaving
        ..add(oldWidget.currentIndex)
        ..remove(widget.currentIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [for (var i = 0; i < widget.children.length; i++) _branch(i)],
    );
  }

  Widget _branch(int index) {
    final active = index == widget.currentIndex;
    final visible = active || _leaving.contains(index);
    return Positioned.fill(
      child: Offstage(
        offstage: !visible,
        child: TickerMode(
          enabled: visible,
          child: IgnorePointer(
            ignoring: !active,
            child: AnimatedOpacity(
              opacity: active ? 1 : 0,
              duration: AnimatedBranchContainer.duration,
              curve: Curves.easeOutCubic,
              onEnd: () {
                if (!active && mounted) {
                  setState(() => _leaving.remove(index));
                }
              },
              child: AnimatedSlide(
                offset: active ? Offset.zero : const Offset(0, 0.015),
                duration: AnimatedBranchContainer.duration,
                curve: Curves.easeOutCubic,
                child: widget.children[index],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
