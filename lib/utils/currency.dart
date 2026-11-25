import 'package:intl/intl.dart';

/// Currency code shown in front of every amount.
const String currencyCode = 'ZMW';

final NumberFormat _withDecimals = NumberFormat('#,##0.00', 'en_US');
final NumberFormat _wholeOnly = NumberFormat('#,##0', 'en_US');

/// Formats [amount] as `ZMW 1,234.00`. Negative amounts are shown as
/// `-ZMW 1,234.00`.
String formatZmw(double amount) {
  final sign = amount < 0 ? '-' : '';
  return '$sign$currencyCode ${_withDecimals.format(amount.abs())}';
}

/// Formats [amount] as `+ZMW 1,234.00` or `-ZMW 1,234.00`.
String formatZmwSigned(double amount, {required bool isIncome}) {
  final sign = isIncome ? '+' : '-';
  return '$sign$currencyCode ${_withDecimals.format(amount.abs())}';
}

/// Formats [amount] without decimals or currency code, e.g. `12,500`.
String formatWhole(double amount) => _wholeOnly.format(amount.abs().round());

/// The pieces of a big amount, so the UI can style them separately:
/// `ZMW` + `4,820` + `.00`.
class MoneyParts {
  const MoneyParts({required this.whole, required this.decimals});

  /// Whole part with thousands separators and sign, e.g. `4,820`.
  final String whole;

  /// Decimal part including the point, e.g. `.00`.
  final String decimals;
}

/// Splits [amount] into [MoneyParts].
MoneyParts splitMoney(double amount) {
  final formatted = _withDecimals.format(amount.abs());
  final point = formatted.lastIndexOf('.');
  final sign = amount < 0 ? '-' : '';
  return MoneyParts(
    whole: '$sign${formatted.substring(0, point)}',
    decimals: formatted.substring(point),
  );
}

/// Parses what the user typed in an amount field, e.g. `1,250.50`.
/// Returns null when it is empty or not a number.
double? parseAmount(String text) {
  final cleaned = text.trim().replaceAll(',', '').replaceAll(' ', '');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

/// Short amount for chart axes: `0`, `950`, `5K`, `12.5K`, `1.2M`.
String formatCompact(double amount) {
  final value = amount.abs();
  if (value >= 1000000) return '${_trim(value / 1000000)}M';
  if (value >= 1000) return '${_trim(value / 1000)}K';
  return value.round().toString();
}

String _trim(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
