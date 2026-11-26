import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/motion.dart';

/// Sweeps a soft highlight across its [child] skeleton blocks at 135°.
/// Stops animating when the platform asks for reduced motion.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.shimmer,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      liveRegion: true,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          child: widget.child,
          builder: (context, child) {
            // Slide the highlight band from off the top-left to off the
            // bottom-right.
            final shift = _controller.value * 3 - 1.5;
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment(-1 + shift, -1 + shift),
                end: Alignment(1 + shift, 1 + shift),
                colors: [
                  context.colors.surfaceMuted,
                  context.colors.skeletonHighlight,
                  context.colors.surfaceMuted,
                ],
                stops: const [0.35, 0.5, 0.65],
              ).createShader(bounds),
              child: child,
            );
          },
        ),
      ),
    );
  }
}

/// A muted placeholder block. Wrap a group of these in one [Shimmer].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = Dimens.radiusIconTile,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surfaceMuted,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A line of placeholder text.
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, this.width, this.height = 12});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) =>
      SkeletonBox(width: width, height: height, radius: Dimens.radiusFull);
}

/// White rounded card that holds skeleton content, matching real cards.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    required this.child,
    this.radius = Dimens.radiusList,
    this.padding = const EdgeInsets.all(Dimens.gapL),
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: context.colors.border),
      ),
      child: child,
    );
  }
}

/// Placeholder for a transaction-style row: icon tile, two lines, amount.
class SkeletonListRow extends StatelessWidget {
  const SkeletonListRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: Dimens.gapS),
      child: Row(
        children: [
          SkeletonBox(width: Dimens.iconTileSize, height: Dimens.iconTileSize),
          SizedBox(width: Dimens.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 120, height: 13),
                SizedBox(height: Dimens.gapS),
                SkeletonLine(width: 80, height: 10),
              ],
            ),
          ),
          SizedBox(width: Dimens.gapM),
          SkeletonLine(width: 64, height: 13),
        ],
      ),
    );
  }
}

/// Header placeholder used by the tab skeletons: a title and subtitle.
class SkeletonHeader extends StatelessWidget {
  const SkeletonHeader({super.key, this.trailing = false});

  /// Adds a 46px button placeholder on the right.
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLine(width: 150, height: 24),
              SizedBox(height: Dimens.gapS),
              SkeletonLine(width: 110, height: 12),
            ],
          ),
        ),
        if (trailing)
          const SkeletonBox(
            width: Dimens.headerButtonSize,
            height: Dimens.headerButtonSize,
            radius: Dimens.radiusButton,
          ),
      ],
    );
  }
}

/// A [SkeletonCard] containing [rows] transaction-style rows.
class SkeletonListCard extends StatelessWidget {
  const SkeletonListCard({super.key, this.rows = 4});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      child: Column(
        children: [for (var i = 0; i < rows; i++) const SkeletonListRow()],
      ),
    );
  }
}
