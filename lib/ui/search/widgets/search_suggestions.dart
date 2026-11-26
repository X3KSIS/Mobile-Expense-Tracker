import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/pressable.dart';

/// Shown before anything is typed: a hint and the most used categories,
/// one tap away from a search.
class SearchSuggestions extends StatelessWidget {
  const SearchSuggestions({
    super.key,
    required this.categories,
    required this.onSelected,
  });

  final List<String> categories;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: Dimens.screenPadding),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Text(
          'Search by title, category or note.',
          style: context.text.body.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        if (categories.isNotEmpty) ...[
          const SizedBox(height: Dimens.sectionGap),
          Text('POPULAR CATEGORIES', style: context.text.overline),
          const SizedBox(height: Dimens.gapM),
          Wrap(
            spacing: Dimens.gapS,
            runSpacing: Dimens.gapS,
            children: [
              for (final name in categories)
                Pressable(
                  child: ActionChip(
                    label: Text(name),
                    onPressed: () => onSelected(name),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
