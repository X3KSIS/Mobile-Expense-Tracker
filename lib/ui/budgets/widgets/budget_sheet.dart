import 'package:flutter/material.dart';

import '../../../domain/models/budget.dart';
import '../../../domain/models/transaction_category.dart';
import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/category_picker.dart';
import '../../core/ui/labeled_text_field.dart';
import '../../core/ui/primary_button.dart';
import '../view_models/budgets_view_model.dart';

/// Opens the add (when [budget] is null) or edit budget sheet.
Future<void> showBudgetSheet(
  BuildContext context, {
  required BudgetsViewModel viewModel,
  Budget? budget,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => BudgetSheet(viewModel: viewModel, budget: budget),
  );
}

/// Form to set a category's monthly limit, and delete it when editing.
class BudgetSheet extends StatefulWidget {
  const BudgetSheet({super.key, required this.viewModel, this.budget});

  final BudgetsViewModel viewModel;
  final Budget? budget;

  @override
  State<BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<BudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _limit = TextEditingController(
    text: widget.budget == null ? '' : formatWhole(widget.budget!.limit),
  );
  late final List<TransactionCategory> _categories =
      widget.viewModel.availableCategories;
  late TransactionCategory? _category = _categories.isEmpty
      ? null
      : _categories.first;

  bool get _isEditing => widget.budget != null;

  @override
  void initState() {
    super.initState();
    widget.viewModel.save.addListener(_onSaved);
    widget.viewModel.delete.addListener(_onSaved);
  }

  @override
  void dispose() {
    widget.viewModel.save.removeListener(_onSaved);
    widget.viewModel.delete.removeListener(_onSaved);
    _limit.dispose();
    super.dispose();
  }

  void _onSaved() {
    final vm = widget.viewModel;
    if (!mounted) return;
    if (vm.save.completed || vm.delete.completed) {
      final message = vm.delete.completed
          ? 'Budget deleted'
          : (_isEditing ? 'Budget updated' : 'Budget added');
      vm.save.clearResult();
      vm.delete.clearResult();
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } else {
      setState(() {});
    }
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.viewModel.save.execute((
      budget: widget.budget,
      category: _category,
      limit: _limit.text,
    ));
  }

  Future<void> _confirmDelete() async {
    final budget = widget.budget!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete budget?'),
        content: Text(
          'Your ${budget.categoryName} transactions stay; only the limit is '
          'removed.',
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
    if (confirmed ?? false) widget.viewModel.delete.execute(budget.id);
  }

  @override
  Widget build(BuildContext context) {
    final busy =
        widget.viewModel.save.running || widget.viewModel.delete.running;
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
                  _isEditing
                      ? '${widget.budget!.categoryName} budget'
                      : 'New budget',
                  style: AppTypography.sectionTitle,
                ),
                const SizedBox(height: Dimens.gapL),
                if (!_isEditing) ...[
                  _CategoryChoice(
                    categories: _categories,
                    selected: _category,
                    onSelected: (c) => setState(() => _category = c),
                  ),
                  const SizedBox(height: Dimens.gapL),
                ],
                LabeledTextField(
                  label: 'Monthly limit (ZMW)',
                  controller: _limit,
                  hint: 'e.g. 1,500',
                  prefixIcon: Icons.payments_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: widget.viewModel.validateLimit,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: Dimens.sectionGap + 4),
                PrimaryButton(
                  label: _isEditing ? 'Save budget' : 'Add budget',
                  loading: widget.viewModel.save.running,
                  onPressed: (!_isEditing && _category == null)
                      ? null
                      : _submit,
                ),
                if (_isEditing) ...[
                  const SizedBox(height: Dimens.gapM),
                  TextButton(
                    onPressed: busy ? null : _confirmDelete,
                    child: const Text('Delete budget'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChoice extends StatelessWidget {
  const _CategoryChoice({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<TransactionCategory> categories;
  final TransactionCategory? selected;
  final ValueChanged<TransactionCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Text(
        'Every expense category already has a budget.',
        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category', style: AppTypography.fieldLabel),
        const SizedBox(height: Dimens.gapS),
        CategoryPicker(
          categories: categories,
          selected: selected,
          onSelected: onSelected,
        ),
      ],
    );
  }
}
