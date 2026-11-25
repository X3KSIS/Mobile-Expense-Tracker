import 'package:flutter/foundation.dart';

import '../../../data/repositories/transaction/transaction_repository.dart';
import '../../../domain/models/transaction.dart';
import '../../../utils/command.dart';
import '../../../utils/dates.dart';
import '../../../utils/result.dart';

/// Spending in one category for the selected month.
class CategorySpend {
  const CategorySpend({
    required this.name,
    required this.icon,
    required this.color,
    required this.amount,
    required this.share,
  });

  final String name;
  final String icon;
  final int color;
  final double amount;

  /// Fraction of the month's expenses, 0–1.
  final double share;
}

/// Income and expenses for one month.
class MonthTotals {
  const MonthTotals({
    required this.month,
    required this.income,
    required this.expenses,
  });

  /// First day of the month.
  final DateTime month;
  final double income;
  final double expenses;

  double get net => income - expenses;
}

/// Spending on one day, for the heatmap.
class DaySpend {
  const DaySpend({required this.day, required this.amount});

  final DateTime day;
  final double amount;
}

/// State for the Reports tab. Everything is scoped to [month], which the
/// month switcher and the trend chart change. Reloads when transactions
/// change.
class ReportsViewModel extends ChangeNotifier {
  ReportsViewModel({
    required this._transactionRepository,
    DateTime Function()? clock,
    this.trendLength = 6,
  }) : _clock = clock ?? DateTime.now {
    _month = monthOf(_clock());
    _transactionRepository.addListener(_onTransactionsChanged);
    load = Command0<void>(_load)..execute();
  }

  final TransactionRepository _transactionRepository;
  final DateTime Function() _clock;

  /// Months shown in the trend chart, ending with the current month.
  final int trendLength;

  late final Command0<void> load;

  List<Transaction> _all = const [];
  late DateTime _month;
  DateTime? _selectedDay;
  bool _loaded = false;
  bool _disposed = false;

  /// First day of the month being reported on.
  DateTime get month => _month;

  DateTime get currentMonth => monthOf(_clock());

  DateTime get previousMonth => DateTime(_month.year, _month.month - 1);

  bool get canGoForward => _month.isBefore(currentMonth);

  bool get canGoBack => _month.isAfter(_earliestMonth);

  DateTime get _earliestMonth =>
      DateTime(currentMonth.year, currentMonth.month - trendLength + 1);

  bool get isLoading => load.running && !_loaded;

  bool get hasError => load.error && !_loaded;

  MonthTotals get totals => _totalsFor(_month);

  MonthTotals get previousTotals => _totalsFor(previousMonth);

  /// The selected month's expenses by category, largest first.
  List<CategorySpend> get categories {
    final byName = <String, Transaction>{};
    final amounts = <String, double>{};
    for (final t in _inMonth(_month).where((t) => !t.isIncome)) {
      byName.putIfAbsent(t.categoryName, () => t);
      amounts.update(
        t.categoryName,
        (a) => a + t.amount,
        ifAbsent: () => t.amount,
      );
    }
    final total = amounts.values.fold(0.0, (a, b) => a + b);
    final list = [
      for (final entry in amounts.entries)
        CategorySpend(
          name: entry.key,
          icon: byName[entry.key]!.categoryIcon,
          color: byName[entry.key]!.categoryColor,
          amount: entry.value,
          share: total == 0 ? 0 : entry.value / total,
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  /// The last [trendLength] months, oldest first.
  List<MonthTotals> get trend => [
    for (var i = trendLength - 1; i >= 0; i--)
      _totalsFor(DateTime(currentMonth.year, currentMonth.month - i)),
  ];

  /// Spending for every day of the selected month, in order.
  List<DaySpend> get days {
    final lastDay = DateTime(_month.year, _month.month + 1, 0).day;
    final totals = List<double>.filled(lastDay, 0);
    for (final t in _inMonth(_month).where((t) => !t.isIncome)) {
      totals[t.date.day - 1] += t.amount;
    }
    return [
      for (var d = 1; d <= lastDay; d++)
        DaySpend(
          day: DateTime(_month.year, _month.month, d),
          amount: totals[d - 1],
        ),
    ];
  }

  /// The heatmap day the user tapped, or null.
  DaySpend? get selectedDay {
    final day = _selectedDay;
    if (day == null) return null;
    return days.firstWhere((d) => d.day == day);
  }

  /// Days after today in the current month have not happened yet.
  bool isFuture(DateTime day) => day.isAfter(dateOnly(_clock()));

  void goBack() {
    if (canGoBack) _setMonth(previousMonth);
  }

  void goForward() {
    if (canGoForward) _setMonth(DateTime(_month.year, _month.month + 1));
  }

  void selectMonth(DateTime month) => _setMonth(monthOf(month));

  void selectDay(DateTime day) {
    _selectedDay = _selectedDay == day ? null : day;
    _notify();
  }

  void _setMonth(DateTime month) {
    if (month == _month) return;
    _month = month;
    _selectedDay = null;
    _notify();
  }

  Iterable<Transaction> _inMonth(DateTime month) =>
      _all.where((t) => t.isInMonth(month));

  MonthTotals _totalsFor(DateTime month) {
    var income = 0.0;
    var expenses = 0.0;
    for (final t in _inMonth(month)) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        expenses += t.amount;
      }
    }
    return MonthTotals(month: month, income: income, expenses: expenses);
  }

  void _onTransactionsChanged() {
    if (!_disposed) load.execute();
  }

  Future<Result<void>> _load() async {
    final result = await _transactionRepository.getTransactions();
    switch (result) {
      case Ok(:final value):
        _all = value;
        _loaded = true;
        _notify();
        return const Result.ok(null);
      case Error(:final error):
        _notify();
        return Result.error(error);
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _transactionRepository.removeListener(_onTransactionsChanged);
    load.dispose();
    super.dispose();
  }
}
