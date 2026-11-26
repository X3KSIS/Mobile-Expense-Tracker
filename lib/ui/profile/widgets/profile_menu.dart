import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';

/// One row in a [ProfileMenuSection].
class ProfileMenuItem {
  const ProfileMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Short value shown on the right, e.g. "ZMW".
  final String? value;

  /// Null makes the row read-only (no chevron, not tappable).
  final VoidCallback? onTap;
}

/// An overline title above a white rounded list of [ProfileMenuItem]s.
class ProfileMenuSection extends StatelessWidget {
  const ProfileMenuSection({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<ProfileMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        indent: Dimens.gapL + Dimens.iconTileSize + Dimens.gapM,
                      ),
                    _MenuRow(item: items[i]),
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

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});

  final ProfileMenuItem item;

  @override
  Widget build(BuildContext context) {
    final subtitle = item.subtitle;
    final value = item.value;
    return InkWell(
      onTap: item.onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Dimens.menuRowMinHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.gapL,
            vertical: Dimens.gapM,
          ),
          child: Row(
            children: [
              _IconTile(icon: item.icon),
              const SizedBox(width: Dimens.gapM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: context.text.listTitle),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: context.text.caption),
                    ],
                  ],
                ),
              ),
              if (value != null)
                Padding(
                  padding: const EdgeInsets.only(left: Dimens.gapS),
                  child: Text(
                    value,
                    style: context.text.body.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
              if (item.onTap != null)
                Padding(
                  padding: EdgeInsets.only(left: Dimens.gapXs),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: Dimens.iconSize,
                    color: context.colors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Dimens.iconTileSize,
      height: Dimens.iconTileSize,
      decoration: BoxDecoration(
        color: context.colors.surfaceMuted,
        borderRadius: BorderRadius.circular(Dimens.radiusIconTile),
      ),
      child: Icon(
        icon,
        size: Dimens.iconSize,
        color: context.colors.textPrimary,
      ),
    );
  }
}
