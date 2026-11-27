import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../utils/currency.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/fade_switcher.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/screen_header.dart';
import '../../core/ui/segmented_toggle.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/stat_tile.dart';
import '../view_models/export_view_model.dart';

/// Export transactions as a CSV file through the share sheet (save to
/// Files, email, WhatsApp, Drive).
class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key, required this.viewModel});

  final ExportViewModel viewModel;

  Future<void> _share(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = utf8.encode(viewModel.buildCsv());
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'text/csv',
              name: viewModel.fileName,
            ),
          ],
          fileNameOverrides: [viewModel.fileName],
          subject: 'Expense Tracker transactions',
        ),
      );
    } on Exception {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't share the file.")),
      );
    }
  }

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
              const ScreenHeader(title: 'Export data'),
              const SizedBox(height: Dimens.sectionGap),
              Text(
                'Share your transactions as a CSV file to open in Excel or '
                'Google Sheets, or keep as a backup.',
                style: context.text.body,
              ),
              const SizedBox(height: Dimens.sectionGap),
              SegmentedToggle<ExportPeriod>(
                options: [
                  for (final p in ExportPeriod.values)
                    ToggleOption(value: p, label: p.label),
                ],
                selected: viewModel.period,
                onChanged: viewModel.selectPeriod,
              ),
              const SizedBox(height: Dimens.sectionGap),
              FadeSwitcher(child: _summary(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summary(BuildContext context) {
    if (viewModel.isLoading) {
      return const Shimmer(
        key: ValueKey('loading'),
        child: SkeletonBox(height: 120, radius: Dimens.radiusList),
      );
    }
    if (viewModel.hasError) {
      return EmptyState(
        key: const ValueKey('error'),
        icon: Icons.cloud_off_outlined,
        title: "Couldn't load your transactions",
        message: 'Please try again.',
        actionLabel: 'Try again',
        onAction: viewModel.load.execute,
      );
    }
    final count = viewModel.selected.length;
    return Column(
      key: ValueKey(viewModel.period),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Money out',
                value: formatZmw(viewModel.moneyOut),
                icon: Icons.north_east_rounded,
              ),
            ),
            const SizedBox(width: Dimens.gapM),
            Expanded(
              child: StatTile(
                label: 'Money in',
                value: formatZmw(viewModel.moneyIn),
                icon: Icons.south_west_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: Dimens.gapM),
        Text(
          count == 1 ? '1 transaction' : '$count transactions',
          style: context.text.caption,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Dimens.sectionGap),
        PrimaryButton(
          label: 'Share CSV',
          onPressed: count == 0 ? null : () => _share(context),
        ),
      ],
    );
  }
}
