import 'transaction.dart';

/// Turns transactions into CSV for spreadsheets: one row each, newest
/// first, with a signed amount (expenses negative) so a column sum gives
/// the net.
abstract final class TransactionCsv {
  static const List<String> header = [
    'Date',
    'Type',
    'Title',
    'Category',
    'Wallet',
    'Amount (ZMW)',
    'Note',
  ];

  /// [walletNames] maps wallet ids to names; unknown ids are left as is.
  static String build(
    List<Transaction> transactions, {
    Map<String, String> walletNames = const {},
  }) {
    final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
    final lines = [
      header.map(_cell).join(','),
      for (final t in sorted)
        [
          _date(t.date),
          t.isIncome ? 'Income' : 'Expense',
          t.title,
          t.categoryName,
          walletNames[t.walletId] ?? t.walletId,
          t.signedAmount.toStringAsFixed(2),
          t.note ?? '',
        ].map(_cell).join(','),
    ];
    // CRLF line ends, as spreadsheets expect.
    return '${lines.join('\r\n')}\r\n';
  }

  /// `2026-11-28 14:05`
  static String _date(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}';
  }

  /// Quotes a cell when it holds a comma, quote or line break. Cells that
  /// a spreadsheet would run as a formula get a leading apostrophe.
  static String _cell(String value) {
    var v = value;
    if (v.isNotEmpty && '=+-@'.contains(v[0]) && double.tryParse(v) == null) {
      v = "'$v";
    }
    if (v.contains(RegExp('[",\r\n]'))) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }
}
