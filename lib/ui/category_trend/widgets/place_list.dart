import 'package:flutter/material.dart';

import '../../../domain/models/category_trend.dart';
import '../../../utils/currency.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/progress_bar.dart';

/// Where the category's money went: each place, how often, and a bar
/// relative to the largest, in one hue.
class PlaceList extends StatelessWidget {
  const PlaceList({super.key, required this.places});

  final List<PlaceSpend> places;

  @override
  Widget build(BuildContext context) {
    final largest = places.isEmpty ? 0.0 : places.first.amount;
    return Column(
      children: [
        for (final (i, place) in places.indexed) ...[
          if (i > 0) const SizedBox(height: Dimens.gapL),
          _PlaceRow(
            place: place,
            fraction: largest == 0 ? 0 : place.amount / largest,
          ),
        ],
      ],
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.place, required this.fraction});

  final PlaceSpend place;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final times = place.count == 1 ? 'Once' : '${place.count} times';
    final detail = place.count == 1
        ? times
        : '$times · about ${formatZmw(place.average)} each';
    return Semantics(
      label: '${place.title}: ${formatZmw(place.amount)}, $detail',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  place.title,
                  style: context.text.listTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(formatZmw(place.amount), style: context.text.listAmount),
            ],
          ),
          const SizedBox(height: 2),
          Text(detail, style: context.text.caption),
          const SizedBox(height: Dimens.gapS - 2),
          ProgressBar(value: fraction),
        ],
      ),
    );
  }
}
