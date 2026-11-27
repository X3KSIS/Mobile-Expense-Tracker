/// Route paths used with go_router.
abstract final class Routes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String signUp = '/signup';
  static const String home = '/home';
  static const String activity = '/activity';
  static const String budgets = '/budgets';
  static const String reports = '/reports';
  static const String add = '/add';
  static const String search = '/search';
  static const String history = '/history';
  static const String recurring = '/recurring';
  static const String categoryTrend = '/category';
  static const String wallets = '/wallets';
  static const String detectedPayments = '/detected';
  static const String profile = '/profile';
  static const String editProfileSegment = 'edit';
  static const String editProfile = '$profile/$editProfileSegment';

  /// Query parameters for [add].
  static const String typeParam = 'type';
  static const String categoryParam = 'category';

  /// [add] with an optional preset type (`expense` or `income`) and
  /// category id.
  static String addWith({String? type, String? categoryId}) => Uri(
    path: add,
    queryParameters: {typeParam: ?type, categoryParam: ?categoryId},
  ).toString();

  /// Query parameters for [categoryTrend].
  static const String nameParam = 'name';
  static const String monthParam = 'month';

  /// [categoryTrend] for the category called [name], opened on [month]
  /// (sent as `yyyy-mm`).
  static String categoryTrendFor(String name, {DateTime? month}) => Uri(
    path: categoryTrend,
    queryParameters: {
      nameParam: name,
      monthParam: ?(month == null
          ? null
          : '${month.year}-${month.month.toString().padLeft(2, '0')}'),
    },
  ).toString();

  /// Reads a `yyyy-mm` [monthParam] value, or null.
  static DateTime? parseMonth(String? value) {
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(value ?? '');
    if (match == null) return null;
    final month = int.parse(match.group(2)!);
    if (month < 1 || month > 12) return null;
    return DateTime(int.parse(match.group(1)!), month);
  }

  /// Routes a signed-out user may visit.
  static const Set<String> signedOut = {login, signUp};
}
