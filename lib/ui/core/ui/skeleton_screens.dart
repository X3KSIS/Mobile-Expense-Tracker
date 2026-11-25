import 'package:flutter/material.dart';

import '../themes/dimens.dart';
import 'skeleton.dart';

/// Lays out a full tab-style skeleton page with the same padding as the
/// real screens, so content fades in exactly where the placeholders were.
class _SkeletonPage extends StatelessWidget {
  const _SkeletonPage({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        Dimens.screenPadding,
        Dimens.gapL,
        Dimens.screenPadding,
        Dimens.navBarClearance(context),
      ),
      children: [Shimmer(child: Column(children: children))],
    );
  }
}

/// Placeholder for the Home dashboard.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _SkeletonPage(
      children: [
        const Row(
          children: [
            SkeletonBox(
              width: Dimens.avatarSize,
              height: Dimens.avatarSize,
              radius: Dimens.radiusButton,
            ),
            SizedBox(width: Dimens.gapM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(width: 90),
                  SizedBox(height: Dimens.gapS),
                  SkeletonLine(width: 140, height: 16),
                ],
              ),
            ),
            SkeletonBox(
              width: Dimens.headerButtonSize,
              height: Dimens.headerButtonSize,
              radius: Dimens.radiusButton,
            ),
          ],
        ),
        const SizedBox(height: Dimens.sectionGap),
        const SkeletonCard(
          radius: Dimens.radiusCard,
          padding: EdgeInsets.all(Dimens.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLine(width: 130),
              SizedBox(height: Dimens.gapL),
              SkeletonLine(width: 190, height: 32),
              SizedBox(height: Dimens.gapL),
              Row(
                children: [
                  Expanded(child: SkeletonBox(height: 64)),
                  SizedBox(width: Dimens.gapM),
                  Expanded(child: SkeletonBox(height: 64)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Dimens.gapL),
        const SkeletonBox(height: 150, radius: Dimens.radiusCard),
        const SizedBox(height: Dimens.sectionGap),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < 4; i++)
              const SkeletonBox(
                width: Dimens.quickActionSize,
                height: Dimens.quickActionSize,
                radius: Dimens.radiusButton,
              ),
          ],
        ),
        const SizedBox(height: Dimens.sectionGap),
        const SkeletonListCard(),
      ],
    );
  }
}

/// Placeholder for the Activity tab.
class ActivitySkeleton extends StatelessWidget {
  const ActivitySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SkeletonPage(
      children: [
        SkeletonHeader(),
        SizedBox(height: Dimens.gapL),
        SkeletonBox(height: 52),
        SizedBox(height: Dimens.gapM),
        SkeletonBox(height: 52, radius: Dimens.radiusFull),
        SizedBox(height: Dimens.gapM),
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 70, radius: Dimens.radiusTile)),
            SizedBox(width: Dimens.gapM),
            Expanded(child: SkeletonBox(height: 70, radius: Dimens.radiusTile)),
          ],
        ),
        SizedBox(height: Dimens.sectionGap),
        Align(alignment: Alignment.centerLeft, child: SkeletonLine(width: 70)),
        SizedBox(height: Dimens.gapS),
        SkeletonListCard(rows: 2),
        SizedBox(height: Dimens.sectionGap),
        Align(alignment: Alignment.centerLeft, child: SkeletonLine(width: 90)),
        SizedBox(height: Dimens.gapS),
        SkeletonListCard(rows: 3),
      ],
    );
  }
}

/// Placeholder for the Budgets tab.
class BudgetsSkeleton extends StatelessWidget {
  const BudgetsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _SkeletonPage(
      children: [
        const SkeletonHeader(trailing: true),
        const SizedBox(height: Dimens.sectionGap),
        const SkeletonBox(height: 190, radius: Dimens.radiusCard),
        const SizedBox(height: Dimens.sectionGap),
        for (var i = 0; i < 3; i++) ...[
          const SkeletonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonListRow(),
                SizedBox(height: Dimens.gapS),
                SkeletonLine(height: 8),
                SizedBox(height: Dimens.gapS),
                SkeletonLine(width: 90, height: 10),
              ],
            ),
          ),
          const SizedBox(height: Dimens.gapM),
        ],
      ],
    );
  }
}

/// Placeholder for the Reports tab.
class ReportsSkeleton extends StatelessWidget {
  const ReportsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SkeletonPage(
      children: [
        SkeletonHeader(),
        SizedBox(height: Dimens.gapL),
        SkeletonBox(height: 56, radius: Dimens.radiusFull),
        SizedBox(height: Dimens.sectionGap),
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 92, radius: Dimens.radiusTile)),
            SizedBox(width: Dimens.gapM),
            Expanded(child: SkeletonBox(height: 92, radius: Dimens.radiusTile)),
          ],
        ),
        SizedBox(height: Dimens.gapM),
        SkeletonBox(height: 92, radius: Dimens.radiusTile),
        SizedBox(height: Dimens.sectionGap + 4),
        Align(
          alignment: Alignment.centerLeft,
          child: SkeletonLine(width: 170, height: 16),
        ),
        SizedBox(height: Dimens.gapM),
        SkeletonListCard(rows: 4),
      ],
    );
  }
}

/// Placeholder for the category grid on Add transaction.
class CategoryGridSkeleton extends StatelessWidget {
  const CategoryGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Wrap(
        spacing: Dimens.gapL,
        runSpacing: Dimens.gapL,
        alignment: WrapAlignment.spaceAround,
        children: [
          for (var i = 0; i < 8; i++)
            const Column(
              children: [
                SkeletonBox(
                  width: Dimens.quickActionSize,
                  height: Dimens.quickActionSize,
                ),
                SizedBox(height: Dimens.gapS),
                SkeletonLine(width: 48, height: 10),
              ],
            ),
        ],
      ),
    );
  }
}
