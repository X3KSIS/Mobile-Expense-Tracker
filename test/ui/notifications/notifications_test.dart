import 'package:flutter/material.dart';
import 'package:flutter_expensetracker/data/repositories/detected_payment/detected_payment_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/repositories/reminder/reminder_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/repositories/settings/settings_repository_local_fake.dart';
import 'package:flutter_expensetracker/domain/models/app_notification.dart';
import 'package:flutter_expensetracker/ui/core/themes/theme.dart';
import 'package:flutter_expensetracker/ui/home/view_models/home_view_model.dart';
import 'package:flutter_expensetracker/ui/notifications/view_models/notification_settings_view_model.dart';
import 'package:flutter_expensetracker/ui/notifications/view_models/notifications_view_model.dart';
import 'package:flutter_expensetracker/ui/notifications/widgets/notification_row.dart';
import 'package:flutter_expensetracker/ui/notifications/widgets/notification_settings_screen.dart';
import 'package:flutter_expensetracker/ui/notifications/widgets/notifications_screen.dart';
import 'package:flutter_expensetracker/ui/preferences/widgets/preference_row.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes/fake_repositories.dart';

void main() {
  DetectedPaymentRepositoryLocalFake detected() =>
      DetectedPaymentRepositoryLocalFake(
        enabled: true,
        incoming: sampleMessages,
      );

  NotificationsViewModel inbox(SettingsRepositoryLocalFake settings) {
    final vm = NotificationsViewModel(
      transactionRepository: instantTransactionRepository(),
      budgetRepository: instantBudgetRepository(),
      settingsRepository: settings,
      detectedPaymentRepository: detected(),
    );
    addTearDown(vm.dispose);
    return vm;
  }

  group('NotificationsViewModel', () {
    test('everything is new on the first visit, and earlier after', () async {
      final settings = SettingsRepositoryLocalFake();
      final first = inbox(settings);
      await first.load.execute();
      expect(first.fresh, isNotEmpty);
      expect(first.earlier, isEmpty);
      expect(
        first.fresh.map((n) => n.kind),
        contains(NotificationKind.paymentsToReview),
      );
      expect(settings.notificationsSeenAt, isNotNull);

      final second = inbox(settings);
      await second.load.execute();
      expect(second.fresh, isEmpty);
      expect(second.earlier, hasLength(first.fresh.length));
    });

    test('budget alerts can be left out', () async {
      final settings = SettingsRepositoryLocalFake();
      await settings.setBudgetAlerts(false);
      final vm = inbox(settings);
      await vm.load.execute();
      expect(
        vm.fresh.where(
          (n) =>
              n.kind == NotificationKind.overBudget ||
              n.kind == NotificationKind.nearBudget,
        ),
        isEmpty,
      );
    });
  });

  test('the bell shows a dot until Notifications is opened', () async {
    final settings = SettingsRepositoryLocalFake();
    final home = HomeViewModel(
      transactionRepository: instantTransactionRepository(),
      budgetRepository: instantBudgetRepository(),
      authRepository: instantAuthRepository(signedIn: true),
      settingsRepository: settings,
      walletRepository: instantWalletRepository(),
      detectedPaymentRepository: detected(),
    );
    addTearDown(home.dispose);
    await home.load.execute();
    expect(home.hasUnreadNotifications, isTrue);

    await settings.markNotificationsSeen(DateTime.now());
    expect(home.hasUnreadNotifications, isFalse);
  });

  test('wording for each kind', () {
    final now = DateTime(2026, 11, 28, 18);
    final over = describeNotification(
      AppNotification(
        id: 'o',
        kind: NotificationKind.overBudget,
        subject: 'Groceries',
        at: now,
        amount: 150,
        percent: 115,
      ),
      now,
    );
    expect(over.title, 'Groceries is over budget');
    expect(over.body, 'Over by ZMW 150.00 this pay cycle (115% used).');

    final due = describeNotification(
      AppNotification(
        id: 'd',
        kind: NotificationKind.paymentDueSoon,
        subject: 'DStv Compact',
        at: now,
        amount: 640,
        due: DateTime(2026, 11, 29),
      ),
      now,
    );
    expect(due.title, 'DStv Compact is due tomorrow');
  });

  testWidgets('the page lists what is new', (tester) async {
    final vm = inbox(SettingsRepositoryLocalFake());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: NotificationsScreen(viewModel: vm),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('NEW'), findsOneWidget);
    expect(find.byType(NotificationRow), findsWidgets);
    expect(find.textContaining('to review'), findsOneWidget);
  });

  group('Notification settings', () {
    NotificationSettingsViewModel build(
      SettingsRepositoryLocalFake settings,
      ReminderRepositoryLocalFake reminders,
    ) {
      final vm = NotificationSettingsViewModel(
        settingsRepository: settings,
        reminderRepository: reminders,
      );
      addTearDown(vm.dispose);
      return vm;
    }

    test('a phone reminder asks for permission first', () async {
      final settings = SettingsRepositoryLocalFake();
      final reminders = ReminderRepositoryLocalFake();
      final vm = build(settings, reminders);

      await vm.setDailyReminder.execute(true);
      expect(reminders.requests, 1);
      expect(settings.dailyReminder, isTrue);
      expect(vm.message, isNull);

      vm.setReminderTime(21, 15);
      expect(vm.reminderTimeLabel, '21:15');
    });

    test('a refused permission keeps the reminder off and says why', () async {
      final settings = SettingsRepositoryLocalFake();
      final reminders = ReminderRepositoryLocalFake(grant: false);
      final vm = build(settings, reminders);

      await vm.setBillReminders.execute(true);
      expect(settings.billReminders, isFalse);
      expect(vm.message, NotificationSettingsViewModel.blockedMessage);
    });

    testWidgets('the page turns reminders and alerts on and off', (
      tester,
    ) async {
      final settings = SettingsRepositoryLocalFake();
      final vm = build(settings, ReminderRepositoryLocalFake());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: NotificationSettingsScreen(viewModel: vm),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Remind me at'), findsNothing);

      Finder switchIn(String title) => find.descendant(
        of: find.widgetWithText(PreferenceRow, title),
        matching: find.byType(Switch),
      );
      await tester.tap(switchIn('Daily reminder'));
      await tester.pumpAndSettle();
      expect(settings.dailyReminder, isTrue);
      expect(find.text('Remind me at'), findsOneWidget);
      expect(find.text('20:00'), findsOneWidget);

      await tester.tap(switchIn('Budget alerts'));
      await tester.pumpAndSettle();
      expect(settings.budgetAlerts, isFalse);
    });
  });
}
