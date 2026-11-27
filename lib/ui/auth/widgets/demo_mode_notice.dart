import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/status_badge.dart';

/// Warns that the app was built without Supabase settings, so sign-in is
/// the demo account and nothing is saved online.
class DemoModeNotice extends StatelessWidget {
  const DemoModeNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(Dimens.gapM),
        decoration: BoxDecoration(
          color: colors.warningSoft,
          borderRadius: BorderRadius.circular(Dimens.radiusInput),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: StatusMark(tone: StatusTone.warning),
            ),
            const SizedBox(width: Dimens.gapS),
            Expanded(
              child: Text(
                'Demo mode: not connected to Supabase. Any email signs in '
                'and data stays on this phone. Run with '
                '--dart-define-from-file=supabase.json to sign in for real.',
                style: context.text.caption.copyWith(color: colors.warning),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
