import 'package:flutter/material.dart';

import '../../../domain/models/transaction.dart';
import '../../activity/view_models/activity_view_model.dart';
import '../../activity/widgets/activity_day_section.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';

/// Matching transactions grouped by day, under a result count.
class SearchResults extends StatelessWidget {
  const SearchResults({
    super.key,
    required this.days,
    required this.count,
    required this.onTransactionTap,
  });

  final List<ActivityDay> days;
  final int count;
  final ValueChanged<Transaction> onTransactionTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        Dimens.screenPadding,
        0,
        Dimens.screenPadding,
        Dimens.screenPadding + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            '$count result${count == 1 ? '' : 's'}',
            style: context.text.caption,
          ),
        ),
        const SizedBox(height: Dimens.gapM),
        for (final day in days)
          ActivityDaySection(
            key: ValueKey(day.day),
            day: day,
            onTransactionTap: onTransactionTap,
          ),
      ],
    );
  }
}
