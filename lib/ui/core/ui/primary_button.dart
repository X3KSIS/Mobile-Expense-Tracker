import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/gradients.dart';
import '../themes/motion.dart';
import '../themes/theme.dart';
import 'pressable.dart';

/// Full-width, fully rounded primary button (height 58) filled with the
/// 135° primary gradient and a soft coral shadow. Shows a spinner and
/// ignores taps while [loading]; greys out when [onPressed] is null.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground = enabled
        ? context.colors.onAccentStrong
        : context.colors.textSecondary;
    return Semantics(
      button: true,
      enabled: enabled && !loading,
      label: loading ? '$label, in progress' : label,
      excludeSemantics: true,
      child: Pressable(
        enabled: enabled && !loading,
        child: Container(
          height: Dimens.primaryButtonHeight,
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            shadows: enabled ? context.shadows.coral : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: BoxDecoration(
                gradient: enabled ? context.gradients.primary : null,
                color: enabled ? null : context.colors.surfaceMuted,
              ),
              child: InkWell(
                onTap: loading ? null : onPressed,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: AppMotion.short,
                    child: loading
                        ? SizedBox.square(
                            key: const ValueKey('spinner'),
                            dimension: Dimens.buttonSpinnerSize,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: foreground,
                            ),
                          )
                        : Text(
                            label,
                            key: ValueKey(label),
                            style: context.text.primaryButton.copyWith(
                              color: foreground,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
