import 'package:flutter_expensetracker/domain/models/transaction.dart';
import 'package:flutter_expensetracker/domain/models/transaction_csv.dart';
import 'package:flutter_expensetracker/ui/export/view_models/export_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../testing/fakes/fake_repositories.dart';

void main() {
  Transaction tx(
    String title,
    double amount, {
    bool income = false,
    String? note,
    DateTime? date,
  }) => Transaction(
    id: title,
    title: title,
    categoryName: income ? 'Salary' : 'Groceries',
    categoryIcon: 'other',
    categoryColor: 0,
    amount: amount,
    type: income ? TransactionType.income : TransactionType.expense,
    date: date ?? DateTime(2026, 11, 20, 9, 5),
    note: note,
    walletId: 'w-cash',
  );

  test('CSV has a header, signed amounts and wallet names', () {
    final csv = TransactionCsv.build(
      [
        tx('Shoprite', 640),
        tx('Salary', 9000, income: true, date: DateTime(2026, 11, 25, 8)),
      ],
      walletNames: {'w-cash': 'Cash'},
    );
    final lines = csv.trim().split('\r\n');
    expect(lines.first, 'Date,Type,Title,Category,Wallet,Amount (ZMW),Note');
    expect(lines[1], '2026-11-25 08:00,Income,Salary,Salary,Cash,9000.00,');
    expect(
      lines[2],
      '2026-11-20 09:05,Expense,Shoprite,Groceries,Cash,-640.00,',
    );
  });

  test('CSV quotes commas and quotes, and defuses formulas', () {
    final csv = TransactionCsv.build([
      tx('Pick n Pay, Manda Hill', 10, note: 'Said "thanks"'),
      tx('=HYPERLINK("x")', 5),
    ]);
    expect(csv, contains('"Pick n Pay, Manda Hill"'));
    expect(csv, contains('"Said ""thanks"""'));
    expect(csv, contains('"\'=HYPERLINK(""x"")"'));
  });

  test('the period decides what is exported', () async {
    final now = DateTime(2026, 11, 25, 15);
    final vm = ExportViewModel(
      transactionRepository: instantTransactionRepository(now: now),
      walletRepository: instantWalletRepository(now: now),
      clock: () => now,
    );
    addTearDown(vm.dispose);
    await vm.load.execute();

    final thisMonth = vm.selected.length;
    expect(vm.selected.every((t) => t.date.month == 11), isTrue);
    vm.selectPeriod(ExportPeriod.all);
    expect(vm.selected.length, greaterThan(thisMonth));
    expect(vm.fileName, 'transactions-2026-11-25.csv');
    expect(vm.buildCsv(), startsWith('Date,Type'));
    expect(vm.buildCsv(), contains('MTN MoMo'));
  });
}
