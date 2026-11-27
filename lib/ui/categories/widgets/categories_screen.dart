import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/transaction.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/motion.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/category_tile.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/fade_switcher.dart';
import '../../core/ui/header_icon_button.dart';
import '../../core/ui/screen_header.dart';
import '../../core/ui/segmented_toggle.dart';
import '../../core/ui/skeleton.dart';
import '../view_models/categories_view_model.dart';
import 'category_sheet.dart';

/// Manage categories: expense or income, in the user's order. Tap to edit,
/// long-press to drag, + to add.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key, required this.viewModel});

  final CategoriesViewModel viewModel;

  void _add(BuildContext context) => showCategorySheet(
    context,
    viewModel: viewModel,
    category: viewModel.blank(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([viewModel, viewModel.load]),
          builder: (context, _) => CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Dimens.screenPadding,
                  Dimens.gapL,
                  Dimens.screenPadding,
                  Dimens.gapL,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ScreenHeader(
                        title: 'Categories',
                        trailing: HeaderIconButton(
                          icon: Icons.add_rounded,
                          tooltip: 'Add category',
                          onPressed: () => _add(context),
                        ),
                      ),
                      const SizedBox(height: Dimens.sectionGap),
                      SegmentedToggle<TransactionType>(
                        options: const [
                          ToggleOption(
                            value: TransactionType.expense,
                            label: 'Expenses',
                          ),
                          ToggleOption(
                            value: TransactionType.income,
                            label: 'Income',
                          ),
                        ],
                        selected: viewModel.type,
                        onChanged: viewModel.selectType,
                      ),
                      const SizedBox(height: Dimens.gapM),
                      Text(
                        'Tap to rename or change the icon. Hold and drag to '
                        'reorder.',
                        style: context.text.caption,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Dimens.screenPadding,
                  0,
                  Dimens.screenPadding,
                  Dimens.screenPadding,
                ),
                sliver: _body(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (viewModel.isLoading) {
      return const SliverToBoxAdapter(
        child: Shimmer(child: SkeletonListCard(rows: 6)),
      );
    }
    if (viewModel.hasError) {
      return SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.cloud_off_outlined,
          title: "Couldn't load categories",
          message: 'Please try again.',
          actionLabel: 'Try again',
          onAction: viewModel.load.execute,
        ),
      );
    }
    final items = viewModel.categories;
    return SliverReorderableList(
      itemCount: items.length,
      onReorderStart: (_) => HapticFeedback.mediumImpact(),
      onReorderItem: (from, to) => viewModel.reorder.execute((from, to)),
      proxyDecorator: _lifted,
      itemBuilder: (context, index) {
        final category = items[index];
        return ReorderableDelayedDragStartListener(
          key: ValueKey(category.id),
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: Dimens.gapS),
            child: FadeSwitcher(
              child: _CategoryRow(
                key: ValueKey('${category.id}-${category.name}'),
                name: category.name,
                icon: category.icon,
                onTap: () => showCategorySheet(
                  context,
                  viewModel: viewModel,
                  category: category,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// The dragged row grows by 5 % and lifts onto a soft shadow.
  Widget _lifted(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = AppMotion.enter.transform(animation.value);
        return Transform.scale(
          scale: lerpDouble(1, AppMotion.dragLiftScale, t),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimens.radiusTile),
              boxShadow: [
                for (final s in context.shadows.soft)
                  s.copyWith(color: s.color.withValues(alpha: s.color.a * t)),
              ],
            ),
            child: Material(type: MaterialType.transparency, child: child),
          ),
        );
      },
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    super.key,
    required this.name,
    required this.icon,
    required this.onTap,
  });

  final String name;
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimens.radiusTile),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.gapM,
            vertical: Dimens.gapS + 2,
          ),
          child: Row(
            children: [
              CategoryTile(icon: icon),
              const SizedBox(width: Dimens.gapM),
              Expanded(child: Text(name, style: context.text.listTitle)),
              Icon(
                Icons.drag_indicator_rounded,
                size: Dimens.iconSize,
                color: colors.textSecondary,
                semanticLabel: 'Hold to reorder',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
