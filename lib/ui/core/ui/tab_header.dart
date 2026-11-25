import 'package:flutter/material.dart';

import '../themes/dimens.dart';

/// Title row at the top of the main tab screens, with an optional subtitle
/// and trailing action.
class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sub = subtitle;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: textTheme.headlineSmall),
              ),
              if (sub != null) ...[
                const SizedBox(height: 2),
                Text(sub, style: textTheme.labelMedium),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: Dimens.gapM),
          trailing!,
        ],
      ],
    );
  }
}
