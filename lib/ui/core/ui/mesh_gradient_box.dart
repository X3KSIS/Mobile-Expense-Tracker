import 'package:flutter/material.dart';

import '../themes/gradients.dart';

/// Paints a [MeshGradient] behind [child], clipped to [borderRadius].
class MeshGradientBox extends StatelessWidget {
  const MeshGradientBox({
    super.key,
    required this.mesh,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.boxShadow,
    this.padding,
  });

  final MeshGradient mesh;
  final Widget child;
  final BorderRadius borderRadius;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: boxShadow,
        gradient: mesh.base,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            for (final point in mesh.points)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: point.center,
                      radius: point.radius,
                      colors: [point.color, point.color.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            Padding(padding: padding ?? EdgeInsets.zero, child: child),
          ],
        ),
      ),
    );
  }
}
