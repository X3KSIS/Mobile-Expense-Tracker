import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/app_notification.dart';
import '../../../routing/routes.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/fade_switcher.dart';
import '../../core/ui/header_icon_button.dart';
import '../../core/ui/list_card.dart';
import '../../core/ui/screen_header.dart';
import '../../core/ui/skeleton.dart';
import '../view_models/notifications_view_model.dart';
import 'notification_row.dart';

/// What needs a look in the user's spending: budgets near or over their
/// limit, regular payments due or late, and payments to review. Opened
/// from the bell on Home.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.viewModel});

  final NotificationsViewModel viewModel;

  /// Where each kind leads.
  static String routeFor(NotificationKind kind) => switch (kind) {
    NotificationKind.overBudget ||
    NotificationKind.nearBudget => Routes.budgets,
    NotificationKind.paymentLate ||
    NotificationKind.paymentDueSoon => Routes.recurring,
    NotificationKind.paymentsToReview => Routes.detectedPayments,
  };

  void _open(BuildContext context, AppNotification n) {
    final route = routeFor(n.kind);
    // Budgets is a tab: go there; the others open over this page.
    if (route == Routes.budgets) {
      context.go(route);
    } else {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimens.screenPadding,
            Dimens.gapL,
            Dimens.screenPadding,
            0,
          ),
          child: Column(
            children: [
              ScreenHeader(
                title: 'Notifications',
                trailing: HeaderIconButton(
                  icon: Icons.tune_rounded,
                  tooltip: 'Notification settings',
                  onPressed: () => context.push(Routes.notificationSettings),
                ),
              ),
              const SizedBox(height: Dimens.sectionGap),
              Expanded(
                child: ListenableBuilder(
                  listenable: viewModel,
                  builder: (context, _) =>
                      FadeSwitcher(animateSize: false, child: _body(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (viewModel.isLoading || !viewModel.hasData) {
      return const Shimmer(
        key: ValueKey('loading'),
        child: Column(children: [SkeletonListCard(rows: 3)]),
      );
    }
    if (viewModel.isEmpty) {
      return const Align(
        key: ValueKey('empty'),
        alignment: Alignment.topCenter,
        child: EmptyState(
          icon: Icons.notifications_none_rounded,
          title: "You're all caught up",
          message:
              'Budgets close to their limit, bills coming up and payments '
              'to review will show here.',
        ),
      );
    }
    final fresh = viewModel.fresh;
    final earlier = viewModel.earlier;
    return ListView(
      key: const ValueKey('list'),
      padding: const EdgeInsets.only(bottom: Dimens.screenPadding),
      children: [
        if (fresh.isNotEmpty) ..._section(context, 'New', fresh),
        if (fresh.isNotEmpty && earlier.isNotEmpty)
          const SizedBox(height: Dimens.sectionGap),
        if (earlier.isNotEmpty) ..._section(context, 'Earlier', earlier),
      ],
    );
  }

  List<Widget> _section(
    BuildContext context,
    String title,
    List<AppNotification> items,
  ) => [
    Padding(
      padding: const EdgeInsets.only(left: Dimens.gapXs, bottom: Dimens.gapS),
      child: Semantics(
        header: true,
        child: Text(title.toUpperCase(), style: context.text.overline),
      ),
    ),
    ListCard(
      children: [
        for (final n in items)
          NotificationRow(
            key: ValueKey(n.id),
            notification: n,
            now: viewModel.now,
            onTap: () => _open(context, n),
          ),
      ],
    ),
  ];
}
