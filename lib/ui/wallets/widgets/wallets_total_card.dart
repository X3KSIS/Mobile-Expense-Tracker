import 'package:flutter/material.dart';

import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/gradients.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/animated_number.dart';
import '../../core/ui/mesh_gradient_box.dart';

/// Navy card with the money held across all wallets.
class WalletsTotalCard extends StatelessWidget {
  const WalletsTotalCard({super.key, required this.total, required this.count});

  final double total;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MeshGradientBox(
      mesh: context.gradients.navyMesh,
      padding: const EdgeInsets.all(Dimens.cardPadding + 2),
      borderRadius: BorderRadius.circular(Dimens.radiusCard),
      boxShadow: context.shadows.soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MONEY YOU HAVE',
            style: context.text.overline.copyWith(
              color: colors.textOnNavyMuted,
            ),
          ),
          const SizedBox(height: Dimens.gapS),
          AnimatedNumber(
            value: total,
            builder: (context, value) {
              final money = splitMoney(value);
              return Semantics(
                label: 'Total ${formatZmw(total)}',
                excludeSemantics: true,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$currencyCode ',
                        style: context.text.amountPrefix.copyWith(
                          color: colors.textOnNavyMuted,
                        ),
                      ),
                      TextSpan(
                        text: money.whole,
                        style: context.text.amountLarge.copyWith(
                          color: colors.textOnNavy,
                        ),
                      ),
                      TextSpan(
                        text: money.decimals,
                        style: context.text.amountDecimals.copyWith(
                          color: colors.textOnNavyMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: Dimens.gapXs),
          Text(
            'Across $count wallet${count == 1 ? '' : 's'}',
            style: context.text.body.copyWith(color: colors.textOnNavyMuted),
          ),
        ],
      ),
    );
  }
}
