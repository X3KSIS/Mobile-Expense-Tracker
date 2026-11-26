import 'transaction.dart';

/// What a [SpendingInsight] is about.
enum InsightKind {
  /// Total spending against the same point last month.
  pace,

  /// A category costing noticeably more than last month.
  categoryUp,

  /// A category costing noticeably less than last month.
  categoryDown,

  /// A category that has cost more each month for several months.
  risingStreak,

  /// The place money goes most often, e.g. one shop visited repeatedly.
  topPlace,

  /// Many small purchases that add up.
  smallSpends,

  /// The day of the week with the most day-to-day spending.
  busiestDay,
}

/// Whether spending went up, down or held steady.
enum InsightTrend { up, down, steady }

/// One observation about the user's spending habits. Holds numbers only;
/// the UI turns them into words.
class SpendingInsight {
  const SpendingInsight({
    required this.kind,
    required this.trend,
    required this.amount,
    this.previous,
    this.count,
    this.label,
    this.icon,
  });

  final InsightKind kind;
  final InsightTrend trend;

  /// The amount this insight is about in the period, e.g. a category's
  /// spending so far, or the average on the busiest weekday.
  final double amount;

  /// The comparison amount, e.g. the same category last month.
  final double? previous;

  /// A count: visits, small purchases, or months in a streak.
  final int? count;

  /// A category or place name, or the weekday (1 = Monday) as text.
  final String? label;

  /// The category's icon key, when the insight is about a category.
  final String? icon;

  /// Change from [previous] as a fraction (0.25 = 25 % more), or null.
  double? get change => (previous == null || previous! <= 0)
      ? null
      : (amount - previous!) / previous!;

  @override
  String toString() => 'SpendingInsight(${kind.name}, $label, $amount)';
}

/// Works out [SpendingInsight]s from transactions.
abstract final class SpendingInsights {
  /// Categories below this in both periods are too small to compare.
  static const double minCategoryAmount = 100;

  /// A change counts when it is at least this fraction ...
  static const double minChange = 0.10;

  /// ... and at least this many kwacha.
  static const double minChangeAmount = 50;

  /// Total spending within this fraction of last month counts as steady.
  static const double steadyBand = 0.05;

  /// Purchases at or under this are "small".
  static const double smallSpend = 100;
  static const int minSmallSpends = 4;

  /// Day-to-day spending for the weekday pattern leaves out big bills.
  static const double dayToDayLimit = 1000;
  static const int weekdayWindowDays = 90;
  static const int minWeekdaySamples = 12;

  /// The busiest weekday must average this much more than the others.
  static const double weekdayLead = 1.3;

  /// Insights for [month], most worth acting on first.
  ///
  /// For the current month (per [now]) this compares the month so far with
  /// the same days of last month; for past months, whole months.
  static List<SpendingInsight> compute({
    required List<Transaction> transactions,
    required DateTime month,
    required DateTime now,
  }) {
    final expenses = transactions.where((t) => !t.isIncome).toList();
    final start = DateTime(month.year, month.month);
    final isCurrent = start.year == now.year && start.month == now.month;
    final end = isCurrent
        ? DateTime(now.year, now.month, now.day + 1)
        : DateTime(month.year, month.month + 1);
    final prevStart = DateTime(month.year, month.month - 1);
    final prevMonthEnd = DateTime(month.year, month.month);
    final prevEnd = isCurrent
        ? _earlier(
            DateTime(prevStart.year, prevStart.month, now.day + 1),
            prevMonthEnd,
          )
        : prevMonthEnd;

    final current = expenses.where((t) => t.isBetween(start, end)).toList();
    final previous = expenses
        .where((t) => t.isBetween(prevStart, prevEnd))
        .toList();

    final (up, down) = _categoryChanges(current, previous);
    final pace = _pace(current, previous);
    return [
      ?up,
      ?_risingStreak(expenses, start, isCurrent),
      if (pace?.trend == InsightTrend.up) pace!,
      ?_smallSpends(current),
      ?_topPlace(current),
      ?_busiestDay(expenses, end),
      ?down,
      if (pace != null && pace.trend != InsightTrend.up) pace,
    ];
  }

  static DateTime _earlier(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

  static double _sum(Iterable<Transaction> ts) =>
      ts.fold(0, (sum, t) => sum + t.amount);

  static SpendingInsight? _pace(
    List<Transaction> current,
    List<Transaction> previous,
  ) {
    final now = _sum(current);
    final before = _sum(previous);
    if (before <= 0 || now <= 0) return null;
    final change = (now - before) / before;
    return SpendingInsight(
      kind: InsightKind.pace,
      trend: change.abs() < steadyBand
          ? InsightTrend.steady
          : (change > 0 ? InsightTrend.up : InsightTrend.down),
      amount: now,
      previous: before,
    );
  }

  /// The biggest rise and the biggest fall, by amount.
  static (SpendingInsight?, SpendingInsight?) _categoryChanges(
    List<Transaction> current,
    List<Transaction> previous,
  ) {
    final now = _byCategory(current);
    final before = _byCategory(previous);
    final icons = {
      for (final t in [...previous, ...current]) t.categoryName: t.categoryIcon,
    };
    SpendingInsight? up;
    SpendingInsight? down;
    for (final name in {...now.keys, ...before.keys}) {
      final a = now[name] ?? 0;
      final b = before[name] ?? 0;
      if (a < minCategoryAmount && b < minCategoryAmount) continue;
      final delta = a - b;
      final fraction = b <= 0 ? double.infinity : delta.abs() / b;
      if (delta.abs() < minChangeAmount || fraction < minChange) continue;
      final insight = SpendingInsight(
        kind: delta > 0 ? InsightKind.categoryUp : InsightKind.categoryDown,
        trend: delta > 0 ? InsightTrend.up : InsightTrend.down,
        amount: a,
        previous: b,
        label: name,
        icon: icons[name],
      );
      if (delta > 0 && (up == null || delta > up.amount - up.previous!)) {
        up = insight;
      }
      if (delta < 0 && (down == null || delta < down.amount - down.previous!)) {
        down = insight;
      }
    }
    return (up, down);
  }

  static Map<String, double> _byCategory(List<Transaction> ts) {
    final totals = <String, double>{};
    for (final t in ts) {
      totals.update(
        t.categoryName,
        (v) => v + t.amount,
        ifAbsent: () => t.amount,
      );
    }
    return totals;
  }

  /// A category that rose every month for at least three whole months up
  /// to [month] (or up to last month, while [month] is still running).
  static SpendingInsight? _risingStreak(
    List<Transaction> expenses,
    DateTime month,
    bool isCurrent,
  ) {
    final last = isCurrent ? DateTime(month.year, month.month - 1) : month;
    const maxMonths = 6;
    final totals = <String, List<double>>{};
    final icons = <String, String>{};
    for (var i = maxMonths - 1; i >= 0; i--) {
      final m = DateTime(last.year, last.month - i);
      final inMonth = expenses.where(
        (t) => t.isBetween(m, DateTime(m.year, m.month + 1)),
      );
      final byCategory = _byCategory(inMonth.toList());
      for (final t in inMonth) {
        icons[t.categoryName] = t.categoryIcon;
      }
      for (final name in {...totals.keys, ...byCategory.keys}) {
        totals.putIfAbsent(
          name,
          () => List.filled(maxMonths - 1 - i, 0.0, growable: true),
        );
        totals[name]!.add(byCategory[name] ?? 0);
      }
    }
    SpendingInsight? best;
    for (final MapEntry(key: name, value: series) in totals.entries) {
      var run = 1;
      for (var i = series.length - 1; i > 0; i--) {
        if (series[i] > series[i - 1] && series[i - 1] > 0) {
          run++;
        } else {
          break;
        }
      }
      if (run < 3 || series.last < minCategoryAmount) continue;
      if (best == null || run > best.count!) {
        best = SpendingInsight(
          kind: InsightKind.risingStreak,
          trend: InsightTrend.up,
          amount: series.last,
          previous: series[series.length - run],
          count: run,
          label: name,
          icon: icons[name],
        );
      }
    }
    return best;
  }

  /// The place visited at least twice with the most spent there.
  static SpendingInsight? _topPlace(List<Transaction> current) {
    final totals = <String, double>{};
    final visits = <String, int>{};
    final names = <String, String>{};
    final icons = <String, String>{};
    for (final t in current) {
      final title = t.title.trim();
      if (title.isEmpty || title == t.categoryName) continue;
      final key = title.toLowerCase();
      names.putIfAbsent(key, () => title);
      icons.putIfAbsent(key, () => t.categoryIcon);
      totals.update(key, (v) => v + t.amount, ifAbsent: () => t.amount);
      visits.update(key, (v) => v + 1, ifAbsent: () => 1);
    }
    String? best;
    for (final key in totals.keys) {
      if (visits[key]! < 2) continue;
      if (best == null || totals[key]! > totals[best]!) best = key;
    }
    if (best == null) return null;
    return SpendingInsight(
      kind: InsightKind.topPlace,
      trend: InsightTrend.steady,
      amount: totals[best]!,
      count: visits[best],
      label: names[best],
      icon: icons[best],
    );
  }

  static SpendingInsight? _smallSpends(List<Transaction> current) {
    final small = current.where((t) => t.amount <= smallSpend).toList();
    if (small.length < minSmallSpends) return null;
    return SpendingInsight(
      kind: InsightKind.smallSpends,
      trend: InsightTrend.steady,
      amount: _sum(small),
      count: small.length,
    );
  }

  /// The weekday with the highest average day-to-day spending over the
  /// [weekdayWindowDays] days before [end], when it clearly leads.
  static SpendingInsight? _busiestDay(
    List<Transaction> expenses,
    DateTime end,
  ) {
    final start = DateTime(end.year, end.month, end.day - weekdayWindowDays);
    final sample = expenses
        .where((t) => t.isBetween(start, end) && t.amount <= dayToDayLimit)
        .toList();
    if (sample.length < minWeekdaySamples) return null;
    final totals = List<double>.filled(8, 0);
    for (final t in sample) {
      totals[t.date.weekday] += t.amount;
    }
    // Each weekday occurs about window / 7 times.
    const occurrences = weekdayWindowDays / 7;
    final averages = [for (var d = 1; d <= 7; d++) totals[d] / occurrences];
    var top = 0;
    for (var i = 1; i < 7; i++) {
      if (averages[i] > averages[top]) top = i;
    }
    final others = [
      for (var i = 0; i < 7; i++)
        if (i != top) averages[i],
    ];
    final mean = others.fold(0.0, (a, b) => a + b) / others.length;
    if (averages[top] < mean * weekdayLead || averages[top] <= 0) return null;
    return SpendingInsight(
      kind: InsightKind.busiestDay,
      trend: InsightTrend.steady,
      amount: averages[top],
      previous: mean,
      label: '${top + 1}',
    );
  }
}
