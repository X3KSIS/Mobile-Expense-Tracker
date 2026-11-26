import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/pressable.dart';

/// "2 payments from your messages", tapping through to review them.
class DetectedPaymentsBanner extends StatelessWidget {
  const DetectedPaymentsBanner({
    super.key,
    required this.count,
    required this.onReview,
  });

  final int count;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(Dimens.radiusTile);
    final label = '$count payment${count == 1 ? '' : 's'} from your messages';
    return Semantics(
      button: true,
      label: '$label. Review',
      excludeSemantics: true,
      child: Pressable(
        child: Material(
          color: colors.accentSoft,
          borderRadius: radius,
          child: InkWell(
            onTap: onReview,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.gapL,
                vertical: Dimens.gapM,
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
                      label,
                      style: context.text.listTitle.copyWith(
                        color: colors.accentText,
                      ),
                    ),
                  ),
                  Text(
                    'Review',
                    style: context.text.button.copyWith(
                      color: colors.accentText,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: Dimens.iconSize,
                    color: colors.accentText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
