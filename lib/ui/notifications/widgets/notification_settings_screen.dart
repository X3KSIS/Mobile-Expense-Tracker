import 'package:flutter/material.dart';

import '../../core/themes/dimens.dart';
import '../../core/ui/fade_switcher.dart';
import '../../core/ui/form_error_banner.dart';
import '../../core/ui/screen_header.dart';
import '../../preferences/widgets/preference_row.dart';
import '../../preferences/widgets/preference_section.dart';
import '../view_models/notification_settings_view_model.dart';

/// Which reminders the phone shows and which alerts the app lists.
/// Changes apply at once and are saved to the account.
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key, required this.viewModel});

  final NotificationSettingsViewModel viewModel;

  Future<void> _pickTime(BuildContext context) async {
    final minutes = viewModel.reminderMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      helpText: 'Remind me at',
    );
    if (picked != null) viewModel.setReminderTime(picked.hour, picked.minute);
  }

  Future<void> _pickBillTime(BuildContext context) async {
    final minutes = viewModel.billReminderMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      helpText: 'Remind me about bills at',
    );
    if (picked != null) {
      viewModel.setBillReminderTime(picked.hour, picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            viewModel,
            viewModel.setDailyReminder,
            viewModel.setBillReminders,
          ]),
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(
              Dimens.screenPadding,
              Dimens.gapL,
              Dimens.screenPadding,
              Dimens.screenPadding,
            ),
            children: [
              const ScreenHeader(title: 'Notifications'),
              const SizedBox(height: Dimens.sectionGap),
              FadeSwitcher(child: _message()),
              _reminders(context),
              const SizedBox(height: Dimens.sectionGap),
              _inApp(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _message() {
    final message = viewModel.message;
    if (message == null) return const SizedBox.shrink(key: ValueKey('none'));
    return Padding(
      key: ValueKey(message),
      padding: const EdgeInsets.only(bottom: Dimens.sectionGap),
      child: FormErrorBanner(message: message),
    );
  }

  Widget _reminders(BuildContext context) => PreferenceSection(
    title: 'Phone reminders',
    children: [
      PreferenceRow(
        title: 'Daily reminder',
        subtitle:
            'A nudge to record what you spent, skipped on days '
            'you already have',
        trailing: Switch(
          value: viewModel.dailyReminder,
          onChanged: viewModel.setDailyReminder.running
              ? null
              : viewModel.setDailyReminder.execute,
        ),
      ),
      if (viewModel.dailyReminder)
        PreferenceRow(
          title: 'Remind me at',
          subtitle: viewModel.reminderTimeLabel,
          onTap: () => _pickTime(context),
        ),
      PreferenceRow(
        title: 'Bill reminders',
        subtitle:
            'A week before, 3 days before and on the day, then every '
            'morning until marked paid',
        trailing: Switch(
          value: viewModel.billReminders,
          onChanged: viewModel.setBillReminders.running
              ? null
              : viewModel.setBillReminders.execute,
        ),
      ),
      if (viewModel.billReminders)
        PreferenceRow(
          title: 'Bill reminder time',
          subtitle: viewModel.billReminderTimeLabel,
          onTap: () => _pickBillTime(context),
        ),
    ],
  );

  Widget _inApp() => PreferenceSection(
    title: 'In the app',
    children: [
      PreferenceRow(
        title: 'Budget alerts',
        subtitle: 'List budgets that reach your warning level or go over',
        trailing: Switch(
          value: viewModel.budgetAlerts,
          onChanged: viewModel.setBudgetAlerts,
        ),
      ),
    ],
  );
}
