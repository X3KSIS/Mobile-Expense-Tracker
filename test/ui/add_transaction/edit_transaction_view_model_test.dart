import 'package:flutter_expensetracker/data/repositories/transaction/transaction_repository_local_fake.dart';
import 'package:flutter_expensetracker/domain/models/transaction.dart';
import 'package:flutter_expensetracker/ui/add_transaction/view_models/add_transaction_view_model.dart';
import 'package:flutter_expensetracker/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes/fake_repositories.dart';

void main() {
  final now = DateTime(2026, 11, 25, 15, 30);
  late TransactionRepositoryLocalFake repository;

  setUp(() => repository = instantTransactionRepository(now: now));

  Future<Transaction> existing(String title) async {
    final result = await repository.getTransactions();
    return (result as Ok<List<Transaction>>).value.firstWhere(
      (t) => t.title == title,
    );
  }

  AddTransactionViewModel build(Transaction editing) {
    final viewModel = AddTransactionViewModel(
      transactionRepository: repository,
      categoryRepository: instantCategoryRepository(),
      walletRepository: instantWalletRepository(now: now),
      editing: editing,
      clock: () => now,
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  test('starts from the transaction being edited', () async {
    final shoprite = await existing('Shoprite');
    final viewModel = build(shoprite);
    await viewModel.loadCategories.execute();

    expect(viewModel.isEditing, isTrue);
    expect(viewModel.type, shoprite.type);
    expect(viewModel.selectedCategory!.name, shoprite.categoryName);
    expect(viewModel.selectedWalletId, shoprite.walletId);
    expect(viewModel.date, shoprite.date);
    final prefill = viewModel.takeInitialPrefill()!;
    expect(prefill.title, 'Shoprite');
    expect(prefill.amount, shoprite.amount.toStringAsFixed(0));
    expect(viewModel.takeInitialPrefill(), isNull);
  });

  test('saving replaces the transaction and keeps its id', () async {
    final shoprite = await existing('Shoprite');
    final before = (await repository.getTransactions() as Ok).value.length;
    final viewModel = build(shoprite);
    await viewModel.loadCategories.execute();

    viewModel.selectCategory(
      viewModel.categories.firstWhere((c) => c.name == 'Transport'),
    );
    await viewModel.save.execute((
      amount: '700.50',
      title: 'Shoprite fuel',
      note: 'Fixed',
    ));

    expect(viewModel.save.completed, isTrue);
    final all = (await repository.getTransactions() as Ok).value;
    expect(all, hasLength(before));
    final edited = all.firstWhere((t) => t.id == shoprite.id);
    expect(edited.amount, 700.50);
    expect(edited.title, 'Shoprite fuel');
    expect(edited.categoryName, 'Transport');
    expect(edited.note, 'Fixed');
    expect(edited.date, shoprite.date);
  });

  test('picking the same day keeps its time', () async {
    final shoprite = await existing('Shoprite');
    final viewModel = build(shoprite);
    await viewModel.loadCategories.execute();

    viewModel.selectDate(shoprite.date);
    expect(viewModel.date, shoprite.date);
  });

  test('a category that no longer exists is kept', () async {
    final old = Transaction(
      id: 'old-1',
      title: 'Lotto',
      categoryName: 'Gambling',
      categoryIcon: 'other',
      categoryColor: 0,
      amount: 20,
      type: TransactionType.expense,
      date: DateTime(2026, 11, 3, 12),
    );
    final viewModel = build(old);
    await viewModel.loadCategories.execute();

    expect(viewModel.selectedCategory!.name, 'Gambling');
    expect(viewModel.categories.first.name, 'Gambling');
  });
}
