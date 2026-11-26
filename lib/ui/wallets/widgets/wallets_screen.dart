import 'package:flutter/material.dart';

import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/fade_switcher.dart';
import '../../core/ui/header_icon_button.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/screen_header.dart';
import '../../core/ui/skeleton.dart';
import '../view_models/wallets_view_model.dart';
import 'transfer_list.dart';
import 'transfer_sheet.dart';
import 'wallet_list.dart';
import 'wallet_sheet.dart';
import 'wallets_total_card.dart';

/// Every wallet (cash, mobile money, bank) with its balance, the total,
/// moving money between them, and recent transfers.
class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key, required this.viewModel});

  final WalletsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([viewModel, viewModel.load]),
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(
              Dimens.screenPadding,
              Dimens.gapL,
              Dimens.screenPadding,
              Dimens.screenPadding,
            ),
            children: [
              ScreenHeader(
                title: 'Wallets',
                trailing: HeaderIconButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Add wallet',
                  onPressed: () =>
                      showWalletSheet(context, viewModel: viewModel),
                ),
              ),
              const SizedBox(height: Dimens.sectionGap),
              FadeSwitcher(child: _body(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (viewModel.isLoading) {
      return const Shimmer(
        key: ValueKey('loading'),
        child: Column(
          children: [
            SkeletonBox(height: 150, radius: Dimens.radiusCard),
            SizedBox(height: Dimens.sectionGap),
            SkeletonListCard(rows: 3),
          ],
        ),
      );
    }
    if (viewModel.hasError) {
      return EmptyState(
        key: const ValueKey('error'),
        icon: Icons.cloud_off_outlined,
        title: "Couldn't load your wallets",
        message: 'Check your connection and try again.',
        actionLabel: 'Try again',
        onAction: viewModel.load.execute,
      );
    }
    return Column(
      key: const ValueKey('content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WalletsTotalCard(
          total: viewModel.total,
          count: viewModel.balances.length,
        ),
        const SizedBox(height: Dimens.sectionGap),
        WalletList(
          balances: viewModel.balances,
          onWalletTap: (wallet) =>
              showWalletSheet(context, viewModel: viewModel, wallet: wallet),
        ),
        const SizedBox(height: Dimens.sectionGap),
        PrimaryButton(
          label: 'Move money',
          onPressed: viewModel.canTransfer
              ? () => showTransferSheet(context, viewModel: viewModel)
              : null,
        ),
        const SizedBox(height: Dimens.sectionGap + Dimens.gapS),
        Text('Recent transfers', style: context.text.sectionTitle),
        const SizedBox(height: Dimens.gapM),
        TransferList(entries: viewModel.recentTransfers),
      ],
    );
  }
}
