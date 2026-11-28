import 'budget.dart';
import 'detected_payment.dart';
import 'recurring_payment.dart';
import 'transaction.dart';

/// What a notification is about.
enum NotificationKind {
  /// A budget went over its limit this pay cycle.
  overBudget,

  /// A budget reached the warning level this pay cycle.
  nearBudget,

  /// A regular payment's usual date has passed without it.
  paymentLate,

  /// A regular payment is due within a few days.
  paymentDueSoon,

  /// Payments read from messages are waiting to be added.
  paymentsToReview,
}

/// Something about the user's spending worth a look, worked out from
/// their data (nothing is stored but when they last looked).
///
/// [at] is when it became true, e.g. the expense that took a budget over
/// its limit, so the app can tell what is new since the user last looked.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.subject,
    required this.at,
    this.amount = 0,
    this.percent = 0,
    this.count = 0,
    this.due,
  });

  /// Stable for the same event, e.g. `over:<budget id>:<cycle start>`.
  final String id;
  final NotificationKind kind;

  /// The budget's category, or the regular payment's title.
  final String subject;
  final DateTime at;

  /// Over the limit by, or the usual payment amount.
  final double amount;

  /// How much of the budget is used, e.g. 85.
  final int percent;

  /// How many payments wait to be reviewed.
  final int count;

  /// A regular payment's due date.
  final DateTime? due;

  bool isNewSince(DateTime? seenAt) => seenAt == null || at.isAfter(seenAt);

  @override
  bool operator ==(Object other) =>
      other is AppNotification &&
      other.id == id &&
      other.at == at &&
      other.amount == amount &&
      other.percent == percent &&
      other.count == count;

  @override
  int get hashCode => Object.hash(id, at, amount, percent, count);
}

/// Works out the notifications from budgets, expenses, regular payments
/// and payments waiting for review.
abstract final class SpendingNotifications {
  /// Newest first.
  ///
  /// Budgets are measured over the pay cycle from [cycleStart] (inclusive)
  /// to [cycleEnd] (exclusive), warning at [alertAt] of the limit. Budget
  /// notifications are left out when [budgetAlerts] is false.
  static List<AppNotification> compute({
    required List<Budget> budgets,
    required List<Transaction> transactions,
    required DateTime cycleStart,
    required DateTime cycleEnd,
    required double alertAt,
    required List<DetectedPayment> toReview,
    required DateTime now,
    bool budgetAlerts = true,
  }) {
    final found = <AppNotification>[
      if (budgetAlerts)
        ..._budgets(budgets, transactions, cycleStart, cycleEnd, alertAt),
      ..._payments(RecurringPayments.detect(transactions, now)),
      ?_review(toReview),
    ];
    // Nothing from the future, e.g. a payment due later than "soon".
    found.removeWhere((n) => n.at.isAfter(now));
    found.sort((a, b) => b.at.compareTo(a.at));
    return found;
  }

  static Iterable<AppNotification> _budgets(
    List<Budget> budgets,
    List<Transaction> transactions,
    DateTime start,
    DateTime end,
    double alertAt,
  ) sync* {
    final key = _day(start);
    for (final budget in budgets) {
      if (budget.limit <= 0) continue;
      final spending =
          transactions
              .where(
                (t) =>
                    t.type == TransactionType.expense &&
                    t.categoryName == budget.categoryName &&
                    !t.date.isBefore(start) &&
                    t.date.isBefore(end),
              )
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));
      var spent = 0.0;
      DateTime? reachedWarning;
      DateTime? wentOver;
      for (final t in spending) {
        spent += t.amount;
        if (reachedWarning == null && spent >= budget.limit * alertAt) {
          reachedWarning = t.date;
        }
        if (wentOver == null && spent > budget.limit) wentOver = t.date;
      }
      final percent = (spent / budget.limit * 100).round();
      if (wentOver != null) {
        yield AppNotification(
          id: 'over:${budget.id}:$key',
          kind: NotificationKind.overBudget,
          subject: budget.categoryName,
          at: wentOver,
          amount: spent - budget.limit,
          percent: percent,
        );
      } else if (reachedWarning != null) {
        yield AppNotification(
          id: 'near:${budget.id}:$key',
          kind: NotificationKind.nearBudget,
          subject: budget.categoryName,
          at: reachedWarning,
          percent: percent,
        );
      }
    }
  }

  static Iterable<AppNotification> _payments(
    List<RecurringPayment> payments,
  ) sync* {
    for (final p in payments) {
      final due = p.nextDue;
      final key = '${p.title.toLowerCase()}:${_day(due)}';
      switch (p.status) {
        case RecurringStatus.late:
          yield AppNotification(
            id: 'late:$key',
            kind: NotificationKind.paymentLate,
            subject: p.title,
            at: due.add(const Duration(days: 1)),
            amount: p.amount,
            due: due,
          );
        case RecurringStatus.dueSoon:
          yield AppNotification(
            id: 'due:$key',
            kind: NotificationKind.paymentDueSoon,
            subject: p.title,
            at: due.subtract(
              const Duration(days: RecurringPayments.dueSoonDays),
            ),
            amount: p.amount,
            due: due,
          );
        case RecurringStatus.upcoming:
          break;
      }
    }
  }

  static AppNotification? _review(List<DetectedPayment> pending) {
    if (pending.isEmpty) return null;
    final latest = pending
        .map((p) => p.receivedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return AppNotification(
      id: 'review',
      kind: NotificationKind.paymentsToReview,
      subject: '',
      at: latest,
      count: pending.length,
    );
  }

  static String _day(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}'
      '${d.day.toString().padLeft(2, '0')}';
}
