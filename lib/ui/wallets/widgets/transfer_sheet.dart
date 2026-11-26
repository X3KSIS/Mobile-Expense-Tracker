import 'package:flutter/material.dart';

import '../../../domain/models/wallet.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/labeled_text_field.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/wallet_tile.dart';
import '../view_models/wallets_view_model.dart';

/// Opens the sheet for moving money between two wallets.
Future<void> showTransferSheet(
  BuildContext context, {
  required WalletsViewModel viewModel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => TransferSheet(viewModel: viewModel),
  );
}

/// From, to, amount and an optional charge (e.g. a MoMo withdrawal fee,
/// recorded as a Fees & charges expense).
class TransferSheet extends StatefulWidget {
  const TransferSheet({super.key, required this.viewModel});

  final WalletsViewModel viewModel;

  @override
  State<TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends State<TransferSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _fee = TextEditingController();
  final _note = TextEditingController();
  late final List<Wallet> _wallets = widget.viewModel.wallets;

  // Defaults: the last wallet (usually the bank) to the first (cash).
  late String _from = _wallets.last.id;
  late String _to = _wallets.first.id;

  @override
  void initState() {
    super.initState();
    widget.viewModel.transfer.addListener(_onSaved);
  }

  @override
  void dispose() {
    widget.viewModel.transfer.removeListener(_onSaved);
    _amount.dispose();
    _fee.dispose();
    _note.dispose();
    super.dispose();
  }

  void _onSaved() {
    final transfer = widget.viewModel.transfer;
    if (!mounted) return;
    if (transfer.completed) {
      transfer.clearResult();
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Money moved')));
    } else {
      setState(() {});
    }
  }

  /// Picking the wallet already on the other side swaps them.
  void _pickFrom(Wallet wallet) => setState(() {
    if (wallet.id == _to) _to = _from;
    _from = wallet.id;
  });

  void _pickTo(Wallet wallet) => setState(() {
    if (wallet.id == _from) _from = _to;
    _to = wallet.id;
  });

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.viewModel.transfer.execute((
      fromWalletId: _from,
      toWalletId: _to,
      amount: _amount.text,
      fee: _fee.text,
      note: _note.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    const amountKeyboard = TextInputType.numberWithOptions(decimal: true);
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
                Text('Move money', style: context.text.sectionTitle),
                const SizedBox(height: Dimens.gapL),
                Text('From', style: context.text.fieldLabel),
                const SizedBox(height: Dimens.gapS),
                WalletPicker(
                  wallets: _wallets,
                  selectedId: _from,
                  onSelected: _pickFrom,
                ),
                const SizedBox(height: Dimens.gapL),
                Text('To', style: context.text.fieldLabel),
                const SizedBox(height: Dimens.gapS),
                WalletPicker(
                  wallets: _wallets,
                  selectedId: _to,
                  onSelected: _pickTo,
                ),
                const SizedBox(height: Dimens.gapL),
                LabeledTextField(
                  label: 'Amount (ZMW)',
                  controller: _amount,
                  hint: 'e.g. 500',
                  prefixIcon: Icons.payments_outlined,
                  keyboardType: amountKeyboard,
                  validator: vm.validateTransferAmount,
                ),
                const SizedBox(height: Dimens.gapL),
                LabeledTextField(
                  label: 'Charge (optional)',
                  controller: _fee,
                  hint: 'e.g. 8.50',
                  helper: 'Withdrawal or transfer fee, saved as an expense',
                  prefixIcon: Icons.receipt_outlined,
                  keyboardType: amountKeyboard,
                  validator: vm.validateFee,
                ),
                const SizedBox(height: Dimens.gapL),
                LabeledTextField(
                  label: 'Note (optional)',
                  controller: _note,
                  hint: 'e.g. Agent withdrawal',
                  prefixIcon: Icons.notes_rounded,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: Dimens.sectionGap + 4),
                PrimaryButton(
                  label: 'Move money',
                  loading: vm.transfer.running,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
