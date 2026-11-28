import 'package:flutter/material.dart';

import '../../../domain/models/bill.dart';
import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/category_icon.dart';
import '../../core/ui/category_tile.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/status_badge.dart';
import '../view_models/bills_view_model.dart';
import 'bill_form_sheet.dart';
import 'bill_row.dart';

/// What can be done with a bill: mark it paid (recording the expense, or
/// not when it was already added), edit it or delete it.
Future<void> showBillActions(
  BuildContext context, {
  required BillsViewModel viewModel,
  required Bill bill,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => _BillActions(viewModel: viewModel, bill: bill),
);

class _BillActions extends StatefulWidget {
  const _BillActions({required this.viewModel, required this.bill});

  final BillsViewModel viewModel;
  final Bill bill;

  @override
  State<_BillActions> createState() => _BillActionsState();
}

class _BillActionsState extends State<_BillActions> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.markPaid.addListener(_onDone);
    widget.viewModel.delete.addListener(_onDone);
  }

  @override
  void dispose() {
    widget.viewModel.markPaid.removeListener(_onDone);
    widget.viewModel.delete.removeListener(_onDone);
    super.dispose();
  }

  void _onDone() {
    final vm = widget.viewModel;
    if (!mounted) return;
    final command = vm.markPaid.result != null ? vm.markPaid : vm.delete;
    if (command.running || command.result == null) {
      setState(() {});
      return;
    }
    final bill = widget.bill;
    final next = formatDayMonth(bill.advanced().nextDue);
    final text = !command.completed
        ? "Couldn't update the bill. Please try again."
        : command == vm.markPaid
        ? '${bill.name} marked paid. Next due $next.'
        : 'Bill deleted';
    command.clearResult();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _edit() async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await showBillForm(
      navigator.context,
      viewModel: widget.viewModel,
      bill: widget.bill,
    );
  }

  Future<void> _confirmDelete() async {
    final bill = widget.bill;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${bill.name}?'),
        content: const Text(
          'Its reminders stop. Payments already recorded stay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.textPrimary,
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) widget.viewModel.delete.execute(bill.id);
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final bill = widget.bill;
    final busy = vm.markPaid.running || vm.delete.running;
    final next = formatDayMonth(bill.advanced().nextDue);
    return SafeArea(
      child: SingleChildScrollView(
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
            _Summary(bill: bill, now: vm.now),
            const SizedBox(height: Dimens.sectionGap),
            PrimaryButton(
              label: 'Mark as paid',
              loading: vm.markPaid.running,
              onPressed: busy
                  ? null
                  : () => vm.markPaid.execute((bill: bill, record: true)),
            ),
            const SizedBox(height: Dimens.gapS),
            Text(
              'Adds a ${formatZmw(bill.amount)} expense today and moves the '
              'bill to $next.',
              style: context.text.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimens.gapM),
            OutlinedButton(
              onPressed: busy
                  ? null
                  : () => vm.markPaid.execute((bill: bill, record: false)),
              child: const Text('Paid, and I already added it'),
            ),
            const SizedBox(height: Dimens.gapS),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: busy ? null : _edit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: busy ? null : _confirmDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.bill, required this.now});

  final Bill bill;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final tone = billTone(bill.status(now));
    final colors = context.colors;
    return Row(
      children: [
        IconTile(icon: CategoryIcons.resolve(bill.categoryIcon)),
        const SizedBox(width: Dimens.gapM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(bill.name, style: context.text.sectionTitle),
              const SizedBox(height: 2),
              Text(
                '${describeDue(bill, now)} · ${cadenceName(bill.cadence)} · '
                '${bill.categoryName}',
                style: context.text.caption.copyWith(
                  color: tone == null
                      ? colors.textSecondary
                      : tone.strong(colors),
                ),
              ),
            ],
          ),
        ),
        Text(formatZmw(bill.amount), style: context.text.statValue),
      ],
    );
  }
}
