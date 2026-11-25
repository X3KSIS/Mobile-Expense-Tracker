import 'package:flutter/material.dart';

import '../../core/themes/dimens.dart';
import '../../core/ui/app_logo.dart';
import '../../core/ui/gradient_text.dart';

/// Centred logo, title and subtitle at the top of the sign-in and sign-up
/// screens.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const AppLogo(size: Dimens.authLogoSize),
        const SizedBox(height: Dimens.sectionGap + 6),
        Semantics(
          header: true,
          child: GradientText(
            title,
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: Dimens.gapS - 2),
        Text(
          subtitle,
          style: textTheme.labelMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
