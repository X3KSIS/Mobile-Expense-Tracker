import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../data/repositories/sync/sync_repository.dart';
import '../../../domain/models/app_user.dart';
import '../../../utils/command.dart';
import '../../../utils/dates.dart';

/// State for the Profile screen: the signed-in user, sync status and
/// sign-out.
///
/// Rebuilds when the user changes, e.g. after editing personal details.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    required this._authRepository,
    required this._settingsRepository,
    required this._syncRepository,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _authRepository.addListener(_onAuthChanged);
    _settingsRepository.addListener(_onAuthChanged);
    _syncRepository.addListener(_onAuthChanged);
    syncNow = Command0<void>(_syncRepository.sync);
    signOut = Command0<void>(_authRepository.signOut);
  }

  final AuthRepository _authRepository;
  final SettingsRepository _settingsRepository;
  final SyncRepository _syncRepository;
  final DateTime Function() _clock;

  /// Sends and fetches changes now.
  late final Command0<void> syncNow;

  SyncStatus get syncStatus => _syncRepository.status;

  DateTime? get lastSyncedAt => _syncRepository.lastSyncedAt;

  DateTime get now => _clock();

  /// Signs out. The router then sends the user to the sign-in screen.
  late final Command0<void> signOut;

  /// App version shown at the bottom of the screen.
  static const String appVersion = '1.0.0';

  /// Currency all amounts are shown in.
  static const String currency = 'ZMW';

  bool _disposed = false;

  /// The signed-in user. Null only for a moment after signing out.
  AppUser? get user => _authRepository.currentUser;

  /// e.g. "Member since August 2026".
  String get memberSince {
    final current = user;
    if (current == null) return '';
    return 'Member since ${formatMonthYear(current.createdAt)}';
  }

  void _onAuthChanged() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _authRepository.removeListener(_onAuthChanged);
    _settingsRepository.removeListener(_onAuthChanged);
    _syncRepository.removeListener(_onAuthChanged);
    syncNow.dispose();
    signOut.dispose();
    super.dispose();
  }
}
