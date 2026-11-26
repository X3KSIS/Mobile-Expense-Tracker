import 'transaction.dart';

/// How often a payment repeats.
enum Cadence {
  weekly(days: 7, minDays: 6, maxDays: 8, perMonth: 52 / 12),
  fortnightly(days: 14, minDays: 12, maxDays: 16, perMonth: 26 / 12),
  monthly(days: 30, minDays: 26, maxDays: 35, perMonth: 1);

  const Cadence({
    required this.days,
    required this.minDays,
    required this.maxDays,
    required this.perMonth,
  });

  /// Typical gap between payments.
  final int days;

  /// Gaps in this range count as on rhythm.
  final int minDays;
  final int maxDays;

  /// Payments in an average month.
  final double perMonth;
}

/// What kind of repeat payment it is.
enum RecurringKind {
  /// A fixed amount for a service: DStv, Netflix, data bundles, a gym.
  subscription,

  /// A fixed amount for a bill: rent, ZESCO units, school fees.
  bill,

  /// A repeat purchase whose amount varies: fuel, the monthly big shop.
  regular,
}

/// Where a repeat payment stands today.
enum RecurringStatus {
  /// Next one is a while off.
  upcoming,

  /// Next one is due within [RecurringPayments.dueSoonDays] days.
  dueSoon,

  /// The usual date has passed without it being recorded.
  late,
}

/// A payment that repeats on a rhythm, found in the transaction history.
class RecurringPayment {
  const RecurringPayment({
    required this.title,
    required this.categoryName,
    required this.categoryIcon,
    required this.cadence,
    required this.kind,
    required this.amount,
    required this.fixedAmount,
    required this.occurrences,
    required this.lastDate,
    required this.nextDue,
    required this.status,
  });

  final String title;
  final String categoryName;
  final String categoryIcon;
  final Cadence cadence;
  final RecurringKind kind;

  /// The usual amount (the median of past payments).
  final double amount;

  /// Whether the amount barely changes from one payment to the next.
  final bool fixedAmount;

  /// How many times it has been paid.
  final int occurrences;
  final DateTime lastDate;

  /// When the next payment is expected (midnight).
  final DateTime nextDue;
  final RecurringStatus status;

  /// What it costs in an average month.
  double get monthlyCost => amount * cadence.perMonth;

  @override
  String toString() =>
      'RecurringPayment($title, ${cadence.name}, ${kind.name}, $amount)';
}

/// Finds [RecurringPayment]s in a transaction history.
abstract final class RecurringPayments {
  /// At least this many payments before a rhythm counts.
  static const int minOccurrences = 3;

  /// This share of the gaps must fit the rhythm.
  static const double minOnRhythm = 0.7;

  /// Amounts within this fraction of the median count as fixed.
  static const double fixedTolerance = 0.1;

  /// A payment is "due soon" within this many days.
  static const int dueSoonDays = 5;

  /// Only the last this-many days of history are considered.
  static const int lookbackDays = 200;

  /// Words that mark a fixed payment as a subscription rather than a bill.
  static final RegExp _subscriptionWords = RegExp(
    r'dstv|gotv|netflix|showmax|spotify|youtube|apple|google|icloud|'
    r'bundle|airtime|data|internet|wifi|fibre|gym|insurance|subscription|'
    r'membership|zamtel|airtel|mtn',
    caseSensitive: false,
  );

  /// Repeat payments still going as of [now], largest monthly cost first.
  static List<RecurringPayment> detect(
    List<Transaction> transactions,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    final since = today.subtract(const Duration(days: lookbackDays));
    final groups = <String, List<Transaction>>{};
    for (final t in transactions) {
      if (t.isIncome || t.date.isBefore(since) || t.date.isAfter(now)) {
        continue;
      }
      groups.putIfAbsent(_key(t), () => []).add(t);
    }

    final found = <RecurringPayment>[];
    for (final payments in groups.values) {
      final payment = _analyse(payments, today);
      if (payment != null) found.add(payment);
    }
    return found..sort((a, b) => b.monthlyCost.compareTo(a.monthlyCost));
  }

  /// Payments to the same place group together; generic entries named
  /// after their category ("Rent") group within the category.
  static String _key(Transaction t) {
    final title = t.title.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return '${t.categoryName.toLowerCase()}|$title';
  }

  static RecurringPayment? _analyse(
    List<Transaction> payments,
    DateTime today,
  ) {
    if (payments.length < minOccurrences) return null;
    payments.sort((a, b) => a.date.compareTo(b.date));
    final gaps = [
      for (var i = 1; i < payments.length; i++)
        _days(payments[i - 1].date, payments[i].date),
    ];

    Cadence? cadence;
    for (final c in Cadence.values) {
      final onRhythm = gaps.where((g) => g >= c.minDays && g <= c.maxDays);
      if (onRhythm.length / gaps.length >= minOnRhythm) {
        cadence = c;
        break;
      }
    }
    if (cadence == null) return null;

    final last = payments.last;
    final sinceLast = _days(last.date, today);
    // Gone quiet for well over one cycle: probably stopped.
    if (sinceLast > cadence.maxDays + cadence.days ~/ 2) return null;

    final amounts = [for (final p in payments) p.amount]..sort();
    final median = amounts[amounts.length ~/ 2];
    final fixed = amounts.every(
      (a) => (a - median).abs() <= median * fixedTolerance,
    );
    final kind = !fixed
        ? RecurringKind.regular
        : (_subscriptionWords.hasMatch(last.title) ||
              last.categoryName == 'Entertainment' ||
              last.categoryName == 'Airtime')
        ? RecurringKind.subscription
        : RecurringKind.bill;

    final lastDay = DateTime(last.date.year, last.date.month, last.date.day);
    final nextDue = cadence == Cadence.monthly
        ? _sameDayNextMonth(lastDay)
        : lastDay.add(Duration(days: cadence.days));
    final untilDue = _days(today, nextDue);
    final status = untilDue < 0
        ? RecurringStatus.late
        : untilDue <= dueSoonDays
        ? RecurringStatus.dueSoon
        : RecurringStatus.upcoming;

    return RecurringPayment(
      title: last.title.trim(),
      categoryName: last.categoryName,
      categoryIcon: last.categoryIcon,
      cadence: cadence,
      kind: kind,
      amount: median,
      fixedAmount: fixed,
      occurrences: payments.length,
      lastDate: last.date,
      nextDue: nextDue,
      status: status,
    );
  }

  /// The same day next month, or the month's last day when it is shorter.
  static DateTime _sameDayNextMonth(DateTime d) {
    final lastDayNext = DateTime(d.year, d.month + 2, 0).day;
    final day = d.day > lastDayNext ? lastDayNext : d.day;
    return DateTime(d.year, d.month + 1, day);
  }

  /// Whole calendar days from [a] to [b], safe across daylight saving.
  static int _days(DateTime a, DateTime b) => DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

  /// Total monthly cost of [payments].
  static double monthlyTotal(Iterable<RecurringPayment> payments) =>
      payments.fold(0, (sum, p) => sum + p.monthlyCost);
}
