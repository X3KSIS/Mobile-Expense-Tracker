import '../../../domain/models/transaction_category.dart';
import '../../../domain/models/monthly_summary.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/transaction_draft.dart';
import '../../../utils/result.dart';
import '../category/fake_categories.dart';
import 'transaction_repository.dart';

/// In-memory [TransactionRepository] with realistic ZMW mock data.
///
/// Dates are relative to [now] so "today" and "yesterday" labels look right.
/// The current month always totals income 12,500, expenses 7,680 and net
/// 4,820. Five earlier months of history feed the reports.
class TransactionRepositoryLocalFake extends TransactionRepository {
  TransactionRepositoryLocalFake({
    DateTime? now,
    this.delay = const Duration(milliseconds: 400),
  }) : _now = now ?? DateTime.now();

  final DateTime _now;

  /// Simulated network latency.
  final Duration delay;

  late final List<Transaction> _transactions = [
    ..._currentMonth(_now),
    ..._history(_now),
  ];
  int _nextId = 1;

  List<Transaction> get _sorted =>
      [..._transactions]..sort((a, b) => b.date.compareTo(a.date));

  @override
  Future<Result<List<Transaction>>> getTransactions() async {
    await Future<void>.delayed(delay);
    return Result.ok(List.unmodifiable(_sorted));
  }

  @override
  Future<Result<List<Transaction>>> getRecentTransactions({
    int limit = 5,
  }) async {
    await Future<void>.delayed(delay);
    return Result.ok(List.unmodifiable(_sorted.take(limit)));
  }

  @override
  Future<Result<MonthlySummary>> getMonthlySummary({DateTime? month}) async {
    await Future<void>.delayed(delay);
    final target = month ?? _now;
    var income = 0.0;
    var expenses = 0.0;
    for (final t in _transactions.where((t) => t.isInMonth(target))) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        expenses += t.amount;
      }
    }
    return Result.ok(
      MonthlySummary(
        month: target,
        income: income,
        expenses: expenses,
        net: income - expenses,
      ),
    );
  }

  @override
  Future<Result<Transaction>> addTransaction(TransactionDraft draft) async {
    await Future<void>.delayed(delay);
    final transaction = draft.toTransaction('new-${_nextId++}');
    _transactions.add(transaction);
    notifyListeners();
    return Result.ok(transaction);
  }

  @override
  Future<Result<Transaction>> updateTransaction(
    String id,
    TransactionDraft draft,
  ) async {
    await Future<void>.delayed(delay);
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index < 0) {
      return Result.error(Exception('Transaction $id not found'));
    }
    final transaction = draft.toTransaction(id);
    _transactions[index] = transaction;
    notifyListeners();
    return Result.ok(transaction);
  }

  @override
  Future<Result<void>> deleteTransaction(String id) async {
    await Future<void>.delayed(delay);
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
    return const Result.ok(null);
  }
}

Transaction _make(
  String id,
  String title,
  TransactionCategory category,
  double amount,
  DateTime date,
) => Transaction(
  id: id,
  title: title,
  categoryName: category.name,
  categoryIcon: category.icon,
  categoryColor: category.color,
  amount: amount,
  type: category.type,
  date: date,
  walletId: _walletFor(title, category),
);

/// Which fake wallet (see `WalletRepositoryLocalFake`) a fake transaction
/// uses: airtime and ZESCO from MoMo, small day-to-day spending in cash,
/// everything else through the bank.
String _walletFor(String title, TransactionCategory category) {
  if (category == FakeCategories.airtime ||
      category == FakeCategories.utilities) {
    return 'w-momo';
  }
  if (title == 'Bus fare' ||
      category == FakeCategories.eatingOut ||
      category == FakeCategories.health) {
    return 'w-cash';
  }
  return 'w-bank';
}

/// This month's transactions, newest first. Entries that would fall before
/// the 1st are pulled forward to the start of the month, keeping their
/// order, so the month's totals never change with the date.
List<Transaction> _currentMonth(DateTime now) {
  const c = FakeCategories.groceries;
  final entries = <(String, String, TransactionCategory, double, Duration)>[
    ('t1', 'Shoprite', c, 640, const Duration(hours: 1)),
    ('t2', 'Salary', FakeCategories.salary, 12500, const Duration(hours: 3)),
    ('t3', 'Fuel', FakeCategories.transport, 450, const Duration(days: 1)),
    (
      't4',
      'ZESCO units',
      FakeCategories.utilities,
      300,
      const Duration(days: 2),
    ),
    ('t5', 'MTN airtime', FakeCategories.airtime, 150, const Duration(days: 3)),
    ('t6', 'Bus fare', FakeCategories.transport, 80, const Duration(days: 4)),
    ('t7', 'Pick n Pay', c, 1560, const Duration(days: 7)),
    ('t8', 'Shoprite', c, 1000, const Duration(days: 12)),
    ('t9', 'Rent', FakeCategories.housing, 3500, const Duration(days: 18)),
  ];
  final monthStart = DateTime(now.year, now.month);
  return [
    for (var i = 0; i < entries.length; i++)
      _make(
        entries[i].$1,
        entries[i].$2,
        entries[i].$3,
        entries[i].$4,
        _clamp(now.subtract(entries[i].$5), monthStart, entries.length - i),
      ),
  ];
}

DateTime _clamp(DateTime date, DateTime monthStart, int order) =>
    date.isBefore(monthStart) ? monthStart.add(Duration(minutes: order)) : date;

/// Five earlier months with a realistic, slightly varying pattern.
List<Transaction> _history(DateTime now) {
  const groceries = FakeCategories.groceries;
  const transport = FakeCategories.transport;
  final result = <Transaction>[];
  for (var back = 1; back <= 5; back++) {
    final m = DateTime(now.year, now.month - back);
    DateTime day(int d) => DateTime(m.year, m.month, d, 12);
    // Spending drifts a little from month to month.
    final f = 1 + ((back * 7) % 5 - 2) / 20;
    final id = 'h$back';
    result.addAll([
      _make('$id-1', 'Salary', FakeCategories.salary, 12500, day(25)),
      _make('$id-2', 'Rent', FakeCategories.housing, 3500, day(1)),
      _make('$id-3', 'Shoprite', groceries, (1250 * f).roundToDouble(), day(4)),
      _make(
        '$id-4',
        'Pick n Pay',
        groceries,
        (980 * f).roundToDouble(),
        day(17),
      ),
      _make('$id-5', 'Fuel', transport, (900 * f).roundToDouble(), day(9)),
      _make('$id-6', 'ZESCO units', FakeCategories.utilities, 300, day(6)),
      _make('$id-7', 'MTN airtime', FakeCategories.airtime, 150, day(2)),
      _make(
        '$id-8',
        'Dinner out',
        FakeCategories.eatingOut,
        (420 * f).roundToDouble(),
        day(20),
      ),
      // A subscription, due again late this month.
      _make(
        '$id-12',
        'DStv Compact',
        FakeCategories.entertainment,
        450,
        day(28),
      ),
      if (back.isOdd)
        _make('$id-9', 'Side job', FakeCategories.business, 1800, day(14)),
      if (back == 2)
        _make('$id-10', 'Clinic visit', FakeCategories.health, 350, day(11)),
      if (back == 4)
        _make('$id-11', 'School fees', FakeCategories.education, 2400, day(8)),
    ]);
  }
  return result;
}
