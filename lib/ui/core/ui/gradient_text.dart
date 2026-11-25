import 'package:flutter/material.dart';

import '../themes/gradients.dart';

/// Headline text filled with a gradient. Use for headlines only; body and
/// label text stays solid for readability.
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.style,
    this.gradient = AppGradients.headline,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final Gradient gradient;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: Text(text, style: style, maxLines: maxLines, overflow: overflow),
    );
  }
}
