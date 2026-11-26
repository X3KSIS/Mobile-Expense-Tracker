import 'package:flutter/material.dart';

import '../../../domain/models/wallet_balances.dart';
import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/motion.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/pressable.dart';
import '../../core/ui/wallet_tile.dart';

/// "Wallets" header with "Manage", then a sideways row of wallet cards
/// with their balances. Balances are masked with the balance card's eye.
class WalletStrip extends StatelessWidget {
  const WalletStrip({
    super.key,
    required this.wallets,
    required this.hideAmounts,
    required this.onOpen,
  });

  final List<WalletBalance> wallets;
  final bool hideAmounts;
  final VoidCallback onOpen;

  static const double _cardWidth = 150;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('Wallets', style: context.text.sectionTitle)),
            TextButton(onPressed: onOpen, child: const Text('Manage')),
          ],
        ),
        const SizedBox(height: Dimens.gapS),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (final (i, b) in wallets.indexed) ...[
                if (i > 0) const SizedBox(width: Dimens.gapM),
                SizedBox(
                  width: _cardWidth,
                  child: _WalletCard(
                    balance: b,
                    hidden: hideAmounts,
                    onTap: onOpen,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.balance,
    required this.hidden,
    required this.onTap,
  });

  final WalletBalance balance;
  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(Dimens.radiusTile);
    final amount = hidden ? '$currencyCode ••••' : formatZmw(balance.balance);
    return Semantics(
      button: true,
      label: '${balance.wallet.name}, ${hidden ? 'hidden' : amount}',
      excludeSemantics: true,
      child: Pressable(
        child: Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: colors.border),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.all(Dimens.gapM + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WalletIconTile(kind: balance.wallet.kind, size: 38),
                  const SizedBox(height: Dimens.gapM),
                  Text(
                    balance.wallet.name,
                    style: context.text.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    duration: AppMotion.medium,
                    child: Text(
                      amount,
                      key: ValueKey(amount),
                      style: context.text.listAmount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
