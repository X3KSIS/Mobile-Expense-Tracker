import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/detected_payment.dart';
import '../../../domain/models/money_message.dart';
import '../../../routing/routes.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/motion.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/expandable_section.dart';
import '../../core/ui/fade_switcher.dart';
import '../../core/ui/screen_header.dart';
import '../view_models/detected_payments_view_model.dart';
import 'access_card.dart';
import 'detected_payment_card.dart';

/// Payments read from MTN MoMo, Airtel Money, Zamtel and bank
/// notifications, each waiting to be added or dismissed. Explains and asks
/// for notification access first.
class DetectedPaymentsScreen extends StatefulWidget {
  const DetectedPaymentsScreen({super.key, required this.viewModel});

  final DetectedPaymentsViewModel viewModel;

  @override
  State<DetectedPaymentsScreen> createState() => _DetectedPaymentsScreenState();
}

class _DetectedPaymentsScreenState extends State<DetectedPaymentsScreen> {
  /// Cards folding away before their payment is removed.
  final Set<String> _leaving = {};

  /// Folds the card away, then removes the payment.
  Future<void> _remove(DetectedPayment payment, {required bool added}) async {
    setState(() => _leaving.add(payment.id));
    await Future<void>.delayed(AppMotion.expand);
    final vm = widget.viewModel;
    await (added ? vm.markAdded : vm.dismiss).execute(payment.id);
    if (mounted) setState(() => _leaving.remove(payment.id));
  }

  Future<void> _add(DetectedPayment payment) async {
    if (payment.message.kind == MoneyMessageKind.withdrawal) {
      await context.push(Routes.wallets);
      return;
    }
    final saved = await context.push<bool>(Routes.add, extra: payment.message);
    if (saved ?? false) await _remove(payment, added: true);
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([vm, vm.enable]),
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(
              Dimens.screenPadding,
              Dimens.gapL,
              Dimens.screenPadding,
              Dimens.screenPadding,
            ),
            children: [
              const ScreenHeader(title: 'From your messages'),
              const SizedBox(height: Dimens.sectionGap),
              FadeSwitcher(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    final vm = widget.viewModel;
    if (!vm.isSupported) {
      return const EmptyState(
        key: ValueKey('unsupported'),
        icon: Icons.phonelink_off_outlined,
        title: 'Available on Android',
        message:
            'Reading payment notifications needs an Android phone. You can '
            'still paste a message on Add transaction.',
      );
    }
    if (!vm.isEnabled) {
      return AccessCard(
        key: const ValueKey('access'),
        loading: vm.enable.running,
        onAllow: vm.enable.execute,
      );
    }
    final pending = vm.pending;
    if (pending.isEmpty) {
      return const EmptyState(
        key: ValueKey('empty'),
        icon: Icons.mark_email_read_outlined,
        title: "You're all caught up",
        message:
            'New payment messages show up here while the app is open, and '
            'from your notification tray when you come back to it.',
      );
    }
    return Column(
      key: const ValueKey('list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${pending.length} waiting. Nothing is saved until you add it.',
          style: context.text.caption,
        ),
        const SizedBox(height: Dimens.gapM),
        for (final payment in pending)
          ExpandableSection(
            key: ValueKey(payment.id),
            expanded: !_leaving.contains(payment.id),
            child: Padding(
              padding: const EdgeInsets.only(bottom: Dimens.gapM),
              child: DetectedPaymentCard(
                payment: payment,
                onAdd: () => _add(payment),
                onDismiss: () => _remove(payment, added: false),
              ),
            ),
          ),
      ],
    );
  }
}
