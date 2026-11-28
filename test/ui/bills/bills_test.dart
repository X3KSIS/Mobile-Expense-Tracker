import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expensetracker/data/repositories/bill/bill_repository_drift.dart';
import 'package:flutter_expensetracker/data/repositories/bill/bill_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/repositories/settings/settings_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/services/database/app_database.dart';
import 'package:flutter_expensetracker/domain/models/bill.dart';
import 'package:flutter_expensetracker/domain/models/transaction.dart';
import 'package:flutter_expensetracker/ui/bills/view_models/bills_view_model.dart';
import 'package:flutter_expensetracker/ui/bills/widgets/bills_screen.dart';
import 'package:flutter_expensetracker/ui/core/themes/theme.dart';
import 'package:flutter_expensetracker/ui/home/view_models/home_view_model.dart';
import 'package:flutter_expensetracker/data/repositories/detected_payment/detected_payment_repository_local_fake.dart';
import 'package:flutter_expensetracker/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes/fake_repositories.dart';

void main() {
  final now = DateTime(2026, 11, 25, 15);

  Bill bill(String id, String name, DateTime due, {double amount = 450}) =>
      Bill(
        id: id,
        name: name,
        amount: amount,
        categoryName: 'Subscriptions',
        categoryIcon: 'other',
        categoryColor: 0,
        walletId: 'w-cash',
        cadence: BillCadence.monthly,
        nextDue: due,
        anchorDay: due.day,
      );

  final sample = [
    bill('rent', 'Rent', DateTime(2026, 11, 20), amount: 3500),
    bill('dstv', 'DStv Compact', DateTime(2026, 11, 28)),
    bill('school', 'School fees', DateTime(2026, 12, 20), amount: 1200),
  ];

  ({BillsViewModel vm, BillRepositoryLocalFake bills, dynamic transactions})
  build({List<Bill>? bills}) {
    final repo = BillRepositoryLocalFake(bills: bills ?? sample);
    final transactions = instantTransactionRepository(now: now);
    final vm = BillsViewModel(
      billRepository: repo,
      transactionRepository: transactions,
      categoryRepository: instantCategoryRepository(),
      walletRepository: instantWalletRepository(now: now),
      clock: () => now,
    );
    addTearDown(vm.dispose);
    return (vm: vm, bills: repo, transactions: transactions);
  }

  test('splits bills into overdue, this week and later', () async {
    final (:vm, bills: _, transactions: _) = build();
    await vm.load.execute();

    expect(vm.overdue.map((b) => b.name), ['Rent']);
    expect(vm.dueSoon.map((b) => b.name), ['DStv Compact']);
    expect(vm.later.map((b) => b.name), ['School fees']);
    expect(vm.overdueTotal, 3500);
    expect(vm.monthlyTotal, 3500 + 450 + 1200);
  });

  test('marking paid records the expense and moves to the next date', () async {
    final (:vm, :bills, :transactions) = build();
    await vm.load.execute();
    final before =
        ((await transactions.getTransactions()) as Ok<List<Transaction>>)
            .value
            .length;

    await vm.markPaid.execute((bill: vm.overdue.single, record: true));

    final after =
        ((await transactions.getTransactions()) as Ok<List<Transaction>>).value;
    expect(after.length, before + 1);
    expect(after.any((t) => t.title == 'Rent' && t.amount == 3500), isTrue);
    final rent = ((await bills.getBills()) as Ok<List<Bill>>).value.firstWhere(
      (b) => b.id == 'rent',
    );
    expect(rent.nextDue, DateTime(2026, 12, 20));
  });

  test('"already added" only moves the bill on', () async {
    final (:vm, :bills, :transactions) = build();
    await vm.load.execute();
    final before =
        ((await transactions.getTransactions()) as Ok<List<Transaction>>)
            .value
            .length;

    await vm.markPaid.execute((bill: vm.dueSoon.single, record: false));

    final after =
        ((await transactions.getTransactions()) as Ok<List<Transaction>>).value;
    expect(after.length, before);
    await vm.load.execute();
    expect(vm.dueSoon, isEmpty);
  });

  test('saves a new bill on its due day', () async {
    final (:vm, :bills, transactions: _) = build(bills: const []);
    await vm.load.execute();

    await vm.save.execute((
      bill: null,
      name: ' Rent ',
      amount: '3,500',
      category: vm.categories.first,
      walletId: null,
      cadence: BillCadence.monthly,
      nextDue: DateTime(2026, 12, 31, 14),
    ));

    final saved = ((await bills.getBills()) as Ok<List<Bill>>).value.single;
    expect(saved.name, 'Rent');
    expect(saved.amount, 3500);
    expect(saved.nextDue, DateTime(2026, 12, 31));
    expect(saved.anchorDay, 31);
  });

  test('suggests regular payments that are not bills yet', () async {
    final (:vm, bills: _, transactions: _) = build(bills: const []);
    await vm.load.execute();
    final names = vm.suggestions.map((s) => s.name).toList();
    expect(names, contains('DStv Compact'));
    expect(
      vm.suggestions.every((s) => !s.nextDue.isBefore(DateTime(2026, 11, 25))),
      isTrue,
    );

    final (vm: tracked, bills: _, transactions: _) = build();
    await tracked.load.execute();
    expect(
      tracked.suggestions.map((s) => s.name),
      isNot(contains('DStv Compact')),
    );
  });

  test('Home lists overdue bills for its banner', () async {
    final home = HomeViewModel(
      transactionRepository: instantTransactionRepository(now: now),
      budgetRepository: instantBudgetRepository(),
      authRepository: instantAuthRepository(signedIn: true),
      settingsRepository: SettingsRepositoryLocalFake(),
      walletRepository: instantWalletRepository(now: now),
      detectedPaymentRepository: DetectedPaymentRepositoryLocalFake(),
      billRepository: BillRepositoryLocalFake(bills: sample),
      clock: () => now,
    );
    addTearDown(home.dispose);
    await home.load.execute();
    expect(home.overdueBills.map((b) => b.name), ['Rent']);
    expect(home.overdueBillTotal, 3500);
    expect(
      home.notifications.map((n) => n.subject),
      containsAll(['Rent', 'DStv Compact']),
    );
  });

  test('bills are stored in the device database', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = BillRepositoryDrift(db, clock: () => now);
    addTearDown(repo.dispose);

    final saved = await repo.saveBill(sample.first.copyWith(id: ''));
    final id = (saved as Ok<Bill>).value.id;
    expect(id, isNotEmpty);
    final row = await db.select(db.bills).getSingle();
    expect(row.dirty, isTrue);
    expect(row.cadence, 'monthly');

    await repo.deleteBill(id);
    expect(((await repo.getBills()) as Ok<List<Bill>>).value, isEmpty);
    expect((await db.select(db.bills).getSingle()).deleted, isTrue);
  });

  testWidgets('the page puts overdue bills first', (tester) async {
    tester.view.physicalSize = const Size(1170, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final (:vm, bills: _, transactions: _) = build();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BillsScreen(viewModel: vm),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('OVERDUE'), findsOneWidget);
    expect(find.text('5 days overdue'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Rent')).dy,
      lessThan(tester.getTopLeft(find.text('DStv Compact').first).dy),
    );

    await tester.tap(find.text('Rent'));
    await tester.pumpAndSettle();
    expect(find.text('Mark as paid'), findsOneWidget);
    await tester.tap(find.text('Mark as paid'));
    await tester.pumpAndSettle();
    expect(find.text('Rent marked paid. Next due 20 Dec.'), findsOneWidget);
    expect(find.text('OVERDUE'), findsNothing);
  });
}
