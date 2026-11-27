import '../../../domain/models/money_message.dart';
import '../../../domain/models/wallet.dart';
import '../../../utils/result.dart';

/// Reads transactions straight from a mobile money provider's or bank's
/// API, one implementation per institution (MTN MoMo, Airtel Money,
/// Zamtel Kwacha, Zanaco, Stanbic …).
///
/// None exist yet: each needs API access granted by the institution. To
/// add one:
///
/// 1. Implement this class in this folder (e.g. `mtn_momo_api_service.dart`),
///    wrapping the HTTP client. Keep it stateless; credentials and tokens
///    come in through the constructor.
/// 2. Map each API record to a [MoneyMessage], the same shape the SMS
///    parser produces, so everything downstream (review, Add transaction,
///    category guess, charges) works unchanged. Always set
///    [MoneyMessage.reference] to the institution's transaction ID: it is
///    how a payment seen both in an SMS and through the API is offered
///    only once.
/// 3. Pass an instance to `AccountLinkRepositoryApi` in
///    `lib/config/dependencies.dart`.
abstract class ProviderApiService {
  /// Matches [MoneyMessage.provider] and the name shown to the user,
  /// e.g. "MTN MoMo".
  String get providerName;

  /// Mobile money or bank.
  WalletKind get kind;

  /// Transactions on the account [accountRef] (a phone number or account
  /// number) since [since], oldest first.
  Future<Result<List<MoneyMessage>>> fetchTransactions({
    required String accountRef,
    required DateTime since,
  });
}
