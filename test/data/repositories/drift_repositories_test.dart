import 'package:drift/native.dart';
import 'package:flutter_expensetracker/data/repositories/budget/budget_repository_drift.dart';
import 'package:flutter_expensetracker/data/repositories/category/category_repository_drift.dart';
import 'package:flutter_expensetracker/data/repositories/category/default_categories.dart';
import 'package:flutter_expensetracker/data/repositories/settings/settings_repository_drift.dart';
import 'package:flutter_expensetracker/data/repositories/transaction/transaction_repository_drift.dart';
import 'package:flutter_expensetracker/data/repositories/wallet/wallet_repository_drift.dart';
import 'package:flutter_expensetracker/data/services/database/app_database.dart';
import 'package:flutter_expensetracker/domain/models/budget.dart';
import 'package:flutter_expensetracker/domain/models/theme_preference.dart';
import 'package:flutter_expensetracker/domain/models/transaction.dart';
import 'package:flutter_expensetracker/domain/models/transaction_category.dart';
import 'package:flutter_expensetracker/domain/models/transaction_draft.dart';
import 'package:flutter_expensetracker/domain/models/transfer.dart';
import 'package:flutter_expensetracker/domain/models/wallet.dart';
import 'package:flutter_expensetracker/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

T _ok<T>(Result<T> result) => (result as Ok<T>).value;

void main() {
  late AppDatabase db;
  final now = DateTime(2026, 11, 27, 9);

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('transactions', () {
    late TransactionRepositoryDrift repo;

    setUp(() => repo = TransactionRepositoryDrift(db, clock: () => now));
    tearDown(() => repo.dispose());

    TransactionDraft draft(
      double amount,
      DateTime date, {
      bool income = false,
    }) => TransactionDraft(
      title: '',
      amount: amount,
      category: income ? DefaultCategories.salary : DefaultCategories.groceries,
      date: date,
      note: '  ',
    );

    test('saves, lists newest first and totals a month', () async {
      await repo.addTransaction(draft(100, DateTime(2026, 11, 2)));
      await repo.addTransaction(draft(250, DateTime(2026, 11, 20)));
      await repo.addTransaction(
        draft(9000, DateTime(2026, 11, 25), income: true),
      );
      await repo.addTransaction(draft(70, DateTime(2026, 10, 30)));

      final all = _ok(await repo.getTransactions());
      expect(all.map((t) => t.amount), [9000, 250, 100, 70]);
      expect(all.first.title, 'Salary');
      expect(all.first.note, isNull);
      expect(_ok(await repo.getRecentTransactions(limit: 2)), hasLength(2));

      final summary = _ok(
        await repo.getMonthlySummary(month: DateTime(2026, 11)),
      );
      expect(summary.expenses, 350);
      expect(summary.income, 9000);
    });

    test('a deleted transaction disappears but is kept for sync', () async {
      final added = _ok(await repo.addTransaction(draft(100, now)));
      await repo.deleteTransaction(added.id);

      expect(_ok(await repo.getTransactions()), isEmpty);
      final row = await db.select(db.transactions).getSingle();
      expect(row.deleted, isTrue);
      expect(row.dirty, isTrue);
      expect(
        await repo.updateTransaction(added.id, draft(5, now)),
        isA<Error>(),
      );
    });

    test('tells listeners about changes', () async {
      var notified = 0;
      repo.addListener(() => notified++);
      await repo.addTransaction(draft(100, now));
      await pumpEventQueue();
      expect(notified, greaterThan(0));
    });
  });

  test('categories start with the defaults, in order', () async {
    final repo = CategoryRepositoryDrift(db);
    final all = _ok(await repo.getCategories());
    expect(all.map((c) => c.id), DefaultCategories.all.map((c) => c.id));
    final income = _ok(await repo.getCategories(type: TransactionType.income));
    expect(income.every((c) => c.type == TransactionType.income), isTrue);
    final rows = await db.select(db.categories).get();
    expect(rows.every((r) => !r.dirty), isTrue);
  });

  group('wallets', () {
    late WalletRepositoryDrift repo;

    setUp(() => repo = WalletRepositoryDrift(db, clock: () => now));
    tearDown(() => repo.dispose());

    test('start with Cash and keep the order they were added', () async {
      expect(_ok(await repo.getWallets()).single.name, 'Cash');
      final momo = _ok(
        await repo.saveWallet(
          const Wallet(id: '', name: 'MTN MoMo', kind: WalletKind.mobileMoney),
        ),
      );
      await repo.saveWallet(momo.copyWith(name: 'MoMo'));
      expect(_ok(await repo.getWallets()).map((w) => w.name), ['Cash', 'MoMo']);
    });

    test('transfers need two different wallets', () async {
      final same = Transfer(
        id: '',
        fromWalletId: 'w-cash',
        toWalletId: 'w-cash',
        amount: 10,
        date: now,
      );
      expect(await repo.addTransfer(same), isA<Error>());

      final moved = _ok(
        await repo.addTransfer(
          Transfer(
            id: '',
            fromWalletId: 'w-cash',
            toWalletId: 'w-momo',
            amount: 200,
            date: now,
          ),
        ),
      );
      expect(_ok(await repo.getTransfers()).single.id, moved.id);
      await repo.deleteTransfer(moved.id);
      expect(_ok(await repo.getTransfers()), isEmpty);
    });
  });

  test('budgets keep the order the user chose', () async {
    final repo = BudgetRepositoryDrift(db, clock: () => now);
    addTearDown(repo.dispose);
    for (final name in ['Groceries', 'Transport', 'Airtime']) {
      await repo.saveBudget(
        Budget(
          id: '',
          categoryName: name,
          categoryIcon: 'other',
          categoryColor: 0,
          limit: 100,
        ),
      );
    }
    final ids = _ok(await repo.getBudgets()).map((b) => b.id).toList();
    await repo.reorderBudgets([ids[2], ids[0]]);
    final names = _ok(await repo.getBudgets()).map((b) => b.categoryName);
    expect(names, ['Airtime', 'Groceries', 'Transport']);

    final first = _ok(await repo.getBudgets()).first;
    await repo.saveBudget(first.copyWith(limit: 300));
    expect(_ok(await repo.getBudgets()).first.limit, 300);
  });

  group('accounts', () {
    Future<void> addTransaction() => TransactionRepositoryDrift(db)
        .addTransaction(
          TransactionDraft(
            title: 'Bread',
            amount: 30,
            category: DefaultCategories.groceries,
            date: now,
          ),
        );

    test('settings kept before signing in move to the account', () async {
      final settings = SettingsRepositoryDrift(db, clock: () => now);
      addTearDown(settings.dispose);
      await settings.setPayday(25);
      await settings.setThemePreference(ThemePreference.dark);
      await addTransaction();

      final profile = await db.openAccount(
        userId: 'user-1',
        email: 'mwila@example.com',
        name: 'Mwila',
        createdAt: now,
      );
      expect(profile.payday, 25);
      expect(profile.theme, 'dark');
      expect(profile.name, 'Mwila');
      expect(await db.select(db.transactions).get(), hasLength(1));
      expect(await db.hasUnsyncedChanges(), isTrue);
    });

    test("another account's data is removed", () async {
      await db.openAccount(
        userId: 'user-1',
        email: 'a@example.com',
        name: 'A',
        createdAt: now,
      );
      await addTransaction();

      final profile = await db.openAccount(
        userId: 'user-2',
        email: 'b@example.com',
        name: 'B',
        createdAt: now,
      );
      expect(profile.email, 'b@example.com');
      expect(await db.select(db.transactions).get(), isEmpty);
      expect(await db.select(db.profiles).get(), hasLength(1));
    });

    test('a fresh account has nothing waiting to sync', () async {
      await db.openAccount(
        userId: 'user-1',
        email: 'a@example.com',
        name: 'A',
        createdAt: now,
      );
      await CategoryRepositoryDrift(db).getCategories();
      expect(await db.hasUnsyncedChanges(), isFalse);
    });
  });

  test('category rows round-trip', () async {
    const custom = TransactionCategory(
      id: 'c-x',
      name: 'Pets',
      icon: 'other',
      color: 0xFF123456,
      type: TransactionType.expense,
    );
    final repo = CategoryRepositoryDrift(db);
    await repo.getCategories();
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: custom.id,
            name: custom.name,
            icon: custom.icon,
            color: custom.color,
            type: custom.type.name,
            modifiedAt: now,
          ),
        );
    expect(_ok(await repo.getCategories()), contains(custom));
  });
}
