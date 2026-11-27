import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../auth/view_models/auth_error_message.dart';

typedef PasswordChange = ({String current, String next});

/// Changes the signed-in user's password.
class SecurityViewModel extends ChangeNotifier {
  SecurityViewModel({required this._authRepository}) {
    changePassword = Command1<void, PasswordChange>(_changePassword);
  }

  final AuthRepository _authRepository;

  late final Command1<void, PasswordChange> changePassword;

  /// The signed-in email, shown for context.
  String get email => _authRepository.currentUser?.email ?? '';

  /// Message for the last failed change, or null.
  String? get errorMessage => commandErrorMessage(changePassword);

  void clearError() => changePassword.clearResult();

  Future<Result<void>> _changePassword(PasswordChange change) =>
      _authRepository.changePassword(
        currentPassword: change.current,
        newPassword: change.next,
      );

  @override
  void dispose() {
    changePassword.dispose();
    super.dispose();
  }
}
