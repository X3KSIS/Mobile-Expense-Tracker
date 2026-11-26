import 'package:flutter_expensetracker/domain/models/recurring_payment.dart';
import 'package:flutter_expensetracker/domain/models/transaction.dart';
import 'package:flutter_expensetracker/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../testing/fakes/fake_repositories.dart';

void main() {
  final now = DateTime(2026, 11, 25, 15);
  var id = 0;

  Transaction pay(
    String title,
    double amount,
    DateTime date, {
    String category = 'Other',
    bool income = false,
  }) => Transaction(
    id: '${id++}',
    title: title,
    categoryName: category,
    categoryIcon: 'other',
    categoryColor: 0,
    amount: amount,
    type: income ? TransactionType.income : TransactionType.expense,
    date: date,
  );

  List<RecurringPayment> detect(List<Transaction> ts) =>
      RecurringPayments.detect(ts, now);

  test('spots a monthly subscription and when it is due', () {
    final found = detect([
      for (var m = 7; m <= 10; m++)
        pay('Netflix', 199, DateTime(2026, m, 28), category: 'Entertainment'),
    ]);

    final netflix = found.single;
    expect(netflix.cadence, Cadence.monthly);
    expect(netflix.kind, RecurringKind.subscription);
    expect(netflix.fixedAmount, isTrue);
    expect(netflix.amount, 199);
    expect(netflix.nextDue, DateTime(2026, 11, 28));
    expect(netflix.status, RecurringStatus.dueSoon);
    expect(netflix.monthlyCost, 199);
  });

  test('a fixed amount without subscription words is a bill', () {
    final rent = detect([
      for (var m = 7; m <= 11; m++)
        pay('Rent', 3500, DateTime(2026, m, 1), category: 'Housing'),
    ]).single;

    expect(rent.kind, RecurringKind.bill);
    expect(rent.nextDue, DateTime(2026, 12, 1));
    expect(rent.status, RecurringStatus.upcoming);
  });

  test('a varying amount on a rhythm is regular spending', () {
    final fuel = detect([
      pay('Fuel', 400, DateTime(2026, 11, 4)),
      pay('Fuel', 520, DateTime(2026, 11, 11)),
      pay('Fuel', 450, DateTime(2026, 11, 18)),
      pay('Fuel', 610, DateTime(2026, 11, 25)),
    ]).single;

    expect(fuel.cadence, Cadence.weekly);
    expect(fuel.kind, RecurringKind.regular);
    expect(fuel.amount, 520);
    expect(fuel.monthlyCost, closeTo(520 * 52 / 12, 0.01));
  });

  test('a missed payment shows as late, a long-stopped one is dropped', () {
    final found = detect([
      // Monthly on the 10th; November's has not been recorded.
      for (var m = 7; m <= 10; m++) pay('Gym', 300, DateTime(2026, m, 10)),
      // Stopped in July.
      for (var m = 4; m <= 7; m++) pay('Magazine', 50, DateTime(2026, m, 3)),
    ]);

    final gym = found.single;
    expect(gym.title, 'Gym');
    expect(gym.status, RecurringStatus.late);
  });

  test('ignores income, irregular spending and too few payments', () {
    expect(
      detect([
        for (var m = 8; m <= 11; m++)
          pay('Salary', 12500, DateTime(2026, m, 25), income: true),
        pay('Shoes', 600, DateTime(2026, 9, 3)),
        pay('Shoes', 450, DateTime(2026, 9, 20)),
        pay('Shoes', 700, DateTime(2026, 11, 22)),
        pay('Bundle', 100, DateTime(2026, 10, 1)),
        pay('Bundle', 100, DateTime(2026, 11, 1)),
      ]),
      isEmpty,
    );
  });

  test('finds the regular payments in the demo data', () async {
    final repo = instantTransactionRepository(now: now);
    final all = (await repo.getTransactions() as Ok<List<Transaction>>).value;

    final found = RecurringPayments.detect(all, now);
    RecurringPayment named(String title) =>
        found.firstWhere((p) => p.title == title);

    expect(named('DStv Compact').kind, RecurringKind.subscription);
    expect(named('DStv Compact').status, RecurringStatus.dueSoon);
    expect(named('MTN airtime').kind, RecurringKind.subscription);
    expect(named('Rent').kind, RecurringKind.bill);
    expect(named('ZESCO units').kind, RecurringKind.bill);
    // Largest monthly cost first.
    expect(found.first.title, 'Rent');
  });
}
