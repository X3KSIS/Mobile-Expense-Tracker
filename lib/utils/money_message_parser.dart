import '../domain/models/money_message.dart';
import '../domain/models/wallet.dart';

/// Reads MTN MoMo, Airtel Money, Zamtel Kwacha and bank SMS confirmations.
///
/// Message wording differs between providers and changes over time, so
/// this looks for the parts every confirmation has (an amount in ZMW or
/// K, a word saying which way the money went) rather than matching exact
/// templates. Returns null when the text doesn't look like one.
abstract final class MoneyMessageParser {
  static MoneyMessage? parse(String text) {
    final message = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (message.isEmpty) return null;

    final kind = _kind(message);
    if (kind == null) return null;

    final amounts = _amounts(message);
    final main = amounts.where((a) => a.label == _Label.main).firstOrNull;
    if (main == null || main.value <= 0) return null;

    final fee = amounts.where((a) => a.label == _Label.fee).firstOrNull?.value;
    final provider = _provider(message);
    return MoneyMessage(
      kind: kind,
      amount: main.value,
      provider: provider?.$1,
      providerKind: provider?.$2,
      counterparty: _counterparty(message, kind),
      fee: (fee != null && fee > 0) ? fee : null,
      balance: amounts
          .where((a) => a.label == _Label.balance)
          .firstOrNull
          ?.value,
      reference: _reference(message),
      date: _date(message),
      categoryHint: _category(message, kind),
    );
  }

  // Which way the money went. Withdrawals are checked first ("cash out"
  // would otherwise read as money out); otherwise the earliest keyword
  // wins, so "received ... from" isn't confused by a later "to".
  static final RegExp _withdrawal = RegExp(
    r'\b(cash ?out|withdraw(n|al)?|atm)\b',
    caseSensitive: false,
  );
  static final RegExp _income = RegExp(
    r'\b(received|credited|deposit(ed)?|cash ?in|money in|refund(ed)?|reversal|reversed)\b',
    caseSensitive: false,
  );
  static final RegExp _spent = RegExp(
    r'\b(paid|sent|payment|debited|purchased?|bought|deducted|transferred to)\b',
    caseSensitive: false,
  );

  static MoneyMessageKind? _kind(String m) {
    if (_withdrawal.hasMatch(m)) return MoneyMessageKind.withdrawal;
    final income = _income.firstMatch(m)?.start;
    final spent = _spent.firstMatch(m)?.start;
    if (income == null && spent == null) return null;
    if (spent == null) return MoneyMessageKind.received;
    if (income == null) return MoneyMessageKind.spent;
    return income < spent ? MoneyMessageKind.received : MoneyMessageKind.spent;
  }

  // Amounts: "ZMW 1,250.00", "ZMW1250", "K500.00", "K 8.50". The few
  // words before each say whether it is a balance or a charge.
  static final RegExp _amount = RegExp(
    r'(?:\bZMW|\bZK|\bK)\s?(\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)',
  );
  static final RegExp _balanceWord = RegExp(
    r'bal(ance)?\b|bal\.|avail',
    caseSensitive: false,
  );
  static final RegExp _feeWord = RegExp(
    r'\b(fee|charge[sd]?|cost|levy|tax)\b',
    caseSensitive: false,
  );

  static List<({double value, _Label label})> _amounts(String m) {
    final result = <({double value, _Label label})>[];
    for (final match in _amount.allMatches(m)) {
      final value = double.tryParse(match.group(1)!.replaceAll(',', ''));
      if (value == null) continue;
      final before = m.substring(
        (match.start - 24).clamp(0, match.start),
        match.start,
      );
      // Only the nearest clause counts: "ZMW 150 to X. Fee ZMW 0" must
      // not label the first amount as a fee.
      final clause = before.split(RegExp(r'[.;]\s')).last;
      final label = _balanceWord.hasMatch(clause)
          ? _Label.balance
          : _feeWord.hasMatch(clause)
          ? _Label.fee
          : _Label.main;
      result.add((value: value, label: label));
    }
    return result;
  }

  // Mobile money names have no trailing word boundary: SMS senders run
  // them together, e.g. "AirtelMoney", "MoMoPay".
  static const List<(String, String, WalletKind)> _providers = [
    (r'\bMTN|\bMoMo', 'MTN MoMo', WalletKind.mobileMoney),
    (r'\bAirtel', 'Airtel Money', WalletKind.mobileMoney),
    (r'\bZamtel|\bZamkwacha', 'Zamtel Kwacha', WalletKind.mobileMoney),
    (r'\bZanaco\b', 'Zanaco', WalletKind.bank),
    (r'\bFNB\b', 'FNB', WalletKind.bank),
    (r'\bStanbic\b', 'Stanbic', WalletKind.bank),
    (r'\bAbsa\b', 'Absa', WalletKind.bank),
    (r'\bAtlas Mara\b', 'Atlas Mara', WalletKind.bank),
    (r'\bIndo Zambia\b', 'Indo Zambia Bank', WalletKind.bank),
    (r'\bZICB\b', 'ZICB', WalletKind.bank),
    (r'\bAccess Bank\b', 'Access Bank', WalletKind.bank),
    (r'\bEcobank\b', 'Ecobank', WalletKind.bank),
    (r'\bacc(oun)?t\b', 'Bank', WalletKind.bank),
  ];

  static (String, WalletKind)? _provider(String m) {
    for (final (pattern, name, kind) in _providers) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(m)) {
        return (name, kind);
      }
    }
    return null;
  }

  // "from JOHN BANDA 0961234567", "to SHOPRITE MANDA HILL on 26/11",
  // "From: 0971234567 JOHN BANDA." Stops at a number, a date, a full stop
  // or words like "on", "ref", "fee".
  static String? _counterparty(String m, MoneyMessageKind kind) {
    final words = kind == MoneyMessageKind.received ? 'from' : r'to|at';
    final match = RegExp(
      '\\b(?:$words)\\s*:?\\s*(?:\\+?\\d{9,13}\\s+)?'
      r"([A-Za-z][A-Za-z&'\-]*(?: [A-Za-z&'\-]+){0,4}?)"
      r'(?=\s+(?:\+?\d{6,}|on|ref|txn|tid|fee|bal|new|your|acc|via|for|is|has|was)\b|\s*[.,;:]|\s+\d|$)',
      caseSensitive: false,
    ).firstMatch(m);
    final name = match?.group(1)?.trim();
    if (name == null || name.length < 2) return null;
    const ignore = {'your', 'you', 'agent', 'account', 'acc', 'the', 'a'};
    if (ignore.contains(name.toLowerCase())) return null;
    return _titleCase(name);
  }

  static final RegExp _referencePattern = RegExp(
    r'\b(?:txn\.?\s*id|transaction\s*id|trans\.?\s*id|tid|ref(?:erence)?(?:\s*no)?)\s*[:.#]?\s*([A-Z0-9][A-Z0-9.\-]{3,})',
    caseSensitive: false,
  );

  static String? _reference(String m) =>
      _referencePattern.firstMatch(m)?.group(1)?.replaceAll(RegExp(r'\.$'), '');

  static final RegExp _datePattern = RegExp(
    r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})(?:\s*(?:at\s*)?(\d{1,2}):(\d{2}))?',
  );

  /// Day first, as Zambian messages write it.
  static DateTime? _date(String m) {
    final match = _datePattern.firstMatch(m);
    if (match == null) return null;
    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    var year = int.parse(match.group(3)!);
    if (year < 100) year += 2000;
    final hour = int.tryParse(match.group(4) ?? '') ?? 12;
    final minute = int.tryParse(match.group(5) ?? '') ?? 0;
    if (month < 1 || month > 12 || day < 1 || day > 31 || hour > 23) {
      return null;
    }
    final date = DateTime(year, month, day, hour, minute);
    return date.day == day ? date : null;
  }

  // Category names match the app's categories.
  static const List<(String, String)> _expenseHints = [
    (r'zesco|electricity|\bunits\b|prepaid power', 'Utilities'),
    (r'lusaka water|water bill', 'Utilities'),
    (r'airtime|bundle|talk ?time|\bdata\b', 'Airtime'),
    (
      r'shoprite|pick ?n ?pay|\bspar\b|choppies|melisa|grocer|supermarket|\bgame stores\b',
      'Groceries',
    ),
    (r'fuel|puma|\btotal\b|engen|mount meru|filling station', 'Transport'),
    (r'\bbus\b|taxi|yango|\bubuntu\b|transport', 'Transport'),
    (r'\brent\b|landlord', 'Housing'),
    (r'school|tuition|unza|\bcbu\b|college', 'Education'),
    (r'clinic|hospital|pharmacy|chemist', 'Health'),
    (
      r'hungry lion|\bkfc\b|debonairs|pizza inn|chicken inn|restaurant|cafe',
      'Eating out',
    ),
    (r'dstv|gotv|netflix|showmax|cinema', 'Entertainment'),
  ];

  static String? _category(String m, MoneyMessageKind kind) {
    if (kind == MoneyMessageKind.withdrawal) return 'Fees & charges';
    if (kind == MoneyMessageKind.received) {
      return RegExp(r'salary|payroll|\bsal\b', caseSensitive: false).hasMatch(m)
          ? 'Salary'
          : 'Other income';
    }
    for (final (pattern, category) in _expenseHints) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(m)) return category;
    }
    return null;
  }

  static String _titleCase(String s) => s
      .split(' ')
      .map(
        (w) => w.isEmpty
            ? w
            : w.length <= 3 &&
                  w == w.toUpperCase() &&
                  !w.contains(RegExp('[AEIOU]'))
            ? w
            : w[0].toUpperCase() + w.substring(1).toLowerCase(),
      )
      .join(' ');
}

enum _Label { main, fee, balance }
