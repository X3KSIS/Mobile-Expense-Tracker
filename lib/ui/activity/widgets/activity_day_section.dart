import 'package:flutter/material.dart';

import '../../../domain/models/transaction.dart';
import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/animated_number.dart';
import '../../core/ui/expandable_section.dart';
import '../../core/ui/list_card.dart';
import '../../core/ui/transaction_row.dart';
import '../view_models/activity_view_model.dart';

/// A day heading with the day's net, then its transactions in a card,
/// followed by the gap before the next day.
///
/// With [isVisible], rows that don't match fold away (and unfold again)
/// in place, the remaining rows stay put, the day's net rolls to its new
/// figure, and a day with nothing left folds away entirely. Without it,
/// every transaction shows.
class ActivityDaySection extends StatelessWidget {
  const ActivityDaySection({
    super.key,
    required this.day,
    required this.onTransactionTap,
    this.isVisible,
    this.now,
  });

  final ActivityDay day;
  final ValueChanged<Transaction> onTransactionTap;
  final bool Function(Transaction transaction)? isVisible;
  final DateTime? now;

  bool _shows(Transaction t) => isVisible?.call(t) ?? true;

  @override
  Widget build(BuildContext context) {
    final shown = day.transactions.where(_shows).toList();
    final net = shown.fold<double>(0, (sum, t) => sum + t.signedAmount);
    return ExpandableSection(
      expanded: shown.isNotEmpty,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Dimens.sectionGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Heading(day: day.day, net: net, now: now),
            const SizedBox(height: Dimens.gapS),
            _Card(
              transactions: day.transactions,
              shows: _shows,
              now: now,
              onTransactionTap: onTransactionTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.day, required this.net, required this.now});

  final DateTime day;
  final double net;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimens.gapXs),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                formatDayHeading(day, now: now).toUpperCase(),
                style: context.text.overline,
              ),
            ),
          ),
          AnimatedNumber(
            value: net,
            builder: (context, value) => Text(
              formatZmwSigned(value, isIncome: value >= 0),
              style: context.text.caption.copyWith(
                color: value > 0
                    ? context.colors.success
                    : context.colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The day's card. Each row folds in or out on its own; a row's divider
/// shows only when a visible row sits above it.
class _Card extends StatelessWidget {
  const _Card({
    required this.transactions,
    required this.shows,
    required this.now,
    required this.onTransactionTap,
  });

  final List<Transaction> transactions;
  final bool Function(Transaction) shows;
  final DateTime? now;
  final ValueChanged<Transaction> onTransactionTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Dimens.radiusList);
    var visibleAbove = false;
    final rows = <Widget>[];
    for (final t in transactions) {
      final visible = shows(t);
      rows.add(
        ExpandableSection(
          key: ValueKey(t.id),
          expanded: visible,
          child: Column(
            children: [
              ExpandableSection(
                expanded: visibleAbove,
                child: const Divider(
                  indent: ListCard.dividerIndent,
                  endIndent: Dimens.gapL,
                ),
              ),
              TransactionRow(
                transaction: t,
                now: now,
                onTap: () => onTransactionTap(t),
              ),
            ],
          ),
        ),
      );
      visibleAbove = visibleAbove || visible;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: radius,
        border: Border.all(color: context.colors.border),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: Column(children: rows),
        ),
      ),
    );
  }
}
