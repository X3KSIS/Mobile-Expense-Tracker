import 'package:flutter/material.dart';
import 'package:flutter_expensetracker/data/repositories/app_lock/app_lock_repository.dart';
import 'package:flutter_expensetracker/data/repositories/app_lock/app_lock_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/repositories/settings/settings_repository_local_fake.dart';
import 'package:flutter_expensetracker/domain/models/budget.dart';
import 'package:flutter_expensetracker/domain/models/budget_progress.dart';
import 'package:flutter_expensetracker/domain/models/theme_preference.dart';
import 'package:flutter_expensetracker/domain/models/transaction.dart';
import 'package:flutter_expensetracker/ui/add_transaction/view_models/add_transaction_view_model.dart';
import 'package:flutter_expensetracker/ui/core/themes/theme.dart';
import 'package:flutter_expensetracker/ui/preferences/view_models/preferences_view_model.dart';
import 'package:flutter_expensetracker/ui/preferences/widgets/preference_row.dart';
import 'package:flutter_expensetracker/ui/preferences/widgets/preferences_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes/fake_repositories.dart';

void main() {
  final now = DateTime(2026, 11, 25, 15);

  PreferencesViewModel build(
    SettingsRepositoryLocalFake settings, {
    AppLockRepositoryLocalFake? appLock,
  }) {
    final vm = PreferencesViewModel(
      settingsRepository: settings,
      walletRepository: instantWalletRepository(now: now),
      appLockRepository: appLock ?? AppLockRepositoryLocalFake(),
    );
    addTearDown(vm.dispose);
    return vm;
  }

  group('PreferencesViewModel', () {
    test('saves every preference', () async {
      final settings = SettingsRepositoryLocalFake();
      final vm = build(settings);
      await vm.loadWallets.execute();

      vm.setTheme(ThemePreference.dark);
      vm.setPayday(25);
      vm.setBudgetAlertPercent(90);
      vm.setDefaultWallet(vm.wallets.last);
      vm.setShowHabitsOnHome(false);
      vm.setHideAmountsOnHome(true);
      await pumpEventQueue();

      expect(settings.themePreference, ThemePreference.dark);
      expect(settings.payday, 25);
      expect(vm.paydayLabel, '25th of the month');
      expect(settings.budgetAlertPercent, 90);
      expect(settings.defaultWalletId, vm.wallets.last.id);
      expect(settings.showHabitsOnHome, isFalse);
      expect(settings.hideAmountsOnHome, isTrue);
    });

    test('the default wallet falls back to the first one', () async {
      final settings = SettingsRepositoryLocalFake();
      await settings.setDefaultWalletId('gone');
      final vm = build(settings);
      await vm.loadWallets.execute();

      expect(vm.defaultWalletId, vm.wallets.first.id);
      expect(vm.paydayLabel, '1st (calendar months)');
    });

    test('the app lock turns on only after confirming', () async {
      final settings = SettingsRepositoryLocalFake();
      final appLock = AppLockRepositoryLocalFake(
        problem: AppLockProblem.cancelled,
      );
      final vm = build(settings, appLock: appLock);
      await pumpEventQueue();
      expect(vm.appLockAvailable, isTrue);

      await vm.setAppLock.execute(true);
      expect(settings.appLock, isFalse);
      expect(vm.appLockMessage, isNull, reason: 'closing the prompt is fine');

      appLock.problem = null;
      await vm.setAppLock.execute(true);
      expect(settings.appLock, isTrue);

      appLock.problem = AppLockProblem.failed;
      await vm.setAppLock.execute(false);
      expect(settings.appLock, isFalse, reason: 'off needs no prompt');
      expect(appLock.prompts, 2);
    });

    test('a phone without a screen lock explains why', () async {
      final appLock = AppLockRepositoryLocalFake(
        available: false,
        problem: AppLockProblem.noScreenLock,
      );
      final vm = build(SettingsRepositoryLocalFake(), appLock: appLock);
      await pumpEventQueue();
      expect(vm.appLockAvailable, isFalse);
      await vm.setAppLock.execute(true);
      expect(vm.appLockMessage, 'Set a screen lock on this phone first');
    });

    test('only the offered warning levels are accepted', () async {
      final settings = SettingsRepositoryLocalFake();
      expect(await settings.setBudgetAlertPercent(55), isNotNull);
      expect(settings.budgetAlertPercent, 80);
    });
  });

  test('the warning level decides when a budget is near its limit', () {
    const budget = Budget(
      id: 'b',
      categoryName: 'Groceries',
      categoryIcon: 'groceries',
      categoryColor: 0,
      limit: 1000,
    );
    const spent = BudgetProgress(budget: budget, spent: 750);
    expect(spent.status, BudgetStatus.onTrack);
    expect(
      const BudgetProgress(budget: budget, spent: 750, alertAt: 0.7).status,
      BudgetStatus.nearLimit,
    );
  });

  test('Add transaction starts with the default wallet', () async {
    final vm = AddTransactionViewModel(
      transactionRepository: instantTransactionRepository(now: now),
      categoryRepository: instantCategoryRepository(),
      walletRepository: instantWalletRepository(now: now),
      defaultWalletId: 'w-momo',
      clock: () => now,
    );
    addTearDown(vm.dispose);
    await vm.loadCategories.execute();

    expect(vm.selectedWalletId, 'w-momo');
    expect(vm.type, TransactionType.expense);
  });

  testWidgets('the page changes the theme and Home switches', (tester) async {
    tester.view.physicalSize = const Size(1170, 3200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final settings = SettingsRepositoryLocalFake();
    final vm = build(settings);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PreferencesScreen(viewModel: vm),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Dark theme'));
    await tester.pumpAndSettle();
    expect(settings.themePreference, ThemePreference.dark);

    await tester.tap(find.text('90%'));
    await tester.pumpAndSettle();
    expect(settings.budgetAlertPercent, 90);

    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();
    expect(settings.hideAmountsOnHome, isTrue);

    final privacySwitch = find.descendant(
      of: find.widgetWithText(PreferenceRow, 'Hide in recent apps'),
      matching: find.byType(Switch),
    );
    await tester.ensureVisible(privacySwitch);
    await tester.pumpAndSettle();
    await tester.tap(privacySwitch);
    await tester.pumpAndSettle();
    expect(settings.privacyScreen, isTrue);

    final lockSwitch = find.descendant(
      of: find.widgetWithText(PreferenceRow, 'Lock with fingerprint or PIN'),
      matching: find.byType(Switch),
    );
    await tester.ensureVisible(lockSwitch);
    await tester.pumpAndSettle();
    await tester.tap(lockSwitch);
    await tester.pumpAndSettle();
    expect(settings.appLock, isTrue);
  });
}
