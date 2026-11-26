import 'package:flutter_expensetracker/domain/models/transaction.dart';
import 'package:flutter_expensetracker/ui/add_transaction/view_models/add_transaction_view_model.dart';
import 'package:flutter_expensetracker/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes/fake_repositories.dart';

void main() {
  final now = DateTime(2026, 11, 25, 15, 30);

  AddTransactionViewModel build({
    TransactionType type = TransactionType.expense,
    String? categoryId,
  }) {
    final viewModel = AddTransactionViewModel(
      transactionRepository: instantTransactionRepository(now: now),
      categoryRepository: instantCategoryRepository(),
      walletRepository: instantWalletRepository(now: now),
      initialType: type,
      initialCategoryId: categoryId,
      clock: () => now,
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  group('AddTransactionViewModel', () {
    test('loads categories and preselects the first expense one', () async {
      final viewModel = build();

      await viewModel.loadCategories.execute();

      expect(viewModel.categories, isNotEmpty);
      expect(
        viewModel.categories.every((c) => c.type == TransactionType.expense),
        isTrue,
      );
      expect(viewModel.selectedCategory!.name, 'Groceries');
      expect(viewModel.date, now);
    });

    test('switching to income swaps the categories', () async {
      final viewModel = build();
      await viewModel.loadCategories.execute();

      viewModel.selectType(TransactionType.income);

      expect(viewModel.isExpense, isFalse);
      expect(viewModel.selectedCategory!.name, 'Salary');
    });

    test('an initial category id presets type and category', () async {
      final viewModel = build(categoryId: 'c-business');

      await viewModel.loadCategories.execute();

      expect(viewModel.type, TransactionType.income);
      expect(viewModel.selectedCategory!.name, 'Business');
    });

    test('validates the amount', () {
      final viewModel = build();

      expect(viewModel.validateAmount(''), 'Enter an amount');
      expect(viewModel.validateAmount('0'), 'Amount must be more than zero');
      expect(viewModel.validateAmount('abc'), 'Enter an amount');
      expect(viewModel.validateAmount('1,250.50'), isNull);
    });

    test('picking an earlier day uses midday; today keeps the time', () {
      final viewModel = build();

      viewModel.selectDate(DateTime(2026, 11, 20));
      expect(viewModel.date, DateTime(2026, 11, 20, 12));

      viewModel.selectDate(DateTime(2026, 11, 25));
      expect(viewModel.date, now);
    });

    test('saves the transaction to the repository', () async {
      final transactions = instantTransactionRepository(now: now);
      final viewModel = AddTransactionViewModel(
        transactionRepository: transactions,
        categoryRepository: instantCategoryRepository(),
        walletRepository: instantWalletRepository(now: now),
        clock: () => now,
      );
      addTearDown(viewModel.dispose);
      await viewModel.loadCategories.execute();

      await viewModel.save.execute((
        amount: '1,250.50',
        title: 'Spar',
        note: '',
      ));

      expect(viewModel.save.completed, isTrue);
      final recent = await transactions.getRecentTransactions(limit: 1);
      final saved = (recent as Ok<List<Transaction>>).value.single;
      expect(saved.title, 'Spar');
      expect(saved.amount, 1250.5);
      expect(saved.categoryName, 'Groceries');
      expect(saved.type, TransactionType.expense);
    });

    test('saves to the chosen wallet, the first one by default', () async {
      final transactions = instantTransactionRepository(now: now);
      final viewModel = AddTransactionViewModel(
        transactionRepository: transactions,
        categoryRepository: instantCategoryRepository(),
        walletRepository: instantWalletRepository(now: now),
        clock: () => now,
      );
      addTearDown(viewModel.dispose);
      await viewModel.loadCategories.execute();

      expect(viewModel.selectedWalletId, 'w-cash');
      viewModel.selectWallet(
        viewModel.wallets.firstWhere((w) => w.name == 'MTN MoMo'),
      );
      await viewModel.save.execute((amount: '20', title: 'Bundle', note: ''));

      final recent = await transactions.getRecentTransactions(limit: 1);
      final saved = (recent as Ok<List<Transaction>>).value.single;
      expect(saved.walletId, 'w-momo');
    });

    test('fills the form from a MoMo message and saves the charge', () async {
      final transactions = instantTransactionRepository(now: now);
      final viewModel = AddTransactionViewModel(
        transactionRepository: transactions,
        categoryRepository: instantCategoryRepository(),
        walletRepository: instantWalletRepository(now: now),
        clock: () => now,
      );
      addTearDown(viewModel.dispose);
      await viewModel.loadCategories.execute();

      final message = viewModel.readMessage(
        'MoMo: You have paid ZMW 150.00 to SHOPRITE MANDA HILL on '
        '24/11/2026 10:15. Fee ZMW 2.50. New balance ZMW 920.00. '
        'Txn ID: 987654.',
      )!;
      final prefill = viewModel.applyMessage(message);

      expect(prefill.amount, '150');
      expect(prefill.title, 'Shoprite Manda Hill');
      expect(prefill.note, contains('Ref 987654'));
      expect(viewModel.isExpense, isTrue);
      expect(viewModel.selectedCategory?.name, 'Groceries');
      expect(viewModel.selectedWalletId, 'w-momo');
      expect(viewModel.date, DateTime(2026, 11, 24, 10, 15));
      expect(viewModel.pendingFee, 2.5);

      await viewModel.save.execute((
        amount: prefill.amount,
        title: prefill.title,
        note: prefill.note,
      ));
      final recent = await transactions.getRecentTransactions(limit: 60);
      final all = (recent as Ok<List<Transaction>>).value;
      final charge = all.firstWhere((t) => t.categoryName == 'Fees & charges');
      expect(charge.amount, 2.5);
      expect(charge.walletId, 'w-momo');
      expect(charge.title, 'Charge: Shoprite Manda Hill');
    });

    test('a received message switches to income', () async {
      final viewModel = build();
      await viewModel.loadCategories.execute();

      viewModel.applyMessage(
        viewModel.readMessage(
          'Airtel Money: Money received. Amt: K500.00 From: 0971234567 '
          'MARY PHIRI. Bal: K1,250.00.',
        )!,
      );

      expect(viewModel.isExpense, isFalse);
      expect(viewModel.selectedCategory?.name, 'Other income');
      expect(viewModel.pendingFee, isNull);
    });

    test('refuses to save an invalid amount', () async {
      final viewModel = build();
      await viewModel.loadCategories.execute();

      await viewModel.save.execute((amount: '', title: '', note: ''));

      expect(viewModel.save.error, isTrue);
    });
  });
}
