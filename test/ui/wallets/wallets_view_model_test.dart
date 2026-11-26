import 'package:flutter_expensetracker/domain/models/wallet.dart';
import 'package:flutter_expensetracker/ui/wallets/view_models/wallets_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes/fake_repositories.dart';

void main() {
  final now = DateTime(2026, 11, 25, 15);

  WalletsViewModel build() {
    final viewModel = WalletsViewModel(
      walletRepository: instantWalletRepository(now: now),
      transactionRepository: instantTransactionRepository(now: now),
      categoryRepository: instantCategoryRepository(),
      clock: () => now,
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  double balanceOf(WalletsViewModel vm, String name) =>
      vm.balances.firstWhere((b) => b.wallet.name == name).balance;

  group('WalletsViewModel', () {
    test('loads wallets, balances, the total and transfers', () async {
      final vm = build();
      await vm.load.execute();

      expect(vm.wallets.map((w) => w.name), ['Cash', 'MTN MoMo', 'Zanaco']);
      expect(
        vm.total,
        vm.balances.fold<double>(0, (sum, b) => sum + b.balance),
      );
      expect(vm.recentTransfers, hasLength(vm.recentTransferLimit));
      expect(vm.recentTransfers.first.from, 'Zanaco');
      expect(vm.canTransfer, isTrue);
    });

    test('moving money shifts balances and records the charge', () async {
      final vm = build();
      await vm.load.execute();
      final momo = balanceOf(vm, 'MTN MoMo');
      final cash = balanceOf(vm, 'Cash');
      final total = vm.total;

      await vm.transfer.execute((
        fromWalletId: 'w-momo',
        toWalletId: 'w-cash',
        amount: '300',
        fee: '8.50',
        note: 'Agent',
      ));
      await vm.load.execute();

      expect(vm.transfer.completed, isTrue);
      expect(balanceOf(vm, 'MTN MoMo'), momo - 308.5);
      expect(balanceOf(vm, 'Cash'), cash + 300);
      // Only the charge leaves the user's money.
      expect(vm.total, total - 8.5);
      expect(vm.recentTransfers.first.to, 'Cash');
    });

    test('refuses a transfer to the same wallet', () async {
      final vm = build();
      await vm.load.execute();

      await vm.transfer.execute((
        fromWalletId: 'w-cash',
        toWalletId: 'w-cash',
        amount: '10',
        fee: '',
        note: '',
      ));
      expect(vm.transfer.error, isTrue);
    });

    test('adds a wallet with its opening balance', () async {
      final vm = build();
      await vm.load.execute();

      await vm.saveWallet.execute((
        wallet: null,
        name: ' Airtel Money ',
        kind: WalletKind.mobileMoney,
        openingBalance: '1,200',
      ));
      await vm.load.execute();

      expect(balanceOf(vm, 'Airtel Money'), 1200);
    });

    test('validates the forms', () {
      final vm = build();
      expect(vm.validateName('  '), isNotNull);
      expect(vm.validateOpeningBalance(''), isNull);
      expect(vm.validateOpeningBalance('abc'), isNotNull);
      expect(vm.validateTransferAmount('0'), isNotNull);
      expect(vm.validateFee(''), isNull);
      expect(vm.validateFee('5'), isNull);
    });
  });
}
