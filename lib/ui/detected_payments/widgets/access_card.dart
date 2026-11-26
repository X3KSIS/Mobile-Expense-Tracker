import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/primary_button.dart';

/// Explains what notification access is for, and asks for it.
class AccessCard extends StatelessWidget {
  const AccessCard({super.key, required this.loading, required this.onAllow});

  final bool loading;
  final VoidCallback onAllow;

  static const List<(IconData, String)> _points = [
    (
      Icons.sms_outlined,
      'Spots MTN MoMo, Airtel Money, Zamtel and bank messages as they '
          'arrive.',
    ),
    (
      Icons.fact_check_outlined,
      'Each one waits here for you to add or dismiss. Nothing is saved on '
          'its own.',
    ),
    (
      Icons.lock_outline_rounded,
      'Other notifications are ignored, and nothing leaves your phone.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(Dimens.cardPadding),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimens.radiusCard),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add payments without typing', style: context.text.sectionTitle),
          const SizedBox(height: Dimens.gapL),
          for (final (icon, text) in _points) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: Dimens.iconSize, color: colors.accentText),
                const SizedBox(width: Dimens.gapM),
                Expanded(child: Text(text, style: context.text.body)),
              ],
            ),
            const SizedBox(height: Dimens.gapM),
          ],
          const SizedBox(height: Dimens.gapS),
          PrimaryButton(
            label: 'Allow notification access',
            loading: loading,
            onPressed: onAllow,
          ),
          const SizedBox(height: Dimens.gapM),
          Text(
            'Android opens Settings. Turn on Expense Tracker, then come back.',
            style: context.text.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
