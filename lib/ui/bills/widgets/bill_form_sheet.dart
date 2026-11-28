import 'package:flutter/material.dart';

import '../../../domain/models/bill.dart';
import '../../../domain/models/transaction_category.dart';
import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/category_picker.dart';
import '../../core/ui/choice_pill.dart';
import '../../core/ui/labeled_text_field.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/segmented_toggle.dart';
import '../../core/ui/wallet_tile.dart';
import '../view_models/bills_view_model.dart';
import 'bill_row.dart';

/// Adds a bill, or edits [bill]. [draft] fills a new one in, e.g. from a
/// regular payment the app spotted.
Future<void> showBillForm(
  BuildContext context, {
  required BillsViewModel viewModel,
  Bill? bill,
  BillDraft? draft,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => _BillForm(viewModel: viewModel, bill: bill, draft: draft),
);

class _BillForm extends StatefulWidget {
  const _BillForm({required this.viewModel, this.bill, this.draft});

  final BillsViewModel viewModel;
  final Bill? bill;
  final BillDraft? draft;

  @override
  State<_BillForm> createState() => _BillFormState();
}

class _BillFormState extends State<_BillForm> {
  final _formKey = GlobalKey<FormState>();
  late final Bill? _bill = widget.bill;
  late final TextEditingController _name = TextEditingController(
    text: _bill?.name ?? widget.draft?.name ?? '',
  );
  late final TextEditingController _amount = TextEditingController(
    text: switch (_bill?.amount ?? widget.draft?.amount) {
      final amount? => formatWhole(amount),
      null => '',
    },
  );
  late TransactionCategory? _category = _bill != null
      ? widget.viewModel.categoryFor(_bill)
      : widget.draft?.category ?? widget.viewModel.categories.firstOrNull;
  late String? _walletId =
      _bill?.walletId ?? widget.viewModel.wallets.firstOrNull?.id;
  late BillCadence _cadence =
      _bill?.cadence ?? widget.draft?.cadence ?? BillCadence.monthly;
  late DateTime _due =
      _bill?.nextDue ??
      widget.draft?.nextDue ??
      DateTime(
        widget.viewModel.now.year,
        widget.viewModel.now.month,
        widget.viewModel.now.day,
      );

  @override
  void initState() {
    super.initState();
    widget.viewModel.save.addListener(_onSaved);
  }

  @override
  void dispose() {
    widget.viewModel.save.removeListener(_onSaved);
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _onSaved() {
    final save = widget.viewModel.save;
    if (!mounted || save.running || save.result == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final text = save.completed
        ? (_bill == null ? 'Bill added' : 'Bill updated')
        : "Couldn't save the bill. Please try again.";
    if (save.completed) Navigator.of(context).pop();
    save.clearResult();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickDue() async {
    final now = widget.viewModel.now;
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Next due',
    );
    if (picked != null) setState(() => _due = picked);
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.viewModel.save.execute((
      bill: _bill,
      name: _name.text,
      amount: _amount.text,
      category: _category,
      walletId: _walletId,
      cadence: _cadence,
      nextDue: _due,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Dimens.screenPadding,
            0,
            Dimens.screenPadding,
            Dimens.screenPadding,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _bill == null ? 'New bill' : 'Edit bill',
                  style: context.text.sectionTitle,
                ),
                const SizedBox(height: Dimens.gapL),
                ..._fields(),
                const SizedBox(height: Dimens.gapL),
                Text('Category', style: context.text.fieldLabel),
                const SizedBox(height: Dimens.gapS),
                CategoryPicker(
                  categories: viewModel.categories,
                  selected: _category,
                  onSelected: (c) => setState(() => _category = c),
                ),
                if (viewModel.wallets.isNotEmpty) ...[
                  const SizedBox(height: Dimens.gapL),
                  Text('Paid from', style: context.text.fieldLabel),
                  const SizedBox(height: Dimens.gapS),
                  WalletPicker(
                    wallets: viewModel.wallets,
                    selectedId: _walletId,
                    onSelected: (w) => setState(() => _walletId = w.id),
                  ),
                ],
                const SizedBox(height: Dimens.sectionGap + 4),
                PrimaryButton(
                  label: _bill == null ? 'Add bill' : 'Save bill',
                  loading: viewModel.save.running,
                  onPressed: _category == null ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _fields() => [
    LabeledTextField(
      label: 'Name',
      controller: _name,
      hint: 'e.g. Rent, DStv, School fees',
      prefixIcon: Icons.receipt_long_outlined,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      validator: widget.viewModel.validateName,
    ),
    const SizedBox(height: Dimens.gapL),
    LabeledTextField(
      label: 'Amount (ZMW)',
      controller: _amount,
      hint: 'e.g. 3,500',
      prefixIcon: Icons.payments_outlined,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: widget.viewModel.validateAmount,
    ),
    const SizedBox(height: Dimens.gapL),
    Text('How often', style: context.text.fieldLabel),
    const SizedBox(height: Dimens.gapS),
    SegmentedToggle<BillCadence>(
      options: [
        for (final c in BillCadence.values)
          ToggleOption(value: c, label: cadenceName(c)),
      ],
      selected: _cadence,
      onChanged: (c) => setState(() => _cadence = c),
    ),
    const SizedBox(height: Dimens.gapL),
    Text('Next due', style: context.text.fieldLabel),
    const SizedBox(height: Dimens.gapS),
    Align(
      alignment: Alignment.centerLeft,
      child: ChoicePill(
        icon: Icons.calendar_today_outlined,
        label: formatPickerDate(_due, now: widget.viewModel.now),
        semanticLabel:
            'Next due ${formatPickerDate(_due, now: widget.viewModel.now)}. '
            'Change date',
        onTap: _pickDue,
      ),
    ),
  ];
}
