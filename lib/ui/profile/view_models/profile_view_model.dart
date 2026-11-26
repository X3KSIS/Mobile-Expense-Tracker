import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../domain/models/app_user.dart';
import '../../../utils/command.dart';
import '../../../utils/dates.dart';

/// State for the Profile screen: the signed-in user, payday and sign-out.
///
/// Rebuilds when the user changes, e.g. after editing personal details.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    required this._authRepository,
    required this._settingsRepository,
  }) {
    _authRepository.addListener(_onAuthChanged);
    _settingsRepository.addListener(_onAuthChanged);
    signOut = Command0<void>(_authRepository.signOut);
  }

  final AuthRepository _authRepository;
  final SettingsRepository _settingsRepository;

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

  /// Day of the month pay arrives.
  int get payday => _settingsRepository.payday;

  /// e.g. '25th of the month', or '1st (calendar months)'.
  String get paydayLabel =>
      payday == 1 ? '1st (calendar months)' : '${ordinal(payday)} of the month';

  void setPayday(int day) => _settingsRepository.setPayday(day);

  void _onAuthChanged() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _authRepository.removeListener(_onAuthChanged);
    _settingsRepository.removeListener(_onAuthChanged);
    signOut.dispose();
    super.dispose();
  }
}
