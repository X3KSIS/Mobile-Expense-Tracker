import 'package:flutter/material.dart';

import '../../../domain/models/wallet.dart';
import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/motion.dart';
import '../themes/theme.dart';
import 'pressable.dart';

/// Outline icon for each kind of wallet.
IconData walletIcon(WalletKind kind) => switch (kind) {
  WalletKind.cash => Icons.payments_outlined,
  WalletKind.mobileMoney => Icons.smartphone_outlined,
  WalletKind.bank => Icons.account_balance_outlined,
};

/// "Cash", "Mobile money" or "Bank".
String walletKindLabel(WalletKind kind) => switch (kind) {
  WalletKind.cash => 'Cash',
  WalletKind.mobileMoney => 'Mobile money',
  WalletKind.bank => 'Bank',
};

/// 44px rounded tile with a wallet kind's icon on a soft tint.
class WalletIconTile extends StatelessWidget {
  const WalletIconTile({
    super.key,
    required this.kind,
    this.size = Dimens.iconTileSize,
  });

  final WalletKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (fg, bg) = switch (kind) {
      WalletKind.cash => (colors.success, colors.successSoft),
      WalletKind.mobileMoney => (colors.warning, colors.warningSoft),
      WalletKind.bank => (colors.textPrimary, colors.surfaceMuted),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Dimens.radiusIconTile),
      ),
      child: Icon(walletIcon(kind), size: Dimens.iconSize, color: fg),
    );
  }
}

/// A row of wallet chips to pick one; the selected chip turns navy.
class WalletPicker extends StatelessWidget {
  const WalletPicker({
    super.key,
    required this.wallets,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Wallet> wallets;
  final String? selectedId;
  final ValueChanged<Wallet> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Dimens.gapS,
      runSpacing: Dimens.gapS,
      children: [
        for (final wallet in wallets)
          _WalletChip(
            wallet: wallet,
            selected: wallet.id == selectedId,
            onTap: () => onSelected(wallet),
          ),
      ],
    );
  }
}

class _WalletChip extends StatelessWidget {
  const _WalletChip({
    required this.wallet,
    required this.selected,
    required this.onTap,
  });

  final Wallet wallet;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = selected ? colors.textOnNavy : colors.textPrimary;
    final radius = BorderRadius.circular(Dimens.radiusInput);
    return Semantics(
      button: true,
      selected: selected,
      label: wallet.name,
      excludeSemantics: true,
      child: Pressable(
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.move,
          constraints: const BoxConstraints(minHeight: Dimens.minTouchTarget),
          decoration: BoxDecoration(
            color: selected ? colors.navy : colors.surface,
            borderRadius: radius,
            border: Border.all(color: selected ? colors.navy : colors.border),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.gapM,
                  vertical: Dimens.gapS,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      walletIcon(wallet.kind),
                      size: Dimens.iconSizeSmall,
                      color: fg,
                    ),
                    const SizedBox(width: Dimens.gapS),
                    AnimatedDefaultTextStyle(
                      duration: AppMotion.medium,
                      style: context.text.body.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                      child: Text(wallet.name),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
