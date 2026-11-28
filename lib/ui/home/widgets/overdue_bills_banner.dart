import 'package:flutter/material.dart';

import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/pressable.dart';
import '../../core/ui/status_badge.dart';

/// "2 bills overdue · ZMW 3,950.00", opening Bills to mark them paid.
class OverdueBillsBanner extends StatelessWidget {
  const OverdueBillsBanner({
    super.key,
    required this.count,
    required this.total,
    required this.onOpen,
  });

  final int count;
  final double total;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(Dimens.radiusTile);
    final label = '$count bill${count == 1 ? '' : 's'} overdue';
    return Semantics(
      button: true,
      label: '$label, ${formatZmw(total)}. Open bills',
      excludeSemantics: true,
      child: Pressable(
        child: Material(
          color: colors.errorSoft,
          borderRadius: radius,
          child: InkWell(
            onTap: onOpen,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.gapL,
                vertical: Dimens.gapM,
              ),
              child: Row(
                children: [
                  const StatusMark(tone: StatusTone.danger, size: 18),
                  const SizedBox(width: Dimens.gapM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: context.text.listTitle.copyWith(
                            color: colors.error,
                          ),
                        ),
                        Text(
                          '${formatZmw(total)} to pay',
                          style: context.text.caption.copyWith(
                            color: colors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Pay',
                    style: context.text.button.copyWith(color: colors.error),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: Dimens.iconSize,
                    color: colors.error,
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
