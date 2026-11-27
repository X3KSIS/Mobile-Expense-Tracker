import 'package:flutter_expensetracker/data/repositories/account_link/account_link_repository.dart';
import 'package:flutter_expensetracker/data/repositories/account_link/account_link_repository_api.dart';
import 'package:flutter_expensetracker/data/services/provider_api/provider_api_service.dart';
import 'package:flutter_expensetracker/domain/models/money_message.dart';
import 'package:flutter_expensetracker/domain/models/wallet.dart';
import 'package:flutter_expensetracker/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for an institution's API.
class _FakeMomoApi implements ProviderApiService {
  final List<DateTime> calls = [];
  bool fail = false;

  @override
  String get providerName => 'MTN MoMo';

  @override
  WalletKind get kind => WalletKind.mobileMoney;

  @override
  Future<Result<List<MoneyMessage>>> fetchTransactions({
    required String accountRef,
    required DateTime since,
  }) async {
    calls.add(since);
    if (fail) return Result.error(Exception('API down'));
    return Result.ok([
      MoneyMessage(
        kind: MoneyMessageKind.spent,
        amount: 120,
        provider: providerName,
        counterparty: 'Shoprite',
        reference: 'TX123',
        date: DateTime(2026, 11, 20),
      ),
    ]);
  }
}

void main() {
  final now = DateTime(2026, 11, 27, 9);

  test('with no APIs nothing can be connected', () async {
    final repo = AccountLinkRepositoryApi();
    addTearDown(repo.dispose);

    expect(repo.availableProviders, isEmpty);
    final result = await repo.link(
      walletId: 'w-momo',
      providerName: 'MTN MoMo',
      accountRef: '0961234567',
    );
    expect(result, isA<Error>());
    expect(repo.links, isEmpty);
  });

  test('syncs a linked wallet into payments to review', () async {
    final api = _FakeMomoApi();
    final repo = AccountLinkRepositoryApi(services: [api], clock: () => now);
    addTearDown(repo.dispose);

    expect(repo.availableProviders, ['MTN MoMo']);
    await repo.link(
      walletId: 'w-momo',
      providerName: 'MTN MoMo',
      accountRef: ' 0961234567 ',
    );
    expect(repo.linkFor('w-momo')!.accountRef, '0961234567');

    final result = await repo.sync('w-momo');
    final payments = (result as Ok).value;
    expect(payments.single.id, 'TX123');
    expect(payments.single.message.counterparty, 'Shoprite');
    expect(
      api.calls.single,
      now.subtract(const Duration(days: AccountLinkRepository.firstSyncDays)),
    );
    expect(repo.linkFor('w-momo')!.lastSyncedAt, now);

    await repo.sync('w-momo');
    expect(api.calls.last, now);
  });

  test('a failed sync keeps the last sync time', () async {
    final api = _FakeMomoApi()..fail = true;
    final repo = AccountLinkRepositoryApi(services: [api], clock: () => now);
    addTearDown(repo.dispose);
    await repo.link(
      walletId: 'w-momo',
      providerName: 'MTN MoMo',
      accountRef: '0961234567',
    );

    expect(await repo.sync('w-momo'), isA<Error>());
    expect(repo.linkFor('w-momo')!.lastSyncedAt, isNull);

    await repo.unlink('w-momo');
    expect(await repo.sync('w-momo'), isA<Error>());
  });
}
