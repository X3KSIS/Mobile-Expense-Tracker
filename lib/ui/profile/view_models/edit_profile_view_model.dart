import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../domain/models/app_user.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../../utils/validators.dart';
import '../../auth/view_models/auth_error_message.dart';

typedef ProfileDetails = ({String name, String phone});

/// Edits the signed-in user's photo, name and phone number.
class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel({required this._authRepository}) {
    save = Command1<void, ProfileDetails>(_save);
    setPhoto = Command1<void, Uint8List?>(_setPhoto);
    _authRepository.addListener(_onUserChanged);
  }

  final AuthRepository _authRepository;

  late final Command1<void, ProfileDetails> save;

  /// Saves a new photo (JPEG bytes), or removes it when given null. Applies
  /// at once, without Save changes.
  late final Command1<void, Uint8List?> setPhoto;

  bool _disposed = false;

  /// The current photo, or null.
  Uint8List? get photo => _authRepository.currentUser?.photo;

  String get initials => _authRepository.currentUser?.initials ?? '';

  /// The user as they were when the screen opened, for the initial values.
  AppUser? get user => _authRepository.currentUser;

  /// Message for the last failed save, or null.
  String? get errorMessage => commandErrorMessage(save);

  void clearError() => save.clearResult();

  Future<Result<void>> _save(ProfileDetails details) async {
    final result = await _authRepository.updateProfile(
      name: details.name.trim(),
      phone: Validators.normalisePhone(details.phone),
    );
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
  }

  Future<Result<void>> _setPhoto(Uint8List? photo) async {
    final result = await _authRepository.setPhoto(photo);
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
  }

  void _onUserChanged() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _authRepository.removeListener(_onUserChanged);
    setPhoto.dispose();
    save.dispose();
    super.dispose();
  }
}
