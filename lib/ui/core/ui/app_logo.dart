import 'package:flutter/material.dart';

/// The coral rounded-square wallet logo. Uses the same PNG as the native
/// splash so the hand-off from native to Flutter splash looks seamless.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96});

  static const String assetPath = 'assets/images/splash_logo.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'ExpenseTrack logo',
    );
  }
}
