import '../../../domain/models/monthly_summary.dart';
import '../../../domain/models/transaction.dart';
import '../../../utils/result.dart';
import 'transaction_repository.dart';

/// In-memory [TransactionRepository] with realistic ZMW mock data.
///
/// Dates are relative to [now] so "today" and "yesterday" labels look right.
/// All mock transactions count towards the current month's summary:
/// income 12,500, expenses 7,680, net 4,820.
class TransactionRepositoryLocalFake implements TransactionRepository {
  TransactionRepositoryLocalFake({
    DateTime? now,
    this.delay = const Duration(milliseconds: 400),
  }) : _now = now ?? DateTime.now();

  final DateTime _now;

  /// Simulated network latency.
  final Duration delay;

  late final List<Transaction> _transactions = _buildTransactions(_now);

  @override
  Future<Result<List<Transaction>>> getRecentTransactions({
    int limit = 5,
  }) async {
    await Future<void>.delayed(delay);
    final sorted = [..._transactions]..sort((a, b) => b.date.compareTo(a.date));
    return Result.ok(List.unmodifiable(sorted.take(limit)));
  }

  @override
  Future<Result<MonthlySummary>> getMonthlySummary() async {
    await Future<void>.delayed(delay);
    var income = 0.0;
    var expenses = 0.0;
    for (final t in _transactions) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        expenses += t.amount;
      }
    }
    return Result.ok(
      MonthlySummary(
        month: _now,
        income: income,
        expenses: expenses,
        net: income - expenses,
      ),
    );
  }
}

const int _groceriesColor = 0xFFE4572E;
const int _salaryColor = 0xFF177A4B;
const int _transportColor = 0xFF2F6FDB;
const int _utilitiesColor = 0xFFB7791F;
const int _airtimeColor = 0xFF7A4CD9;
const int _housingColor = 0xFF1B2A38;

List<Transaction> _buildTransactions(DateTime now) {
  DateTime ago({int days = 0, int hours = 0}) =>
      now.subtract(Duration(days: days, hours: hours));

  return [
    Transaction(
      id: 't1',
      title: 'Shoprite',
      categoryName: 'Groceries',
      categoryIcon: 'groceries',
      categoryColor: _groceriesColor,
      amount: 640,
      type: TransactionType.expense,
      date: ago(hours: 1),
    ),
    Transaction(
      id: 't2',
      title: 'Salary',
      categoryName: 'Income',
      categoryIcon: 'salary',
      categoryColor: _salaryColor,
      amount: 12500,
      type: TransactionType.income,
      date: ago(hours: 3),
    ),
    Transaction(
      id: 't3',
      title: 'Fuel',
      categoryName: 'Transport',
      categoryIcon: 'fuel',
      categoryColor: _transportColor,
      amount: 450,
      type: TransactionType.expense,
      date: ago(days: 1),
    ),
    Transaction(
      id: 't4',
      title: 'ZESCO units',
      categoryName: 'Utilities',
      categoryIcon: 'electricity',
      categoryColor: _utilitiesColor,
      amount: 300,
      type: TransactionType.expense,
      date: ago(days: 2),
    ),
    Transaction(
      id: 't5',
      title: 'MTN airtime',
      categoryName: 'Airtime',
      categoryIcon: 'airtime',
      categoryColor: _airtimeColor,
      amount: 150,
      type: TransactionType.expense,
      date: ago(days: 3),
    ),
    Transaction(
      id: 't6',
      title: 'Bus fare',
      categoryName: 'Transport',
      categoryIcon: 'bus',
      categoryColor: _transportColor,
      amount: 80,
      type: TransactionType.expense,
      date: ago(days: 4),
    ),
    Transaction(
      id: 't7',
      title: 'Pick n Pay',
      categoryName: 'Groceries',
      categoryIcon: 'groceries',
      categoryColor: _groceriesColor,
      amount: 1560,
      type: TransactionType.expense,
      date: ago(days: 7),
    ),
    Transaction(
      id: 't8',
      title: 'Shoprite',
      categoryName: 'Groceries',
      categoryIcon: 'groceries',
      categoryColor: _groceriesColor,
      amount: 1000,
      type: TransactionType.expense,
      date: ago(days: 12),
    ),
    Transaction(
      id: 't9',
      title: 'Rent',
      categoryName: 'Housing',
      categoryIcon: 'housing',
      categoryColor: _housingColor,
      amount: 3500,
      type: TransactionType.expense,
      date: ago(days: 18),
    ),
  ];
}
