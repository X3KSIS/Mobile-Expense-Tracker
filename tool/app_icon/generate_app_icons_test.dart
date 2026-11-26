// Generates the launcher icons for every platform from one vector drawing
// of the coral wallet logo used on the splash screen.
//
// Run from the project root:
//   flutter test tool/app_icon/generate_app_icons_test.dart
//
// It lives outside test/ so the normal test run never rewrites the icons.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// accent, the same coral as the splash logo.
const Color coral = Color(0xFFFF6B4A);
const Color white = Color(0xFFFFFFFF);

/// How the logo is drawn on the canvas.
enum IconStyle {
  /// Coral rounded square with transparent corners (Android legacy, web,
  /// Windows, macOS).
  rounded,

  /// Coral fills the whole square; the platform masks it (iOS, maskable).
  fullBleed,

  /// Only the white wallet on transparent, shrunk into the adaptive-icon
  /// safe zone (Android adaptive foreground and monochrome).
  glyphOnly,
}

/// Paints the logo in a 384-unit box, matching assets/images/splash_logo.png.
class WalletLogoPainter extends CustomPainter {
  WalletLogoPainter(this.style, {this.glyph = white});

  final IconStyle style;
  final Color glyph;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 384, size.height / 384);
    switch (style) {
      case IconStyle.rounded:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, 384, 384),
            const Radius.circular(84),
          ),
          Paint()..color = coral,
        );
      case IconStyle.fullBleed:
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, 384, 384),
          Paint()..color = coral,
        );
      case IconStyle.glyphOnly:
        // Adaptive icons are 108dp with a 66dp safe circle; the wallet
        // (about 230 units wide) is scaled to sit well inside it.
        canvas
          ..translate(192, 192)
          ..scale(0.66)
          ..translate(-192, -192);
    }
    _wallet(canvas);
  }

  void _wallet(Canvas canvas) {
    final stroke = Paint()
      ..color = glyph
      ..style = PaintingStyle.stroke
      ..strokeWidth = 21
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Flap: from the body's top-left, up to a rounded peak, down to the
    // body's top edge.
    canvas.drawPath(
      Path()
        ..moveTo(114, 128)
        ..lineTo(232, 86)
        ..quadraticBezierTo(240, 83, 243, 91)
        ..lineTo(252, 124),
      stroke,
    );

    // Body.
    canvas.drawRRect(
      RRect.fromLTRBR(93, 129, 290, 272, const Radius.circular(30)),
      stroke,
    );

    // Clasp: punched out of the body's right edge, then outlined.
    final clasp = RRect.fromLTRBR(
      213,
      173,
      303,
      229,
      const Radius.circular(28),
    );
    canvas
      ..drawRRect(
        clasp,
        Paint()
          ..color = style == IconStyle.glyphOnly ? Colors.black : coral
          ..blendMode = style == IconStyle.glyphOnly
              ? BlendMode.clear
              : BlendMode.srcOver,
      )
      ..drawRRect(clasp, stroke)
      ..drawCircle(const Offset(247, 201), 11, Paint()..color = glyph);
  }

  @override
  bool shouldRepaint(WalletLogoPainter oldDelegate) => false;
}

Future<Uint8List> render(int px, IconStyle style, {Color glyph = white}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  // saveLayer so the glyph-only clasp can clear the body stroke under it.
  canvas.saveLayer(Rect.fromLTWH(0, 0, px.toDouble(), px.toDouble()), Paint());
  WalletLogoPainter(
    style,
    glyph: glyph,
  ).paint(canvas, Size(px.toDouble(), px.toDouble()));
  canvas.restore();
  final image = await recorder.endRecording().toImage(px, px);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Future<void> write(String path, int px, IconStyle style) async {
  final file = File(path)..createSync(recursive: true);
  file.writeAsBytesSync(await render(px, style));
}

/// A Windows .ico holding PNG-compressed images.
Future<void> writeIco(String path, List<int> sizes) async {
  final images = [for (final s in sizes) await render(s, IconStyle.rounded)];
  final header = BytesBuilder()
    ..add(_u16(0))
    ..add(_u16(1))
    ..add(_u16(sizes.length));
  var offset = 6 + 16 * sizes.length;
  for (var i = 0; i < sizes.length; i++) {
    final s = sizes[i] >= 256 ? 0 : sizes[i];
    header
      ..addByte(s)
      ..addByte(s)
      ..addByte(0)
      ..addByte(0)
      ..add(_u16(1))
      ..add(_u16(32))
      ..add(_u32(images[i].length))
      ..add(_u32(offset));
    offset += images[i].length;
  }
  for (final image in images) {
    header.add(image);
  }
  File(path).writeAsBytesSync(header.toBytes());
}

List<int> _u16(int v) => [v & 0xFF, (v >> 8) & 0xFF];
List<int> _u32(int v) => [
  v & 0xFF,
  (v >> 8) & 0xFF,
  (v >> 16) & 0xFF,
  (v >> 24) & 0xFF,
];

void main() {
  test('generate app icons', () async {
    await generate();
  });
}

Future<void> generate() async {
  final preview = Platform.environment['ICON_PREVIEW'];
  if (preview != null) {
    // ICON_PREVIEW_STYLE=glyphOnly previews the adaptive foreground in navy.
    final style = IconStyle.values.byName(
      Platform.environment['ICON_PREVIEW_STYLE'] ?? 'rounded',
    );
    final glyph = style == IconStyle.glyphOnly
        ? const Color(0xFF1B2A38)
        : white;
    File(preview).writeAsBytesSync(await render(384, style, glyph: glyph));
    return;
  }

  // Android: legacy icons, plus adaptive foreground and monochrome.
  const android = 'android/app/src/main/res';
  const densities = {
    'mdpi': 1.0,
    'hdpi': 1.5,
    'xhdpi': 2.0,
    'xxhdpi': 3.0,
    'xxxhdpi': 4.0,
  };
  for (final MapEntry(key: density, value: scale) in densities.entries) {
    await write(
      '$android/mipmap-$density/ic_launcher.png',
      (48 * scale).round(),
      IconStyle.rounded,
    );
    await write(
      '$android/mipmap-$density/ic_launcher_foreground.png',
      (108 * scale).round(),
      IconStyle.glyphOnly,
    );
  }

  // iOS: every size the asset catalogue lists, no transparency.
  const ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  final iosSizes = RegExp(r'Icon-App-([\d.]+)x[\d.]+@(\d)x\.png');
  for (final entity in Directory(ios).listSync()) {
    final name = entity.uri.pathSegments.last;
    final match = iosSizes.firstMatch(name);
    if (match == null) continue;
    final px = (double.parse(match.group(1)!) * int.parse(match.group(2)!))
        .round();
    await write('$ios/$name', px, IconStyle.fullBleed);
  }

  // macOS.
  const mac = 'macos/Runner/Assets.xcassets/AppIcon.appiconset';
  for (final px in [16, 32, 64, 128, 256, 512, 1024]) {
    await write('$mac/app_icon_$px.png', px, IconStyle.rounded);
  }

  // Web.
  await write('web/favicon.png', 32, IconStyle.rounded);
  await write('web/icons/Icon-192.png', 192, IconStyle.rounded);
  await write('web/icons/Icon-512.png', 512, IconStyle.rounded);
  await write('web/icons/Icon-maskable-192.png', 192, IconStyle.fullBleed);
  await write('web/icons/Icon-maskable-512.png', 512, IconStyle.fullBleed);

  // Windows.
  await writeIco('windows/runner/resources/app_icon.ico', [16, 32, 48, 256]);
}
