import 'package:flutter/material.dart';

import '../../core/ui/segmented_toggle.dart';
import '../view_models/activity_view_model.dart';

/// All / Expenses / Income, shared by Activity and History.
class ActivityFilterToggle extends StatelessWidget {
  const ActivityFilterToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ActivityFilter selected;
  final ValueChanged<ActivityFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedToggle<ActivityFilter>(
      options: const [
        ToggleOption(value: ActivityFilter.all, label: 'All'),
        ToggleOption(value: ActivityFilter.expenses, label: 'Expenses'),
        ToggleOption(value: ActivityFilter.income, label: 'Income'),
      ],
      selected: selected,
      onChanged: onChanged,
    );
  }
}
