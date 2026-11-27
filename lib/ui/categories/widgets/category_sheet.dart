import 'package:flutter/material.dart';

import '../../../domain/models/transaction_category.dart';
import '../../../utils/result.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/category_icon.dart';
import '../../core/ui/category_tile.dart';
import '../../core/ui/labeled_text_field.dart';
import '../../core/ui/pressable.dart';
import '../../core/ui/primary_button.dart';
import '../view_models/categories_view_model.dart';

/// Opens the sheet to add a category (id empty) or edit one.
Future<void> showCategorySheet(
  BuildContext context, {
  required CategoriesViewModel viewModel,
  required TransactionCategory category,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => CategorySheet(viewModel: viewModel, category: category),
  );
}

/// Name and icon for a category, with Delete when editing.
class CategorySheet extends StatefulWidget {
  const CategorySheet({
    super.key,
    required this.viewModel,
    required this.category,
  });

  final CategoriesViewModel viewModel;
  final TransactionCategory category;

  @override
  State<CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<CategorySheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.category.name,
  );
  late String _icon = widget.category.icon;
  String? _error;
  bool _busy = false;

  bool get _isNew => widget.category.id.isEmpty;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final save = widget.viewModel.save;
    await save.execute(
      TransactionCategory(
        id: widget.category.id,
        name: _name.text,
        icon: _icon,
        color: widget.category.color,
        type: widget.category.type,
      ),
    );
    _finish(save.result, _isNew ? 'Category added' : 'Category saved');
    save.clearResult();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${widget.category.name}?'),
        content: const Text(
          'It leaves the category list. Past transactions keep their '
          'category, so reports stay the same.',
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
    if (!(confirmed ?? false) || !mounted) return;
    setState(() => _busy = true);
    final delete = widget.viewModel.delete;
    await delete.execute(widget.category.id);
    _finish(delete.result, 'Category deleted');
    delete.clearResult();
  }

  void _finish(Result<Object?>? result, String done) {
    if (!mounted || result == null) return;
    switch (result) {
      case Ok():
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(done)));
      case Error(:final error):
        setState(() {
          _busy = false;
          _error = CategoriesViewModel.messageFor(error);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = !_isNew && widget.viewModel.canDelete(widget.category);
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isNew ? 'New category' : 'Edit category',
                style: context.text.sectionTitle,
              ),
              const SizedBox(height: Dimens.gapL),
              LabeledTextField(
                label: 'Name',
                controller: _name,
                hint: 'e.g. Pets',
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              if (_error case final error?) ...[
                const SizedBox(height: Dimens.gapS),
                Text(
                  error,
                  style: context.text.caption.copyWith(
                    color: context.colors.error,
                  ),
                ),
              ],
              const SizedBox(height: Dimens.gapL),
              Text('Icon', style: context.text.fieldLabel),
              const SizedBox(height: Dimens.gapS),
              _IconGrid(
                selected: _icon,
                onSelected: (key) => setState(() => _icon = key),
              ),
              const SizedBox(height: Dimens.sectionGap + 4),
              PrimaryButton(
                label: _isNew ? 'Add category' : 'Save category',
                loading: _busy,
                onPressed: _save,
              ),
              if (canDelete) ...[
                const SizedBox(height: Dimens.gapM),
                TextButton(
                  onPressed: _busy ? null : _delete,
                  child: const Text('Delete category'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IconGrid extends StatelessWidget {
  const _IconGrid({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Dimens.gapS,
      runSpacing: Dimens.gapS,
      children: [
        for (final key in CategoryIcons.choices)
          Semantics(
            button: true,
            selected: key == selected,
            label: key.replaceAll('_', ' '),
            excludeSemantics: true,
            child: Pressable(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(key),
                child: IconTile(
                  icon: CategoryIcons.resolve(key),
                  emphasized: key == selected,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
