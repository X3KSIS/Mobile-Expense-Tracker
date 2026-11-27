import 'package:flutter/foundation.dart';

import '../../../domain/models/account_link.dart';
import '../../../domain/models/detected_payment.dart';
import '../../../utils/result.dart';

/// Source of truth for wallets connected to their institution's API.
///
/// Fetched transactions come back as [DetectedPayment]s for the user to
/// review, like payments read from SMS: nothing is saved automatically.
///
/// Notifies when links are added, removed or synced.
abstract class AccountLinkRepository extends ChangeNotifier {
  /// Institutions that can be connected right now. Empty until an API is
  /// available.
  List<String> get availableProviders;

  /// Every connected wallet.
  List<AccountLink> get links;

  /// The link for [walletId], or null.
  AccountLink? linkFor(String walletId);

  /// Connects [walletId] to [accountRef] at [providerName]. Fails if the
  /// institution is not in [availableProviders].
  Future<Result<AccountLink>> link({
    required String walletId,
    required String providerName,
    required String accountRef,
  });

  /// Disconnects [walletId]. Its transactions stay.
  Future<Result<void>> unlink(String walletId);

  /// Fetches [walletId]'s transactions since the last sync (or the last
  /// [firstSyncDays] days the first time) for review.
  Future<Result<List<DetectedPayment>>> sync(String walletId);

  /// How far back the first sync looks.
  static const int firstSyncDays = 30;
}
