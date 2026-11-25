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

  /// Routes a signed-out user may visit.
  static const Set<String> signedOut = {login, signUp};
}
