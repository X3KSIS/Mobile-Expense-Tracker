import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';

/// An overline title above a white rounded card, with dividers between
/// [children]. Matches the Profile menu sections.
class PreferenceSection extends StatelessWidget {
  const PreferenceSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: Dimens.gapXs),
          child: Semantics(
            header: true,
            child: Text(title.toUpperCase(), style: context.text.overline),
          ),
        ),
        const SizedBox(height: Dimens.gapS + 2),
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(Dimens.radiusList),
            border: Border.all(color: context.colors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Dimens.radiusList),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, child) in children.indexed) ...[
                    if (i > 0) const Divider(indent: Dimens.gapL),
                    child,
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
