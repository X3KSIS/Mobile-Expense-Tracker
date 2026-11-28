import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../domain/models/app_user.dart';
import '../../../domain/models/auth_exception.dart';
import '../../../utils/result.dart';
import '../../services/database/app_database.dart';
import 'auth_repository.dart';

/// [AuthRepository] on Supabase Auth (email and password).
///
/// Supabase keeps the session on the device, so the user stays signed in
/// across launches. The profile (name, phone) lives on the device's
/// profile row and syncs to the `profiles` table. Call [load] before the
/// app starts.
class AuthRepositorySupabase extends AuthRepository {
  AuthRepositorySupabase(
    this._auth,
    this._db, {
    this._client,
    this.beforeSignOut,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _authChanges = _auth.onAuthStateChange.listen(_onAuthChange);
    _profileChanges = _db
        .tableUpdates(TableUpdateQuery.onTable(_db.profiles))
        .listen((_) => _reloadProfile());
  }

  final sb.GoTrueClient _auth;

  /// For usernames: the database functions and the sign-in Edge Function.
  final sb.SupabaseClient? _client;

  /// The Edge Function that signs in with a username
  /// (`supabase/functions/sign-in-with-username`).
  static const String usernameSignInFunction = 'sign-in-with-username';
  final AppDatabase _db;
  final DateTime Function() _clock;

  /// Runs before signing out, to send unsaved changes (the sync).
  final Future<Object?> Function()? beforeSignOut;

  late final StreamSubscription<sb.AuthState> _authChanges;
  late final StreamSubscription<Set<TableUpdate>> _profileChanges;
  AppUser? _user;

  @override
  bool get isAuthenticated => _auth.currentSession != null && _user != null;

  @override
  AppUser? get currentUser => _user;

  /// Restores the signed-in user from the saved session.
  Future<void> load() async {
    final user = _auth.currentUser;
    if (_auth.currentSession == null || user == null) return;
    await _open(user);
  }

  @override
  Future<Result<AppUser>> signIn({
    required String identifier,
    required String password,
  }) => _call(() async {
    if (!identifier.contains('@')) {
      return _signInWithUsername(identifier, password);
    }
    final response = await _auth.signInWithPassword(
      email: identifier.trim(),
      password: password,
    );
    final user = response.user;
    if (user == null) throw const AuthException(AuthErrorCode.unknown);
    return _open(user);
  });

  @override
  Future<Result<AppUser>> signUp({
    required String name,
    required String email,
    required String password,
  }) => _call(() async {
    final response = await _auth.signUp(
      email: email.trim(),
      password: password,
      data: {'name': name.trim()},
    );
    final user = response.user;
    // With email confirmation on, an email that already has an account
    // comes back as a user without identities.
    if (user != null && (user.identities?.isEmpty ?? false)) {
      throw const AuthException(AuthErrorCode.emailAlreadyInUse);
    }
    if (user == null) throw const AuthException(AuthErrorCode.unknown);
    if (response.session == null) {
      throw const AuthException(AuthErrorCode.confirmEmail);
    }
    return _open(user);
  });

  @override
  Future<Result<AppUser>> verifyEmail({
    required String email,
    required String code,
  }) => _call(() async {
    final response = await _auth.verifyOTP(
      type: sb.OtpType.signup,
      email: email.trim(),
      token: code.trim(),
    );
    final user = response.user;
    if (user == null || response.session == null) {
      throw const AuthException(AuthErrorCode.invalidCode);
    }
    return _open(user);
  });

  @override
  Future<Result<void>> resendEmailCode(String email) =>
      _call(() => _auth.resend(type: sb.OtpType.signup, email: email.trim()));

  @override
  Future<Result<void>> signOut() => _call(() async {
    await beforeSignOut?.call();
    if (await _db.hasUnsyncedChanges()) {
      throw const AuthException(AuthErrorCode.unsyncedChanges);
    }
    await _auth.signOut();
    await _db.clearAll();
    _user = null;
    notifyListeners();
  });

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) =>
      _call(() => _auth.resetPasswordForEmail(email.trim()));

  @override
  Future<Result<AppUser>> updateProfile({
    required String name,
    required String phone,
    String preferredName = '',
  }) => _call(() async {
    final user = _user;
    if (user == null) throw const AuthException(AuthErrorCode.notSignedIn);
    final trimmedPhone = phone.trim();
    final preferred = preferredName.trim();
    await (_db.update(
      _db.profiles,
    )..where((p) => p.userId.equals(user.id))).write(
      ProfilesCompanion(
        name: Value(name.trim()),
        phone: Value(trimmedPhone.isEmpty ? null : trimmedPhone),
        preferredName: Value(preferred.isEmpty ? null : preferred),
        modifiedAt: Value(_clock()),
        dirty: const Value(true),
      ),
    );
    return _reloadProfile().then((updated) => updated ?? user);
  });

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _call(() async {
    final email = _auth.currentUser?.email;
    if (email == null) throw const AuthException(AuthErrorCode.notSignedIn);
    // Signing in again proves the current password before it changes.
    try {
      await _auth.signInWithPassword(email: email, password: currentPassword);
    } on sb.AuthException catch (e) {
      if (e.code == 'invalid_credentials') {
        throw const AuthException(AuthErrorCode.wrongPassword);
      }
      rethrow;
    }
    await _auth.updateUser(sb.UserAttributes(password: newPassword));
  });

  /// The Edge Function finds the account on the server and returns a
  /// refresh token, so the email behind a username never reaches the
  /// device. A wrong username and a wrong password give the same error.
  Future<AppUser> _signInWithUsername(String username, String password) async {
    final client = _client;
    if (client == null) throw const AuthException(AuthErrorCode.unknown);
    final String token;
    try {
      final response = await client.functions.invoke(
        usernameSignInFunction,
        body: {'username': username.trim().toLowerCase(), 'password': password},
      );
      final data = response.data;
      final value = data is Map ? data['refresh_token'] : null;
      if (value is! String) throw const AuthException(AuthErrorCode.unknown);
      token = value;
    } on sb.FunctionException catch (e) {
      final details = e.details;
      final code = details is Map ? details['error'] : null;
      throw AuthException(switch (code) {
        'invalid_credentials' => AuthErrorCode.invalidCredentials,
        'email_not_confirmed' => AuthErrorCode.emailNotConfirmed,
        'too_many_requests' => AuthErrorCode.tooManyRequests,
        _ => AuthErrorCode.unknown,
      });
    }
    final session = await _auth.setSession(token);
    final user = session.user;
    if (user == null) throw const AuthException(AuthErrorCode.unknown);
    return _open(user);
  }

  @override
  Future<Result<AppUser>> setUsername(String? username) => _call(() async {
    final user = _user;
    final client = _client;
    if (user == null) throw const AuthException(AuthErrorCode.notSignedIn);
    if (client == null) throw const AuthException(AuthErrorCode.unknown);
    final cleaned = username?.trim().toLowerCase() ?? '';
    final Object? stored;
    try {
      stored = await client.rpc(
        'set_username',
        params: {'new_username': cleaned.isEmpty ? null : cleaned},
      );
    } on sb.PostgrestException catch (e) {
      throw AuthException(
        e.message.contains('username_taken') || e.code == '23505'
            ? AuthErrorCode.usernameTaken
            : e.message.contains('username_invalid')
            ? AuthErrorCode.usernameInvalid
            : AuthErrorCode.unknown,
      );
    }
    // Already on the server, so the row stays clean.
    await (_db.update(_db.profiles)..where((p) => p.userId.equals(user.id)))
        .write(ProfilesCompanion(username: Value(stored as String?)));
    return _reloadProfile().then((updated) => updated ?? user);
  });

  @override
  Future<Result<bool>> isUsernameAvailable(String username) => _call(() async {
    final client = _client;
    if (client == null) throw const AuthException(AuthErrorCode.unknown);
    final free = await client.rpc(
      'username_available',
      params: {'candidate': username.trim().toLowerCase()},
    );
    return free == true;
  });

  @override
  Future<Result<AppUser>> setPhoto(Uint8List? photo) => _call(() async {
    final user = _user;
    if (user == null) throw const AuthException(AuthErrorCode.notSignedIn);
    await (_db.update(
      _db.profiles,
    )..where((p) => p.userId.equals(user.id))).write(
      ProfilesCompanion(
        avatarBytes: Value(photo),
        avatarDirty: const Value(true),
        modifiedAt: Value(_clock()),
        dirty: const Value(true),
      ),
    );
    return _reloadProfile().then((updated) => updated ?? user);
  });

  Future<AppUser> _open(sb.User user) async {
    final row = await _db.openAccount(
      userId: user.id,
      email: user.email ?? '',
      name: (user.userMetadata?['name'] as String?) ?? '',
      createdAt: DateTime.tryParse(user.createdAt)?.toLocal() ?? _clock(),
    );
    final appUser = _toAppUser(row);
    _user = appUser;
    notifyListeners();
    return appUser;
  }

  /// Picks up profile changes, including ones that arrived by sync.
  Future<AppUser?> _reloadProfile() async {
    final id = _user?.id;
    if (id == null) return null;
    final row = await (_db.select(
      _db.profiles,
    )..where((p) => p.userId.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final updated = _toAppUser(row);
    if (updated != _user) {
      _user = updated;
      notifyListeners();
    }
    return updated;
  }

  static AppUser _toAppUser(ProfileRow row) => AppUser(
    id: row.userId,
    name: row.name,
    email: row.email,
    phone: row.phone,
    createdAt: row.createdAt,
    photo: row.avatarBytes,
    preferredName: row.preferredName,
    username: row.username,
  );

  /// The session ended elsewhere (expired or revoked).
  void _onAuthChange(sb.AuthState state) {
    if (state.event == sb.AuthChangeEvent.signedOut && _user != null) {
      _user = null;
      notifyListeners();
    }
  }

  /// Turns Supabase and network failures into [AuthException]s.
  Future<Result<T>> _call<T>(Future<T> Function() body) async {
    try {
      return Result.ok(await body());
    } on AuthException catch (e) {
      return Result.error(e);
    } on sb.AuthRetryableFetchException {
      return const Result.error(AuthException(AuthErrorCode.network));
    } on sb.AuthWeakPasswordException {
      return const Result.error(AuthException(AuthErrorCode.weakPassword));
    } on sb.AuthException catch (e) {
      return Result.error(AuthException(_codeFor(e)));
    } on SocketException {
      return const Result.error(AuthException(AuthErrorCode.network));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  static AuthErrorCode _codeFor(sb.AuthException e) => switch (e.code) {
    'invalid_credentials' => AuthErrorCode.invalidCredentials,
    'email_not_confirmed' => AuthErrorCode.emailNotConfirmed,
    'user_already_exists' || 'email_exists' => AuthErrorCode.emailAlreadyInUse,
    'weak_password' => AuthErrorCode.weakPassword,
    'same_password' => AuthErrorCode.samePassword,
    'otp_expired' || 'otp_disabled' => AuthErrorCode.invalidCode,
    'over_email_send_rate_limit' ||
    'over_request_rate_limit' => AuthErrorCode.tooManyRequests,
    _ => AuthErrorCode.unknown,
  };

  @override
  void dispose() {
    _authChanges.cancel();
    _profileChanges.cancel();
    super.dispose();
  }
}
