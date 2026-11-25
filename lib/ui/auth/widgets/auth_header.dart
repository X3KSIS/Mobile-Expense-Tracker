import 'package:flutter/material.dart';

import '../../core/themes/dimens.dart';
import '../../core/ui/app_logo.dart';

/// Logo, title and subtitle at the top of the sign-in and sign-up screens.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppLogo(size: Dimens.authLogoSize),
        const SizedBox(height: Dimens.sectionGap + 6),
        Semantics(
          header: true,
          child: Text(title, style: textTheme.headlineSmall),
        ),
        const SizedBox(height: Dimens.gapS - 2),
        Text(subtitle, style: textTheme.labelMedium),
      ],
    );
  }
}
