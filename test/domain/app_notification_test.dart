import 'package:flutter_expensetracker/domain/models/app_notification.dart';
import 'package:flutter_expensetracker/domain/models/budget.dart';
import 'package:flutter_expensetracker/domain/models/detected_payment.dart';
import 'package:flutter_expensetracker/domain/models/money_message.dart';
import 'package:flutter_expensetracker/domain/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction _expense(
  String id,
  String category,
  double amount,
  DateTime date, {
  String? title,
}) => Transaction(
  id: id,
  title: title ?? category,
  categoryName: category,
  categoryIcon: 'other',
  categoryColor: 0,
  amount: amount,
  type: TransactionType.expense,
  date: date,
);

Budget _budget(String id, String category, double limit) => Budget(
  id: id,
  categoryName: category,
  categoryIcon: 'other',
  categoryColor: 0,
  limit: limit,
);

void main() {
  final now = DateTime(2026, 11, 28, 18);
  final start = DateTime(2026, 11);
  final end = DateTime(2026, 12);

  List<AppNotification> compute({
    List<Budget> budgets = const [],
    List<Transaction> transactions = const [],
    List<DetectedPayment> toReview = const [],
    bool budgetAlerts = true,
  }) => SpendingNotifications.compute(
    budgets: budgets,
    transactions: transactions,
    cycleStart: start,
    cycleEnd: end,
    alertAt: 0.8,
    toReview: toReview,
    now: now,
    budgetAlerts: budgetAlerts,
  );

  test('a budget over its limit dates from the expense that took it over', () {
    final found = compute(
      budgets: [_budget('b1', 'Groceries', 1000)],
      transactions: [
        _expense('1', 'Groceries', 600, DateTime(2026, 11, 3)),
        _expense('2', 'Groceries', 300, DateTime(2026, 11, 10)),
        _expense('3', 'Groceries', 250, DateTime(2026, 11, 20)),
        // Last cycle doesn't count.
        _expense('4', 'Groceries', 900, DateTime(2026, 10, 20)),
      ],
    );
    expect(found, hasLength(1));
    final over = found.single;
    expect(over.kind, NotificationKind.overBudget);
    expect(over.subject, 'Groceries');
    expect(over.at, DateTime(2026, 11, 20));
    expect(over.amount, 150);
    expect(over.percent, 115);
    expect(over.id, 'over:b1:20261101');
  });

  test('a budget at the warning level dates from crossing it', () {
    final found = compute(
      budgets: [_budget('b1', 'Transport', 500)],
      transactions: [
        _expense('1', 'Transport', 300, DateTime(2026, 11, 5)),
        _expense('2', 'Transport', 120, DateTime(2026, 11, 12)),
      ],
    );
    expect(found.single.kind, NotificationKind.nearBudget);
    expect(found.single.at, DateTime(2026, 11, 12));
    expect(found.single.percent, 84);
  });

  test('budget alerts can be turned off', () {
    final found = compute(
      budgets: [_budget('b1', 'Transport', 100)],
      transactions: [_expense('1', 'Transport', 300, DateTime(2026, 11, 5))],
      budgetAlerts: false,
    );
    expect(found, isEmpty);
  });

  test('a regular payment due soon shows from five days before', () {
    final found = compute(
      transactions: [
        for (final month in [8, 9, 10, 11])
          _expense(
            'd$month',
            'Subscriptions',
            640,
            DateTime(2026, month, 1),
            title: 'DStv Compact',
          ),
      ],
    );
    final due = found.single;
    expect(due.kind, NotificationKind.paymentDueSoon);
    expect(due.subject, 'DStv Compact');
    expect(due.due, DateTime(2026, 12, 1));
    expect(due.at, DateTime(2026, 11, 26));
    expect(due.amount, 640);
  });

  test('payments to review show with the latest arrival, newest first', () {
    DetectedPayment payment(String id, DateTime at) => DetectedPayment(
      id: id,
      receivedAt: at,
      message: const MoneyMessage(kind: MoneyMessageKind.spent, amount: 50),
    );
    final found = compute(
      budgets: [_budget('b1', 'Transport', 100)],
      transactions: [_expense('1', 'Transport', 300, DateTime(2026, 11, 5))],
      toReview: [
        payment('a', DateTime(2026, 11, 27, 9)),
        payment('b', DateTime(2026, 11, 28, 8)),
      ],
    );
    expect(found.first.kind, NotificationKind.paymentsToReview);
    expect(found.first.count, 2);
    expect(found.first.at, DateTime(2026, 11, 28, 8));
    expect(found.last.kind, NotificationKind.overBudget);
  });

  test('new means after the last visit', () {
    final n = AppNotification(
      id: 'x',
      kind: NotificationKind.nearBudget,
      subject: 'Food',
      at: DateTime(2026, 11, 20),
    );
    expect(n.isNewSince(null), isTrue);
    expect(n.isNewSince(DateTime(2026, 11, 19)), isTrue);
    expect(n.isNewSince(DateTime(2026, 11, 21)), isFalse);
  });
}
