import 'package:flutter/material.dart';

import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/list_card.dart';
import '../view_models/wallets_view_model.dart';

/// Recent transfers: "Zanaco → MTN MoMo", the date and note, and the
/// amount.
class TransferList extends StatelessWidget {
  const TransferList({super.key, required this.entries});

  final List<TransferEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return ListCard(
        children: [
          Padding(
            padding: const EdgeInsets.all(Dimens.cardPadding),
            child: Text(
              'No transfers yet. Use Move money when you withdraw cash or '
              'top up mobile money.',
              style: context.text.body.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    return ListCard(
      children: [for (final entry in entries) _TransferRow(entry: entry)],
    );
  }
}

class _TransferRow extends StatelessWidget {
  const _TransferRow({required this.entry});

  final TransferEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = entry.transfer;
    final note = t.note;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.all(Dimens.gapL),
        child: Row(
          children: [
            Container(
              width: Dimens.iconTileSize,
              height: Dimens.iconTileSize,
              decoration: BoxDecoration(
                color: colors.surfaceMuted,
                borderRadius: BorderRadius.circular(Dimens.radiusIconTile),
              ),
              child: Icon(
                Icons.swap_horiz_rounded,
                size: Dimens.iconSize,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: Dimens.gapM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.from} → ${entry.to}',
                    style: context.text.listTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [formatActivityTime(t.date), ?note].join(' · '),
                    style: context.text.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Dimens.gapM),
            Text(formatZmw(t.amount), style: context.text.listAmount),
          ],
        ),
      ),
    );
  }
}
