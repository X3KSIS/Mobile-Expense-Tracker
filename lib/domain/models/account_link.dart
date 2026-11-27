/// A wallet connected to its institution's API, so its transactions can be
/// fetched instead of typed in or read from SMS.
class AccountLink {
  const AccountLink({
    required this.walletId,
    required this.providerName,
    required this.accountRef,
    this.lastSyncedAt,
  });

  final String walletId;

  /// e.g. "MTN MoMo"; matches a `ProviderApiService.providerName`.
  final String providerName;

  /// The phone number or account number at the institution.
  final String accountRef;

  /// When transactions were last fetched, or null if never.
  final DateTime? lastSyncedAt;

  AccountLink copyWith({DateTime? lastSyncedAt}) => AccountLink(
    walletId: walletId,
    providerName: providerName,
    accountRef: accountRef,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is AccountLink &&
      other.walletId == walletId &&
      other.providerName == providerName &&
      other.accountRef == accountRef &&
      other.lastSyncedAt == lastSyncedAt;

  @override
  int get hashCode =>
      Object.hash(walletId, providerName, accountRef, lastSyncedAt);

  @override
  String toString() => 'AccountLink($walletId → $providerName $accountRef)';
}
