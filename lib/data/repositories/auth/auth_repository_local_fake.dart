import '../../../domain/models/app_user.dart';
import '../../../domain/models/auth_exception.dart';
import '../../../utils/result.dart';
import 'auth_repository.dart';

/// In-memory [AuthRepository] with one demo account.
///
/// Sign in with [demoEmail] / [demoPassword]. New sign-ups are kept until
/// the app restarts. Nothing is persisted, so the app always starts signed
/// out unless [signedIn] is true.
class AuthRepositoryLocalFake extends AuthRepository {
  AuthRepositoryLocalFake({
    this.delay = const Duration(milliseconds: 600),
    bool signedIn = false,
    DateTime? now,
  }) : _now = now ?? DateTime.now() {
    final demo = AppUser(
      id: 'user-1',
      name: 'Paul Mubanga',
      email: demoEmail,
      phone: '0971234567',
      createdAt: DateTime(_now.year, _now.month - 3, 12),
    );
    _accounts[demoEmail] = _Account(demo, demoPassword);
    if (signedIn) _currentUser = demo;
  }

  static const String demoEmail = 'demo@expensetrack.app';
  static const String demoPassword = 'password123';

  /// Simulated network latency.
  final Duration delay;

  final DateTime _now;
  final Map<String, _Account> _accounts = {};
  AppUser? _currentUser;
  int _nextId = 2;

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(delay);
    final account = _accounts[_normalise(email)];
    if (account == null || account.password != password) {
      return const Result.error(
        AuthException(AuthErrorCode.invalidCredentials),
      );
    }
    _setUser(account.user);
    return Result.ok(account.user);
  }

  @override
  Future<Result<AppUser>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(delay);
    final key = _normalise(email);
    if (_accounts.containsKey(key)) {
      return const Result.error(AuthException(AuthErrorCode.emailAlreadyInUse));
    }
    if (password.length < 8) {
      return const Result.error(AuthException(AuthErrorCode.weakPassword));
    }
    final user = AppUser(
      id: 'user-${_nextId++}',
      name: name.trim(),
      email: key,
      createdAt: _now,
    );
    _accounts[key] = _Account(user, password);
    _setUser(user);
    return Result.ok(user);
  }

  @override
  Future<Result<void>> signOut() async {
    await Future<void>.delayed(delay);
    _setUser(null);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    await Future<void>.delayed(delay);
    return const Result.ok(null);
  }

  @override
  Future<Result<AppUser>> updateProfile({
    required String name,
    required String phone,
  }) async {
    await Future<void>.delayed(delay);
    final user = _currentUser;
    if (user == null) {
      return const Result.error(AuthException(AuthErrorCode.notSignedIn));
    }
    final trimmedPhone = phone.trim();
    final updated = user.copyWith(
      name: name.trim(),
      phone: trimmedPhone.isEmpty ? null : trimmedPhone,
      clearPhone: trimmedPhone.isEmpty,
    );
    final account = _accounts[user.email]!;
    _accounts[user.email] = _Account(updated, account.password);
    _setUser(updated);
    return Result.ok(updated);
  }

  void _setUser(AppUser? user) {
    _currentUser = user;
    notifyListeners();
  }

  static String _normalise(String email) => email.trim().toLowerCase();
}

class _Account {
  const _Account(this.user, this.password);

  final AppUser user;
  final String password;
}
