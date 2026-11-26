import 'package:flutter/widgets.dart';

import 'colors.dart';

/// One colour point in a [MeshGradient]: a soft radial glow at [center].
class MeshPoint {
  const MeshPoint({
    required this.center,
    required this.color,
    this.radius = 0.9,
  });

  final Alignment center;
  final Color color;

  /// Radius as a fraction of the shorter side of the box.
  final double radius;
}

/// A base 135° linear gradient with radial colour points layered on top.
/// Flutter has no native mesh gradient; overlapping soft glows give the
/// same organic, multi-point blend.
class MeshGradient {
  const MeshGradient({required this.base, required this.points});

  final LinearGradient base;
  final List<MeshPoint> points;
}

/// Gradient rules (see CLAUDE.md):
/// 1. Hues stay within 60° of each other: neighbouring hues only.
/// 2. Direction is 135° (top-left to bottom-right).
/// 3. Use mesh gradients for organic multi-point blends on large surfaces.
/// 4. Gradient text is for headlines only; other text stays solid.
///
/// Hues were checked when the stops were chosen, in both palettes: navy
/// mesh 198–219°, primary 357–11°, headline 213–218°. White text keeps at
/// least 4.5:1 on every stop of the navy mesh and the primary gradient.
///
/// Read with `context.gradients`; the stops come from the active
/// [AppPalette], so gradients blend along with a theme change.
class AppGradients {
  const AppGradients(this._palette);

  final AppPalette _palette;

  static const Alignment _start = Alignment.topLeft;
  static const Alignment _end = Alignment.bottomRight;

  /// Navy feature cards: deep navy with blue and teal-navy glows.
  MeshGradient get navyMesh => MeshGradient(
    base: LinearGradient(
      begin: _start,
      end: _end,
      colors: [_palette.navy, _palette.navyMeshEnd],
    ),
    points: [
      MeshPoint(
        center: const Alignment(0.9, -1.1),
        color: _palette.navyGlowTop,
        radius: 1.1,
      ),
      MeshPoint(
        center: const Alignment(-1, 1.1),
        color: _palette.navyGlowBottom,
      ),
    ],
  );

  /// Primary action button: accentStrong into a neighbouring crimson.
  LinearGradient get primary => LinearGradient(
    begin: _start,
    end: _end,
    colors: [_palette.accentStrong, _palette.primaryGradientEnd],
  );

  /// Screen headlines: the primary text colour easing into steel blue.
  LinearGradient get headline => LinearGradient(
    begin: _start,
    end: _end,
    colors: [_palette.textPrimary, _palette.headlineGradientEnd],
  );
}

extension AppGradientsContext on BuildContext {
  AppGradients get gradients => AppGradients(colors);
}
