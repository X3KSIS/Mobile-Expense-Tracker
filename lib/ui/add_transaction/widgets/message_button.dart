import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/pressable.dart';

/// A soft coral bar inviting the user to paste a MoMo or bank SMS, the
/// quickest way to fill the form.
class MessageButton extends StatelessWidget {
  const MessageButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(Dimens.radiusTile);
    return Semantics(
      button: true,
      label: 'Fill from a MoMo or bank message',
      excludeSemantics: true,
      child: Pressable(
        child: Material(
          color: colors.accentSoft,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: Dimens.minTouchTarget + 4,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.gapL,
                  vertical: Dimens.gapS,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sms_outlined,
                      size: Dimens.iconSize,
                      color: colors.accentText,
                    ),
                    const SizedBox(width: Dimens.gapM),
                    Expanded(
                      child: Text(
                        'Paste a MoMo or bank SMS',
                        style: context.text.button.copyWith(
                          color: colors.accentText,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: colors.accentText),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
