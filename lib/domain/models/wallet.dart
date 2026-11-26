/// Where money is kept.
enum WalletKind {
  cash,

  /// MTN MoMo, Airtel Money, Zamtel Kwacha.
  mobileMoney,
  bank,
}

/// A place money is kept: cash, a mobile money account or a bank account.
///
/// The balance is not stored; it is worked out from [openingBalance], the
/// wallet's transactions and its transfers (see `WalletBalances`).
class Wallet {
  const Wallet({
    required this.id,
    required this.name,
    required this.kind,
    this.openingBalance = 0,
  });

  final String id;

  /// e.g. "Cash", "MTN MoMo", "Zanaco".
  final String name;
  final WalletKind kind;

  /// What the wallet held when tracking started. Can be negative for an
  /// overdraft.
  final double openingBalance;

  Wallet copyWith({String? name, WalletKind? kind, double? openingBalance}) =>
      Wallet(
        id: id,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        openingBalance: openingBalance ?? this.openingBalance,
      );

  @override
  bool operator ==(Object other) =>
      other is Wallet &&
      other.id == id &&
      other.name == name &&
      other.kind == kind &&
      other.openingBalance == openingBalance;

  @override
  int get hashCode => Object.hash(id, name, kind, openingBalance);

  @override
  String toString() => 'Wallet($id, $name, ${kind.name})';
}
