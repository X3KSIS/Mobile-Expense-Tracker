import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/theme.dart';

/// Hero tag shared by the [SearchLauncher] and the full-screen search
/// field, so the box glides from one into the other.
const Object searchHeroTag = 'transaction-search';

/// Height of the search box.
const double searchBoxHeight = 54;

/// The search box's frame: surface fill, 1px border, a search icon and
/// [child] (the hint or the text field) beside it.
class SearchBoxFrame extends StatelessWidget {
  const SearchBoxFrame({super.key, required this.child, this.trailing});

  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: searchBoxHeight,
      padding: const EdgeInsets.only(left: Dimens.gapL, right: Dimens.gapXs),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimens.radiusInput),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: Dimens.iconSize,
            color: colors.textSecondary,
          ),
          const SizedBox(width: Dimens.gapM),
          Expanded(child: child),
          ?trailing,
        ],
      ),
    );
  }
}

/// Looks like a search field; tapping it opens the full-screen search,
/// where the box grows into the real field.
class SearchLauncher extends StatelessWidget {
  const SearchLauncher({super.key, required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: hint,
      excludeSemantics: true,
      child: Hero(
        tag: searchHeroTag,
        flightShuttleBuilder: searchHeroShuttle,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Dimens.radiusInput),
            child: SearchBoxFrame(child: _Hint(hint)),
          ),
        ),
      ),
    );
  }
}

/// What flies between the launcher and the search page: the bare frame,
/// so no text field is ever mid-flight.
Widget searchHeroShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  return const Material(
    type: MaterialType.transparency,
    child: SearchBoxFrame(child: SizedBox.shrink()),
  );
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.text.body.copyWith(color: context.colors.textSecondary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
