import 'package:flutter/material.dart';

import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/fade_switcher.dart';

/// "‹ November 2026 ›" control that scopes every report below it.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.onBack,
    required this.onForward,
  });

  final DateTime month;

  /// Null disables the button.
  final VoidCallback? onBack;
  final VoidCallback? onForward;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimens.gapXs),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(Dimens.radiusFull),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous month',
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: FadeSwitcher(
                alignment: Alignment.center,
                child: Text(
                  formatMonthYear(month),
                  key: ValueKey(month),
                  style: context.text.listTitle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next month',
            onPressed: onForward,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
