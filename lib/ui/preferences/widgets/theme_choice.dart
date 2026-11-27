import 'package:flutter/material.dart';

import '../../../domain/models/theme_preference.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/motion.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/pressable.dart';

/// Three tiles: follow the phone, always light, always dark. The selected
/// one is navy; switching blends the whole app over `AppMotion.theme`.
class ThemeChoice extends StatelessWidget {
  const ThemeChoice({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ThemePreference selected;
  final ValueChanged<ThemePreference> onChanged;

  static const _options = [
    (ThemePreference.system, Icons.brightness_auto_outlined, 'System'),
    (ThemePreference.light, Icons.light_mode_outlined, 'Light'),
    (ThemePreference.dark, Icons.dark_mode_outlined, 'Dark'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, (value, icon, label)) in _options.indexed) ...[
          if (i > 0) const SizedBox(width: Dimens.gapS),
          Expanded(
            child: _ThemeTile(
              icon: icon,
              label: label,
              selected: value == selected,
              onTap: () => onChanged(value),
            ),
          ),
        ],
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = selected ? colors.textOnNavy : colors.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label theme',
      excludeSemantics: true,
      child: Pressable(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.medium,
            curve: AppMotion.move,
            padding: const EdgeInsets.symmetric(vertical: Dimens.gapM),
            decoration: BoxDecoration(
              color: selected ? colors.navy : colors.surfaceMuted,
              borderRadius: BorderRadius.circular(Dimens.radiusInput),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: Dimens.iconSize, color: foreground),
                const SizedBox(height: Dimens.gapXs),
                Text(
                  label,
                  style: context.text.button.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
