import 'pay_cycle.dart';
import 'transaction.dart';

/// Will the money last until payday?
enum ForecastStatus {
  /// At the current pace the money lasts past payday.
  onTrack,

  /// It runs out in the last few days before payday.
  tight,

  /// It runs out well before payday.
  short,

  /// Nothing left to spend.
  empty,
}

/// How much can be spent each day until payday, and whether the money
/// lasts at the current pace.
class CycleForecast {
  const CycleForecast({
    required this.cycle,
    required this.balance,
    required this.safePerDay,
    required this.averagePerDay,
    required this.runsOutOn,
    required this.status,
  });

  /// Running out within this many days of payday counts as tight.
  static const int tightDays = 3;

  final PayCycle cycle;

  /// Money held now, across wallets.
  final double balance;

  /// [balance] spread evenly over the days left, counting today.
  final double safePerDay;

  /// Average spent per day so far this cycle.
  final double averagePerDay;

  /// The day the money runs out at [averagePerDay], or null when nothing
  /// has been spent yet.
  final DateTime? runsOutOn;

  final ForecastStatus status;

  /// The next payday.
  DateTime get payday => cycle.end;

  /// Works out the forecast from the money held now and this cycle's
  /// expenses up to [now].
  factory CycleForecast.compute({
    required PayCycle cycle,
    required DateTime now,
    required double balance,
    required List<Transaction> transactions,
  }) {
    final spent = transactions
        .where(
          (t) => !t.isIncome && cycle.contains(t.date) && !t.date.isAfter(now),
        )
        .fold<double>(0, (sum, t) => sum + t.amount);
    final daysLeft = cycle.daysLeft(now);
    final average = spent / cycle.daysElapsed(now);
    final today = DateTime(now.year, now.month, now.day);

    DateTime? runsOut;
    if (balance <= 0) {
      runsOut = today;
    } else if (average > 0) {
      runsOut = DateTime(
        today.year,
        today.month,
        today.day + (balance / average).floor(),
      );
    }

    final ForecastStatus status;
    if (balance <= 0) {
      status = ForecastStatus.empty;
    } else if (runsOut == null || !runsOut.isBefore(cycle.end)) {
      status = ForecastStatus.onTrack;
    } else if (cycle.end.difference(runsOut).inDays <= tightDays) {
      status = ForecastStatus.tight;
    } else {
      status = ForecastStatus.short;
    }

    return CycleForecast(
      cycle: cycle,
      balance: balance,
      safePerDay: balance <= 0 ? 0 : balance / daysLeft,
      averagePerDay: average,
      runsOutOn: runsOut,
      status: status,
    );
  }
}
