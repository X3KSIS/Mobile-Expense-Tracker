import '../../../domain/models/transaction_category.dart';
import '../../../domain/models/transaction.dart';

/// Mock categories shared by the local fake repositories, so transactions,
/// budgets and the category picker all agree.
abstract final class FakeCategories {
  static const TransactionCategory groceries = TransactionCategory(
    id: 'c-groceries',
    name: 'Groceries',
    icon: 'groceries',
    color: 0xFFE4572E,
    type: TransactionType.expense,
  );
  static const TransactionCategory transport = TransactionCategory(
    id: 'c-transport',
    name: 'Transport',
    icon: 'fuel',
    color: 0xFF2F6FDB,
    type: TransactionType.expense,
  );
  static const TransactionCategory utilities = TransactionCategory(
    id: 'c-utilities',
    name: 'Utilities',
    icon: 'electricity',
    color: 0xFFB7791F,
    type: TransactionType.expense,
  );
  static const TransactionCategory airtime = TransactionCategory(
    id: 'c-airtime',
    name: 'Airtime',
    icon: 'airtime',
    color: 0xFF7A4CD9,
    type: TransactionType.expense,
  );
  static const TransactionCategory housing = TransactionCategory(
    id: 'c-housing',
    name: 'Housing',
    icon: 'housing',
    color: 0xFF1B2A38,
    type: TransactionType.expense,
  );
  static const TransactionCategory eatingOut = TransactionCategory(
    id: 'c-eating-out',
    name: 'Eating out',
    icon: 'eating_out',
    color: 0xFFD9467A,
    type: TransactionType.expense,
  );
  static const TransactionCategory health = TransactionCategory(
    id: 'c-health',
    name: 'Health',
    icon: 'health',
    color: 0xFF1F8A8A,
    type: TransactionType.expense,
  );
  static const TransactionCategory education = TransactionCategory(
    id: 'c-education',
    name: 'Education',
    icon: 'education',
    color: 0xFF4A5FC1,
    type: TransactionType.expense,
  );
  static const TransactionCategory entertainment = TransactionCategory(
    id: 'c-entertainment',
    name: 'Entertainment',
    icon: 'entertainment',
    color: 0xFFC0567F,
    type: TransactionType.expense,
  );
  static const TransactionCategory otherExpense = TransactionCategory(
    id: 'c-other-expense',
    name: 'Other',
    icon: 'other',
    color: 0xFF6B7280,
    type: TransactionType.expense,
  );

  static const TransactionCategory salary = TransactionCategory(
    id: 'c-salary',
    name: 'Salary',
    icon: 'salary',
    color: 0xFF177A4B,
    type: TransactionType.income,
  );
  static const TransactionCategory business = TransactionCategory(
    id: 'c-business',
    name: 'Business',
    icon: 'business',
    color: 0xFF2E8B57,
    type: TransactionType.income,
  );
  static const TransactionCategory gifts = TransactionCategory(
    id: 'c-gifts',
    name: 'Gifts',
    icon: 'gift',
    color: 0xFF8E5BD6,
    type: TransactionType.income,
  );
  static const TransactionCategory otherIncome = TransactionCategory(
    id: 'c-other-income',
    name: 'Other income',
    icon: 'other',
    color: 0xFF6B7280,
    type: TransactionType.income,
  );

  static const List<TransactionCategory> all = [
    groceries,
    transport,
    utilities,
    airtime,
    housing,
    eatingOut,
    health,
    education,
    entertainment,
    otherExpense,
    salary,
    business,
    gifts,
    otherIncome,
  ];
}
