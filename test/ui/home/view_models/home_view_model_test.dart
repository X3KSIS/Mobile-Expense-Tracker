import 'package:flutter_expensetracker/data/repositories/settings/settings_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/repositories/transaction/transaction_repository.dart';
import 'package:flutter_expensetracker/ui/home/view_models/home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../testing/fakes/failing_transaction_repository.dart';
import '../../../testing/fakes/fake_repositories.dart';

void main() {
  HomeViewModel buildViewModel({TransactionRepository? transactions}) {
    final viewModel = HomeViewModel(
      transactionRepository: transactions ?? instantTransactionRepository(),
      budgetRepository: instantBudgetRepository(),
      authRepository: instantAuthRepository(signedIn: true),
      settingsRepository: SettingsRepositoryLocalFake(),
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  group('HomeViewModel', () {
    test('starts loading as soon as it is created', () {
      final viewModel = buildViewModel();

      expect(viewModel.isLoading, isTrue);
      expect(viewModel.hasData, isFalse);
      expect(viewModel.hasError, isFalse);
    });

    test('loads the monthly summary', () async {
      final viewModel = buildViewModel();

      await viewModel.load.execute();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.hasData, isTrue);
      expect(viewModel.load.completed, isTrue);
      final summary = viewModel.summary!;
      expect(summary.income, 12500);
      expect(summary.expenses, 7680);
      expect(summary.net, 4820);
    });

    test('loads the top budget alert', () async {
      final viewModel = buildViewModel();

      await viewModel.load.execute();

      final alert = viewModel.budgetAlert!;
      expect(alert.categoryName, 'Groceries');
      expect(alert.percentRounded, 97);
      expect(alert.remaining, 100);
    });

    test('loads the 5 most recent transactions, newest first', () async {
      final viewModel = buildViewModel();

      await viewModel.load.execute();

      final recent = viewModel.recentTransactions;
      expect(recent, hasLength(5));
      expect(recent.map((t) => t.title), [
        'Shoprite',
        'Salary',
        'Fuel',
        'ZESCO units',
        'MTN airtime',
      ]);
      for (var i = 1; i < recent.length; i++) {
        expect(recent[i - 1].date.isAfter(recent[i].date), isTrue);
      }
    });

    test('exposes the error state when a repository fails', () async {
      final viewModel = buildViewModel(
        transactions: FailingTransactionRepository(
          instantTransactionRepository(),
        ),
      );

      await viewModel.load.execute();

      expect(viewModel.hasError, isTrue);
      expect(viewModel.hasData, isFalse);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.recentTransactions, isEmpty);
    });

    test('recovers on retry after a failure', () async {
      final repository = FailingTransactionRepository(
        instantTransactionRepository(),
      );
      final viewModel = buildViewModel(transactions: repository);
      await viewModel.load.execute();
      expect(viewModel.hasError, isTrue);

      repository.shouldFail = false;
      await viewModel.load.execute();

      expect(viewModel.hasError, isFalse);
      expect(viewModel.hasData, isTrue);
      expect(viewModel.summary!.net, 4820);
    });

    test('keeps existing data when a refresh fails', () async {
      final repository = FailingTransactionRepository(
        instantTransactionRepository(),
        shouldFail: false,
      );
      final viewModel = buildViewModel(transactions: repository);
      await viewModel.load.execute();

      repository.shouldFail = true;
      await viewModel.load.execute();

      expect(viewModel.hasError, isTrue);
      expect(viewModel.hasData, isTrue);
      expect(viewModel.recentTransactions, hasLength(5));
    });

    test('toggleHideAmounts flips the flag and notifies', () async {
      final viewModel = buildViewModel();
      await viewModel.load.execute();
      var notified = 0;
      viewModel.addListener(() => notified++);

      viewModel.toggleHideAmounts();
      expect(viewModel.hideAmounts, isTrue);
      viewModel.toggleHideAmounts();
      expect(viewModel.hideAmounts, isFalse);

      expect(notified, 2);
    });

    test('reads the name and initials from the signed-in user', () {
      final viewModel = buildViewModel();

      expect(viewModel.userName, 'Paul Mubanga');
      expect(viewModel.userInitials, 'PM');
    });

    test('updates the name when the profile changes', () async {
      final auth = instantAuthRepository(signedIn: true);
      final viewModel = HomeViewModel(
        transactionRepository: instantTransactionRepository(),
        budgetRepository: instantBudgetRepository(),
        authRepository: auth,
        settingsRepository: SettingsRepositoryLocalFake(),
      );
      addTearDown(viewModel.dispose);
      await viewModel.load.execute();
      var notified = 0;
      viewModel.addListener(() => notified++);

      await auth.updateProfile(name: 'Mwila Banda', phone: '');

      expect(viewModel.userName, 'Mwila Banda');
      expect(viewModel.userInitials, 'MB');
      expect(notified, greaterThan(0));
    });
  });
}
