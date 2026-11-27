import 'transaction.dart';

/// Spending in one category during one month.
class CategoryMonth {
  const CategoryMonth({
    required this.month,
    required this.amount,
    required this.count,
  });

  /// First day of the month.
  final DateTime month;
  final double amount;

  /// Number of expenses.
  final int count;
}

/// Spending in one category at one place during a month.
class PlaceSpend {
  const PlaceSpend({
    required this.title,
    required this.amount,
    required this.count,
  });

  final String title;
  final double amount;
  final int count;

  double get average => count == 0 ? 0 : amount / count;
}

/// How spending in one category has moved over recent months, and how the
/// selected month compares with a usual one.
class CategoryTrend {
  const CategoryTrend({
    required this.categoryName,
    required this.categoryIcon,
    required this.months,
    required this.month,
    required this.monthToDate,
    required this.spent,
    required this.usual,
    required this.usualMonths,
    required this.places,
    required this.transactions,
  });

  final String categoryName;
  final String categoryIcon;

  /// The trend window, oldest first.
  final List<CategoryMonth> months;

  /// The month being looked at (first day).
  final DateTime month;

  /// True when [month] is still running, so [spent] and [usual] stop at
  /// today's day of the month.
  final bool monthToDate;

  /// Spent in [month] (so far, when [monthToDate]).
  final double spent;

  /// The average of the months before [month] in the window that had any
  /// spending in this category, up to the same day when [monthToDate].
  /// Null when there is no earlier month to compare with.
  final double? usual;

  /// How many months [usual] is the average of.
  final int usualMonths;

  /// Where the money went in [month], largest first.
  final List<PlaceSpend> places;

  /// The category's expenses in [month], newest first.
  final List<Transaction> transactions;

  /// [spent] minus [usual], or null without a [usual].
  double? get difference => usual == null ? null : spent - usual!;

  /// The change against [usual] as a fraction (0.25 = 25% more), or null
  /// when there is nothing to compare with.
  double? get change {
    final u = usual;
    if (u == null || u == 0) return null;
    return (spent - u) / u;
  }

  /// The month in the window with the most spending, or null if none.
  CategoryMonth? get peak {
    CategoryMonth? best;
    for (final m in months) {
      if (m.amount > 0 && (best == null || m.amount > best.amount)) best = m;
    }
    return best;
  }
}

/// Builds [CategoryTrend]s from a transaction history.
abstract final class CategoryTrends {
  /// Changes smaller than this fraction count as "about usual".
  static const double steadyTolerance = 0.1;

  /// The trend for [categoryName] over the [length] months ending with the
  /// current month (from [now]), looking closely at [month].
  ///
  /// Returns null when the category has no expenses in the window.
  static CategoryTrend? compute({
    required List<Transaction> transactions,
    required String categoryName,
    required DateTime month,
    required DateTime now,
    int length = 6,
  }) {
    final current = DateTime(now.year, now.month);
    final start = DateTime(current.year, current.month - length + 1);
    final selected = DateTime(month.year, month.month);
    final inCategory = [
      for (final t in transactions)
        if (!t.isIncome &&
            t.categoryName == categoryName &&
            !t.date.isBefore(start) &&
            !t.date.isAfter(now))
          t,
    ];
    if (inCategory.isEmpty) return null;

    final months = [
      for (var i = 0; i < length; i++)
        _monthOf(inCategory, DateTime(start.year, start.month + i)),
    ];

    final monthToDate = selected == current;
    final cutOffDay = monthToDate ? now.day : null;
    final inSelected = inCategory.where((t) => _isInMonth(t, selected));
    final spent = _sum(inSelected);

    final earlier = [
      for (final m in months)
        if (m.month.isBefore(selected) && m.amount > 0) m.month,
    ];
    final usual = earlier.isEmpty
        ? null
        : earlier
                  .map(
                    (m) => _sum(
                      inCategory.where(
                        (t) =>
                            _isInMonth(t, m) &&
                            (cutOffDay == null || t.date.day <= cutOffDay),
                      ),
                    ),
                  )
                  .fold(0.0, (a, b) => a + b) /
              earlier.length;

    final latest = inCategory.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
    return CategoryTrend(
      categoryName: categoryName,
      categoryIcon: latest.categoryIcon,
      months: months,
      month: selected,
      monthToDate: monthToDate,
      spent: spent,
      usual: usual,
      usualMonths: earlier.length,
      places: _places(inSelected),
      transactions: inSelected.toList()
        ..sort((a, b) => b.date.compareTo(a.date)),
    );
  }

  static CategoryMonth _monthOf(List<Transaction> all, DateTime month) {
    final inMonth = all.where((t) => _isInMonth(t, month)).toList();
    return CategoryMonth(
      month: month,
      amount: _sum(inMonth),
      count: inMonth.length,
    );
  }

  /// Groups by title, ignoring case and extra spaces; shows the title as
  /// it was last written.
  static List<PlaceSpend> _places(Iterable<Transaction> list) {
    final titles = <String, String>{};
    final latest = <String, DateTime>{};
    final amounts = <String, double>{};
    final counts = <String, int>{};
    for (final t in list) {
      final title = t.title.trim();
      final key = title.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      if (latest[key] == null || t.date.isAfter(latest[key]!)) {
        latest[key] = t.date;
        titles[key] = title;
      }
      amounts.update(key, (a) => a + t.amount, ifAbsent: () => t.amount);
      counts.update(key, (c) => c + 1, ifAbsent: () => 1);
    }
    return [
      for (final key in amounts.keys)
        PlaceSpend(
          title: titles[key]!,
          amount: amounts[key]!,
          count: counts[key]!,
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
  }

  static bool _isInMonth(Transaction t, DateTime month) =>
      t.date.year == month.year && t.date.month == month.month;

  static double _sum(Iterable<Transaction> list) =>
      list.fold(0.0, (a, t) => a + t.amount);
}
