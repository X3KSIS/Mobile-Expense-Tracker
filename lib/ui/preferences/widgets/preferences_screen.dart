import 'package:flutter/material.dart';

import '../../core/themes/dimens.dart';
import '../../core/ui/payday_picker.dart';
import '../../core/ui/screen_header.dart';
import '../../core/ui/segmented_toggle.dart';
import '../../core/ui/wallet_tile.dart';
import '../view_models/preferences_view_model.dart';
import 'preference_row.dart';
import 'preference_section.dart';
import 'theme_choice.dart';

/// How the app looks and behaves: theme, budgeting, the wallet new
/// expenses start with, and what Home shows. Changes apply at once and are
/// saved to the account.
class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key, required this.viewModel});

  final PreferencesViewModel viewModel;

  Future<void> _pickPayday(BuildContext context) async {
    final day = await showPaydayPicker(context, current: viewModel.payday);
    if (day != null) viewModel.setPayday(day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(
              Dimens.screenPadding,
              Dimens.gapL,
              Dimens.screenPadding,
              Dimens.screenPadding,
            ),
            children: [
              const ScreenHeader(title: 'Preferences'),
              const SizedBox(height: Dimens.sectionGap),
              _appearance(),
              const SizedBox(height: Dimens.sectionGap),
              _budgeting(context),
              if (viewModel.wallets.isNotEmpty) ...[
                const SizedBox(height: Dimens.sectionGap),
                _addingExpenses(),
              ],
              const SizedBox(height: Dimens.sectionGap),
              _home(),
              const SizedBox(height: Dimens.sectionGap),
              _privacy(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appearance() => PreferenceSection(
    title: 'Appearance',
    children: [
      PreferenceRow(
        title: 'Theme',
        subtitle: 'Follow your phone, or always light or dark',
        below: ThemeChoice(
          selected: viewModel.theme,
          onChanged: viewModel.setTheme,
        ),
      ),
    ],
  );

  Widget _budgeting(BuildContext context) => PreferenceSection(
    title: 'Budgeting',
    children: [
      PreferenceRow(
        title: 'Payday',
        subtitle: viewModel.paydayLabel,
        onTap: () => _pickPayday(context),
      ),
      PreferenceRow(
        title: 'Warn me at',
        subtitle: 'Budgets show "Near limit" once this much is spent',
        below: SegmentedToggle<int>(
          options: [
            for (final percent in viewModel.budgetAlertChoices)
              ToggleOption(value: percent, label: '$percent%'),
          ],
          selected: viewModel.budgetAlertPercent,
          onChanged: viewModel.setBudgetAlertPercent,
        ),
      ),
    ],
  );

  Widget _addingExpenses() => PreferenceSection(
    title: 'Adding expenses',
    children: [
      PreferenceRow(
        title: 'Default wallet',
        subtitle: 'New transactions start with this wallet',
        below: WalletPicker(
          wallets: viewModel.wallets,
          selectedId: viewModel.defaultWalletId,
          onSelected: viewModel.setDefaultWallet,
        ),
      ),
    ],
  );

  Widget _privacy() => PreferenceSection(
    title: 'Privacy',
    children: [
      PreferenceRow(
        title: 'Hide in recent apps',
        subtitle:
            'Shows a blank card in the app switcher and blocks screenshots',
        trailing: Switch(
          value: viewModel.privacyScreen,
          onChanged: viewModel.setPrivacyScreen,
        ),
      ),
    ],
  );

  Widget _home() => PreferenceSection(
    title: 'Home',
    children: [
      PreferenceRow(
        title: 'Show spending habits',
        subtitle: 'A tip about how your spending is going',
        trailing: Switch(
          value: viewModel.showHabitsOnHome,
          onChanged: viewModel.setShowHabitsOnHome,
        ),
      ),
      PreferenceRow(
        title: 'Hide amounts',
        subtitle: 'Cover balances on Home until you tap the eye',
        trailing: Switch(
          value: viewModel.hideAmountsOnHome,
          onChanged: viewModel.setHideAmountsOnHome,
        ),
      ),
    ],
  );
}
