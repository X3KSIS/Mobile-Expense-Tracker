import '../../../domain/models/account_link.dart';
import '../../../domain/models/detected_payment.dart';
import '../../../utils/result.dart';
import '../../services/provider_api/provider_api_service.dart';
import 'account_link_repository.dart';

/// [AccountLinkRepository] backed by institution APIs.
///
/// [services] is empty until an institution grants API access, so nothing
/// can be linked yet. Links are kept in memory until Drift lands.
class AccountLinkRepositoryApi extends AccountLinkRepository {
  AccountLinkRepositoryApi({
    List<ProviderApiService> services = const [],
    DateTime Function()? clock,
  }) : _services = {for (final s in services) s.providerName: s},
       _clock = clock ?? DateTime.now;

  final Map<String, ProviderApiService> _services;
  final DateTime Function() _clock;
  final Map<String, AccountLink> _links = {};

  @override
  List<String> get availableProviders => _services.keys.toList()..sort();

  @override
  List<AccountLink> get links => _links.values.toList(growable: false);

  @override
  AccountLink? linkFor(String walletId) => _links[walletId];

  @override
  Future<Result<AccountLink>> link({
    required String walletId,
    required String providerName,
    required String accountRef,
  }) async {
    if (!_services.containsKey(providerName)) {
      return Result.error(Exception("$providerName can't be connected yet"));
    }
    final ref = accountRef.trim();
    if (ref.isEmpty) {
      return Result.error(Exception('Enter the account or phone number'));
    }
    final link = AccountLink(
      walletId: walletId,
      providerName: providerName,
      accountRef: ref,
    );
    _links[walletId] = link;
    notifyListeners();
    return Result.ok(link);
  }

  @override
  Future<Result<void>> unlink(String walletId) async {
    if (_links.remove(walletId) != null) notifyListeners();
    return const Result.ok(null);
  }

  @override
  Future<Result<List<DetectedPayment>>> sync(String walletId) async {
    final link = _links[walletId];
    if (link == null) {
      return Result.error(Exception('This wallet is not connected'));
    }
    final service = _services[link.providerName];
    if (service == null) {
      return Result.error(
        Exception("${link.providerName} can't be connected yet"),
      );
    }
    final now = _clock();
    final since =
        link.lastSyncedAt ??
        now.subtract(const Duration(days: AccountLinkRepository.firstSyncDays));
    final result = await service.fetchTransactions(
      accountRef: link.accountRef,
      since: since,
    );
    switch (result) {
      case Ok(:final value):
        _links[walletId] = link.copyWith(lastSyncedAt: now);
        notifyListeners();
        return Result.ok([
          for (final (i, message) in value.indexed)
            DetectedPayment(
              // The reference matches the one in the SMS for the same
              // payment, so it is only offered once.
              id:
                  message.reference ??
                  '${link.providerName}:${now.millisecondsSinceEpoch}:$i',
              message: message,
              receivedAt: message.date ?? now,
              sender: link.providerName,
            ),
        ]);
      case Error(:final error):
        return Result.error(error);
    }
  }
}
