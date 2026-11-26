import 'package:flutter/material.dart';

import '../../../domain/models/wallet.dart';
import '../../../domain/models/wallet_balances.dart';
import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/animated_number.dart';
import '../../core/ui/list_card.dart';
import '../../core/ui/wallet_tile.dart';

/// Each wallet with its kind and balance. Tap one to edit it.
class WalletList extends StatelessWidget {
  const WalletList({
    super.key,
    required this.balances,
    required this.onWalletTap,
  });

  final List<WalletBalance> balances;
  final ValueChanged<Wallet> onWalletTap;

  @override
  Widget build(BuildContext context) {
    return ListCard(
      children: [
        for (final b in balances)
          _WalletRow(balance: b, onTap: () => onWalletTap(b.wallet)),
      ],
    );
  }
}

class _WalletRow extends StatelessWidget {
  const _WalletRow({required this.balance, required this.onTap});

  final WalletBalance balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final wallet = balance.wallet;
    return Semantics(
      button: true,
      label: '${wallet.name}, ${formatZmw(balance.balance)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Dimens.gapL),
          child: Row(
            children: [
              WalletIconTile(kind: wallet.kind),
              const SizedBox(width: Dimens.gapM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(wallet.name, style: context.text.listTitle),
                    const SizedBox(height: 2),
                    Text(
                      walletKindLabel(wallet.kind),
                      style: context.text.caption,
                    ),
                  ],
                ),
              ),
              AnimatedNumber(
                value: balance.balance,
                builder: (context, value) => Text(
                  formatZmw(value),
                  style: context.text.listAmount.copyWith(
                    color: value < 0 ? context.colors.error : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
