import 'dart:typed_data';

import '../../../domain/models/app_user.dart';
import '../../../domain/models/auth_exception.dart';
import '../../../utils/result.dart';
import 'auth_repository.dart';

/// In-memory [AuthRepository] for tests only. The app always uses
/// `AuthRepositorySupabase`.
///
/// Every sign-in and sign-up succeeds, whatever is typed:
/// - Signing in with the email of an account created this session opens
///   that account. Any other input (even empty) opens the demo account.
/// - Signing up creates an account from the details given, falling back to
///   the demo name and email for blank fields.
///
/// Nothing is persisted, so the app starts signed out unless [signedIn] is
/// true.
class AuthRepositoryLocalFake extends AuthRepository {
  AuthRepositoryLocalFake({
    this.delay = const Duration(milliseconds: 600),
    bool signedIn = false,
    DateTime? now,
  }) : _now = now ?? DateTime.now() {
    final demo = AppUser(
      id: 'user-1',
      name: demoName,
      email: demoEmail,
      phone: '0971234567',
      createdAt: DateTime(_now.year, _now.month - 3, 12),
    );
    _accounts[demoEmail] = demo;
    if (signedIn) _currentUser = demo;
  }

  static const String demoName = 'Paul Mubanga';
  static const String demoEmail = 'demo@expensetrack.app';

  /// Simulated network latency.
  final Duration delay;

  final DateTime _now;
  final Map<String, AppUser> _accounts = {};
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
    final user = _accounts[_normalise(email)] ?? _accounts[demoEmail]!;
    _setUser(user);
    return Result.ok(user);
  }

  @override
  Future<Result<AppUser>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(delay);
    final trimmedName = name.trim();
    final key = _normalise(email).isEmpty ? demoEmail : _normalise(email);
    final user = AppUser(
      id: 'user-${_nextId++}',
      name: trimmedName.isEmpty ? demoName : trimmedName,
      email: key,
      createdAt: _now,
    );
    _accounts[key] = user;
    _setUser(user);
    return Result.ok(user);
  }

  @override
  Future<Result<AppUser>> setPhoto(Uint8List? photo) async {
    await Future<void>.delayed(delay);
    final user = _currentUser;
    if (user == null) {
      return const Result.error(AuthException(AuthErrorCode.notSignedIn));
    }
    final updated = AppUser(
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      createdAt: user.createdAt,
      photo: photo,
    );
    _currentUser = updated;
    _accounts[user.email] = updated;
    notifyListeners();
    return Result.ok(updated);
  }

  /// The only code [verifyEmail] accepts.
  static const String validCode = '123456';

  @override
  Future<Result<AppUser>> verifyEmail({
    required String email,
    required String code,
  }) async {
    await Future<void>.delayed(delay);
    final account = _accounts[_normalise(email)];
    if (code.trim() != validCode || account == null) {
      return const Result.error(AuthException(AuthErrorCode.invalidCode));
    }
    _currentUser = account;
    notifyListeners();
    return Result.ok(account);
  }

  @override
  Future<Result<void>> resendEmailCode(String email) async {
    await Future<void>.delayed(delay);
    return const Result.ok(null);
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
    _accounts[user.email] = updated;
    _setUser(updated);
    return Result.ok(updated);
  }

  void _setUser(AppUser? user) {
    _currentUser = user;
    notifyListeners();
  }

  static String _normalise(String email) => email.trim().toLowerCase();
}
