import '../../../domain/models/category.dart';
import '../../../domain/models/transaction.dart';

/// Mock categories shared by the local fake repositories, so transactions,
/// budgets and the category picker all agree.
abstract final class FakeCategories {
  static const Category groceries = Category(
    id: 'c-groceries',
    name: 'Groceries',
    icon: 'groceries',
    color: 0xFFE4572E,
    type: TransactionType.expense,
  );
  static const Category transport = Category(
    id: 'c-transport',
    name: 'Transport',
    icon: 'fuel',
    color: 0xFF2F6FDB,
    type: TransactionType.expense,
  );
  static const Category utilities = Category(
    id: 'c-utilities',
    name: 'Utilities',
    icon: 'electricity',
    color: 0xFFB7791F,
    type: TransactionType.expense,
  );
  static const Category airtime = Category(
    id: 'c-airtime',
    name: 'Airtime',
    icon: 'airtime',
    color: 0xFF7A4CD9,
    type: TransactionType.expense,
  );
  static const Category housing = Category(
    id: 'c-housing',
    name: 'Housing',
    icon: 'housing',
    color: 0xFF1B2A38,
    type: TransactionType.expense,
  );
  static const Category eatingOut = Category(
    id: 'c-eating-out',
    name: 'Eating out',
    icon: 'eating_out',
    color: 0xFFD9467A,
    type: TransactionType.expense,
  );
  static const Category health = Category(
    id: 'c-health',
    name: 'Health',
    icon: 'health',
    color: 0xFF1F8A8A,
    type: TransactionType.expense,
  );
  static const Category education = Category(
    id: 'c-education',
    name: 'Education',
    icon: 'education',
    color: 0xFF4A5FC1,
    type: TransactionType.expense,
  );
  static const Category entertainment = Category(
    id: 'c-entertainment',
    name: 'Entertainment',
    icon: 'entertainment',
    color: 0xFFC0567F,
    type: TransactionType.expense,
  );
  static const Category otherExpense = Category(
    id: 'c-other-expense',
    name: 'Other',
    icon: 'other',
    color: 0xFF6B7280,
    type: TransactionType.expense,
  );

  static const Category salary = Category(
    id: 'c-salary',
    name: 'Salary',
    icon: 'salary',
    color: 0xFF177A4B,
    type: TransactionType.income,
  );
  static const Category business = Category(
    id: 'c-business',
    name: 'Business',
    icon: 'business',
    color: 0xFF2E8B57,
    type: TransactionType.income,
  );
  static const Category gifts = Category(
    id: 'c-gifts',
    name: 'Gifts',
    icon: 'gift',
    color: 0xFF8E5BD6,
    type: TransactionType.income,
  );
  static const Category otherIncome = Category(
    id: 'c-other-income',
    name: 'Other income',
    icon: 'other',
    color: 0xFF6B7280,
    type: TransactionType.income,
  );

  static const List<Category> all = [
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
