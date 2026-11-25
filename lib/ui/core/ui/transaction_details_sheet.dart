import 'package:flutter/material.dart';

import '../../../domain/models/transaction.dart';
import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/theme.dart';
import 'category_tile.dart';

/// Opens a bottom sheet with [transaction]'s details and a Delete button.
/// [onDelete] runs after the user confirms.
Future<void> showTransactionDetails(
  BuildContext context, {
  required Transaction transaction,
  required VoidCallback onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (sheetContext) => TransactionDetailsSheet(
      transaction: transaction,
      onDelete: () {
        Navigator.of(sheetContext).pop();
        onDelete();
      },
    ),
  );
}

/// Details of one transaction, shown in a bottom sheet.
class TransactionDetailsSheet extends StatelessWidget {
  const TransactionDetailsSheet({
    super.key,
    required this.transaction,
    required this.onDelete,
  });

  final Transaction transaction;
  final VoidCallback onDelete;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text(
          '"${transaction.title}" will be removed from your activity, '
          'budgets and reports.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final note = transaction.note;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Dimens.screenPadding,
          0,
          Dimens.screenPadding,
          Dimens.screenPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Summary(transaction: transaction),
            const SizedBox(height: Dimens.sectionGap),
            _DetailRow(label: 'Category', value: transaction.categoryName),
            _DetailRow(
              label: 'Date',
              value: formatFullDateTime(transaction.date),
            ),
            _DetailRow(
              label: 'Type',
              value: transaction.isIncome ? 'Income' : 'Expense',
            ),
            if (note != null) _DetailRow(label: 'Note', value: note),
            const SizedBox(height: Dimens.sectionGap),
            OutlinedButton.icon(
              onPressed: () => _confirmDelete(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentText,
                minimumSize: const Size.fromHeight(Dimens.buttonHeight + 4),
                shape: const StadiumBorder(),
              ),
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: Dimens.iconSizeSmall + 2,
              ),
              label: const Text('Delete transaction'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CategoryTile(
          icon: transaction.categoryIcon,
          color: transaction.categoryColor,
          size: Dimens.quickActionSize + 4,
        ),
        const SizedBox(height: Dimens.gapM),
        Text(
          transaction.title,
          style: AppTypography.sectionTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Dimens.gapXs),
        Text(
          formatZmwSigned(transaction.amount, isIncome: transaction.isIncome),
          style: AppTypography.amountMedium.copyWith(
            color: transaction.isIncome
                ? AppColors.success
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Dimens.gapM),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 92, child: Text(label, style: AppTypography.label)),
            Expanded(
              child: Text(
                value,
                style: AppTypography.body,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
