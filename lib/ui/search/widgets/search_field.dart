import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/motion.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/search_box.dart';

/// The search page's text field, inside the same frame as the launcher it
/// grew from. The hero flight only mounts the field once the box has
/// settled, so autofocus raises the keyboard after the movement rather
/// than during it.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onCleared,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Hero(
      tag: searchHeroTag,
      flightShuttleBuilder: searchHeroShuttle,
      child: Material(
        type: MaterialType.transparency,
        child: SearchBoxFrame(
          trailing: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => AnimatedSwitcher(
              duration: AppMotion.short,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: controller.text.isEmpty
                  ? const SizedBox(
                      key: ValueKey('empty'),
                      width: Dimens.minTouchTarget,
                    )
                  : IconButton(
                      key: const ValueKey('clear'),
                      tooltip: 'Clear search',
                      onPressed: onCleared,
                      icon: Icon(
                        Icons.close_rounded,
                        size: Dimens.iconSizeSmall + 2,
                        color: colors.textSecondary,
                      ),
                    ),
            ),
          ),
          child: TextField(
            controller: controller,
            autofocus: true,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            style: context.text.body,
            decoration: InputDecoration.collapsed(
              hintText: 'Search transactions',
              hintStyle: context.text.body.copyWith(
                color: colors.textSecondary,
              ),
            ).copyWith(filled: false),
          ),
        ),
      ),
    );
  }
}
