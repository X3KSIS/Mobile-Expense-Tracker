import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/transaction.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/category_picker.dart';
import '../../core/ui/fade_switcher.dart';
import '../../core/ui/labeled_text_field.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/screen_header.dart';
import '../../core/ui/segmented_toggle.dart';
import '../../core/ui/wallet_tile.dart';
import '../../core/ui/skeleton_screens.dart';
import '../view_models/add_transaction_view_model.dart';
import 'amount_input.dart';
import 'date_field.dart';

/// Form to record an expense or income.
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, required this.viewModel});

  final AddTransactionViewModel viewModel;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _title = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.save.addListener(_onSaveChanged);
  }

  @override
  void didUpdateWidget(covariant AddTransactionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.save.removeListener(_onSaveChanged);
      widget.viewModel.save.addListener(_onSaveChanged);
    }
  }

  @override
  void dispose() {
    widget.viewModel.save.removeListener(_onSaveChanged);
    _amount.dispose();
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  void _onSaveChanged() {
    final save = widget.viewModel.save;
    if (!mounted || save.running || save.result == null) return;
    final messenger = ScaffoldMessenger.of(context);
    if (save.completed) {
      final kind = widget.viewModel.isExpense ? 'Expense' : 'Income';
      context.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$kind saved')));
    } else {
      save.clearResult();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("Couldn't save. Please try again.")),
        );
    }
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.viewModel.save.execute((
      amount: _amount.text,
      title: _title.text,
      note: _note.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([viewModel, viewModel.save]),
          builder: (context, _) => Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Dimens.screenPadding,
                Dimens.gapL,
                Dimens.screenPadding,
                Dimens.screenPadding,
              ),
              children: [
                const ScreenHeader(title: 'Add transaction'),
                const SizedBox(height: Dimens.sectionGap),
                SegmentedToggle<TransactionType>(
                  options: const [
                    ToggleOption(
                      value: TransactionType.expense,
                      label: 'Expense',
                    ),
                    ToggleOption(
                      value: TransactionType.income,
                      label: 'Income',
                    ),
                  ],
                  selected: viewModel.type,
                  onChanged: viewModel.selectType,
                ),
                const SizedBox(height: Dimens.gapL),
                AmountInput(
                  controller: _amount,
                  validator: viewModel.validateAmount,
                  label: viewModel.isExpense
                      ? 'Amount spent'
                      : 'Amount received',
                ),
                const SizedBox(height: Dimens.sectionGap),
                _CategorySection(viewModel: viewModel),
                if (viewModel.wallets.isNotEmpty) ...[
                  const SizedBox(height: Dimens.sectionGap),
                  _WalletSection(viewModel: viewModel),
                ],
                const SizedBox(height: Dimens.sectionGap),
                _DetailsSection(
                  viewModel: viewModel,
                  title: _title,
                  note: _note,
                ),
                const SizedBox(height: Dimens.sectionGap + 10),
                PrimaryButton(
                  label: viewModel.isExpense ? 'Save expense' : 'Save income',
                  loading: viewModel.save.running,
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

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.viewModel});

  final AddTransactionViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Category', style: textTheme.titleMedium),
        const SizedBox(height: Dimens.gapM),
        FadeSwitcher(child: _categoryBody(textTheme)),
      ],
    );
  }

  Widget _categoryBody(TextTheme textTheme) {
    if (viewModel.loadCategories.running && viewModel.categories.isEmpty) {
      return const CategoryGridSkeleton(key: ValueKey('loading'));
    }
    if (viewModel.categories.isEmpty) {
      return Row(
        key: const ValueKey('error'),
        children: [
          Expanded(
            child: Text(
              "Couldn't load categories.",
              style: textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: viewModel.loadCategories.execute,
            child: const Text('Try again'),
          ),
        ],
      );
    }
    return CategoryPicker(
      key: ValueKey(viewModel.type),
      categories: viewModel.categories,
      selected: viewModel.selectedCategory,
      onSelected: viewModel.selectCategory,
    );
  }
}

/// "Paid from" or "Received into", with a chip per wallet.
class _WalletSection extends StatelessWidget {
  const _WalletSection({required this.viewModel});

  final AddTransactionViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          viewModel.isExpense ? 'Paid from' : 'Received into',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: Dimens.gapM),
        WalletPicker(
          wallets: viewModel.wallets,
          selectedId: viewModel.selectedWalletId,
          onSelected: viewModel.selectWallet,
        ),
      ],
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.viewModel,
    required this.title,
    required this.note,
  });

  final AddTransactionViewModel viewModel;
  final TextEditingController title;
  final TextEditingController note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledTextField(
          label: 'Title (optional)',
          controller: title,
          hint: viewModel.isExpense ? 'e.g. Shoprite' : 'e.g. Salary',
          prefixIcon: Icons.edit_note_rounded,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: Dimens.gapL),
        DateField(
          date: viewModel.date,
          firstDate: viewModel.firstDate,
          lastDate: viewModel.lastDate,
          onChanged: viewModel.selectDate,
        ),
        const SizedBox(height: Dimens.gapL),
        LabeledTextField(
          label: 'Note (optional)',
          controller: note,
          hint: 'Anything to remember about this',
          textCapitalization: TextCapitalization.sentences,
          maxLines: 3,
        ),
      ],
    );
  }
}
