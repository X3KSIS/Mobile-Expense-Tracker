import 'package:flutter/material.dart';

import '../../../utils/currency.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/category_icon.dart';
import '../../core/ui/choice_pill.dart';
import '../view_models/add_transaction_view_model.dart';

/// "Recent": a row of chips for places recorded again and again. One tap
/// fills the title, category and wallet (and the amount when it never
/// changes).
class QuickPicks extends StatelessWidget {
  const QuickPicks({super.key, required this.picks, required this.onPicked});

  final List<QuickPick> picks;
  final ValueChanged<QuickPick> onPicked;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Recent', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: Dimens.gapM),
        // Bleeds to the screen edges so chips scroll under the padding.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (final pick in picks) ...[
                ChoicePill(
                  icon: CategoryIcons.resolve(pick.category.icon),
                  label: pick.title,
                  detail: pick.fixedAmount
                      ? '$currencyCode ${formatWhole(pick.amount)}'
                      : null,
                  semanticLabel:
                      'Fill in ${pick.title}, ${pick.category.name}'
                      '${pick.fixedAmount ? ', ${formatZmw(pick.amount)}' : ''}',
                  onTap: () => onPicked(pick),
                ),
                const SizedBox(width: Dimens.gapS),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
