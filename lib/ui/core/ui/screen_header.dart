import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../themes/dimens.dart';
import 'gradient_text.dart';
import 'header_icon_button.dart';

/// Header for pushed screens: a 46px back button, the screen title and an
/// optional trailing action.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
  });

  final String title;
  final Widget? trailing;

  /// Defaults to popping the current route.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HeaderIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Back',
          onPressed: onBack ?? () => context.pop(),
        ),
        const SizedBox(width: Dimens.gapM + 2),
        Expanded(
          child: Semantics(
            header: true,
            child: GradientText(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
