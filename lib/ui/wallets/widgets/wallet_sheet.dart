import 'package:flutter/material.dart';

import '../../../domain/models/wallet.dart';
import '../../../utils/currency.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/labeled_text_field.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/segmented_toggle.dart';
import '../view_models/wallets_view_model.dart';

/// Opens the add (when [wallet] is null) or edit wallet sheet.
Future<void> showWalletSheet(
  BuildContext context, {
  required WalletsViewModel viewModel,
  Wallet? wallet,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => WalletSheet(viewModel: viewModel, wallet: wallet),
  );
}

/// Name, kind and opening balance of a wallet.
class WalletSheet extends StatefulWidget {
  const WalletSheet({super.key, required this.viewModel, this.wallet});

  final WalletsViewModel viewModel;
  final Wallet? wallet;

  @override
  State<WalletSheet> createState() => _WalletSheetState();
}

class _WalletSheetState extends State<WalletSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.wallet?.name ?? '',
  );
  late final TextEditingController _opening = TextEditingController(
    text: widget.wallet == null
        ? ''
        : formatWhole(widget.wallet!.openingBalance),
  );
  late WalletKind _kind = widget.wallet?.kind ?? WalletKind.mobileMoney;

  bool get _isEditing => widget.wallet != null;

  @override
  void initState() {
    super.initState();
    widget.viewModel.saveWallet.addListener(_onSaved);
  }

  @override
  void dispose() {
    widget.viewModel.saveWallet.removeListener(_onSaved);
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  void _onSaved() {
    final save = widget.viewModel.saveWallet;
    if (!mounted) return;
    if (save.completed) {
      save.clearResult();
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Wallet updated' : 'Wallet added'),
          ),
        );
    } else {
      setState(() {});
    }
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.viewModel.saveWallet.execute((
      wallet: widget.wallet,
      name: _name.text,
      kind: _kind,
      openingBalance: _opening.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
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
                  _isEditing ? 'Edit wallet' : 'New wallet',
                  style: context.text.sectionTitle,
                ),
                const SizedBox(height: Dimens.gapL),
                SegmentedToggle<WalletKind>(
                  options: const [
                    ToggleOption(value: WalletKind.cash, label: 'Cash'),
                    ToggleOption(
                      value: WalletKind.mobileMoney,
                      label: 'Mobile',
                    ),
                    ToggleOption(value: WalletKind.bank, label: 'Bank'),
                  ],
                  selected: _kind,
                  onChanged: (kind) => setState(() => _kind = kind),
                ),
                const SizedBox(height: Dimens.gapL),
                LabeledTextField(
                  label: 'Name',
                  controller: _name,
                  hint: 'e.g. Airtel Money, FNB',
                  prefixIcon: Icons.edit_outlined,
                  textCapitalization: TextCapitalization.words,
                  validator: vm.validateName,
                ),
                const SizedBox(height: Dimens.gapL),
                LabeledTextField(
                  label: 'Balance when you started (ZMW)',
                  controller: _opening,
                  hint: 'e.g. 500',
                  helper: 'What it held before the transactions you record',
                  prefixIcon: Icons.account_balance_wallet_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: vm.validateOpeningBalance,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: Dimens.sectionGap + 4),
                PrimaryButton(
                  label: _isEditing ? 'Save wallet' : 'Add wallet',
                  loading: vm.saveWallet.running,
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
