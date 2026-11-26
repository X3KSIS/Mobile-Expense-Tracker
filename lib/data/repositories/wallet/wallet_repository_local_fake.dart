import '../../../domain/models/transfer.dart';
import '../../../domain/models/wallet.dart';
import '../../../utils/result.dart';
import 'wallet_repository.dart';

/// In-memory [WalletRepository]: cash, MTN MoMo and a Zanaco account, with
/// a monthly top-up from the bank to MoMo and a cash withdrawal, matching
/// the fake transactions so every balance stays positive.
class WalletRepositoryLocalFake extends WalletRepository {
  WalletRepositoryLocalFake({
    DateTime? now,
    this.delay = const Duration(milliseconds: 400),
  }) : _now = now ?? DateTime.now();

  static const String cashId = 'w-cash';
  static const String momoId = 'w-momo';
  static const String bankId = 'w-bank';

  final DateTime _now;

  /// Simulated network latency.
  final Duration delay;

  final List<Wallet> _wallets = [
    const Wallet(
      id: cashId,
      name: 'Cash',
      kind: WalletKind.cash,
      openingBalance: 250,
    ),
    const Wallet(
      id: momoId,
      name: 'MTN MoMo',
      kind: WalletKind.mobileMoney,
      openingBalance: 180,
    ),
    const Wallet(
      id: bankId,
      name: 'Zanaco',
      kind: WalletKind.bank,
      openingBalance: 4200,
    ),
  ];

  late final List<Transfer> _transfers = _fakeTransfers(_now);
  int _nextId = 1;

  @override
  Future<Result<List<Wallet>>> getWallets() async {
    await Future<void>.delayed(delay);
    return Result.ok(List.unmodifiable(_wallets));
  }

  @override
  Future<Result<Wallet>> saveWallet(Wallet wallet) async {
    await Future<void>.delayed(delay);
    final saved = wallet.id.isEmpty
        ? Wallet(
            id: 'w-new-${_nextId++}',
            name: wallet.name,
            kind: wallet.kind,
            openingBalance: wallet.openingBalance,
          )
        : wallet;
    final index = _wallets.indexWhere((w) => w.id == saved.id);
    if (index == -1) {
      _wallets.add(saved);
    } else {
      _wallets[index] = saved;
    }
    notifyListeners();
    return Result.ok(saved);
  }

  @override
  Future<Result<List<Transfer>>> getTransfers() async {
    await Future<void>.delayed(delay);
    final sorted = [..._transfers]..sort((a, b) => b.date.compareTo(a.date));
    return Result.ok(List.unmodifiable(sorted));
  }

  @override
  Future<Result<Transfer>> addTransfer(Transfer transfer) async {
    await Future<void>.delayed(delay);
    if (transfer.fromWalletId == transfer.toWalletId) {
      return Result.error(Exception('Pick two different wallets'));
    }
    final saved = transfer.id.isEmpty
        ? Transfer(
            id: 'x-new-${_nextId++}',
            fromWalletId: transfer.fromWalletId,
            toWalletId: transfer.toWalletId,
            amount: transfer.amount,
            date: transfer.date,
            note: transfer.note,
          )
        : transfer;
    _transfers.add(saved);
    notifyListeners();
    return Result.ok(saved);
  }

  @override
  Future<Result<void>> deleteTransfer(String id) async {
    await Future<void>.delayed(delay);
    _transfers.removeWhere((t) => t.id == id);
    notifyListeners();
    return const Result.ok(null);
  }
}

/// This month and the five before: ZMW 500 from the bank to MoMo on the
/// 3rd and a ZMW 500 cash withdrawal on the 5th. This month's are moved
/// back to today if those days haven't come yet.
List<Transfer> _fakeTransfers(DateTime now) {
  final result = <Transfer>[];
  for (var back = 0; back <= 5; back++) {
    final m = DateTime(now.year, now.month - back);
    DateTime day(int d) {
      final date = DateTime(m.year, m.month, d, 9);
      return date.isAfter(now)
          ? now.subtract(const Duration(minutes: 30))
          : date;
    }

    result.addAll([
      Transfer(
        id: 'x$back-momo',
        fromWalletId: WalletRepositoryLocalFake.bankId,
        toWalletId: WalletRepositoryLocalFake.momoId,
        amount: 500,
        date: day(3),
        note: 'Top up',
      ),
      Transfer(
        id: 'x$back-cash',
        fromWalletId: WalletRepositoryLocalFake.bankId,
        toWalletId: WalletRepositoryLocalFake.cashId,
        amount: 500,
        date: day(5),
        note: 'ATM withdrawal',
      ),
    ]);
  }
  return result;
}
