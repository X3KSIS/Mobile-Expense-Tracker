import 'package:flutter/foundation.dart';

import '../../../domain/models/app_user.dart';
import '../../../utils/result.dart';

/// Source of truth for who is signed in.
///
/// Extends [ChangeNotifier] so the router can listen to it and redirect when
/// the user signs in or out. Failures come back as `Result.error` holding an
/// `AuthException`.
abstract class AuthRepository extends ChangeNotifier {
  /// Whether someone is signed in.
  bool get isAuthenticated;

  /// The signed-in user, or null when signed out.
  AppUser? get currentUser;

  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  });

  /// Creates an account and signs it in.
  Future<Result<AppUser>> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Confirms [email] with the [code] emailed after sign-up, and signs
  /// the account in.
  Future<Result<AppUser>> verifyEmail({
    required String email,
    required String code,
  });

  /// Emails a new sign-up confirmation code to [email].
  Future<Result<void>> resendEmailCode(String email);

  Future<Result<void>> signOut();

  /// Sends a password reset link. Succeeds even when no account exists for
  /// [email], so the app never reveals which emails are registered.
  Future<Result<void>> sendPasswordResetEmail(String email);

  /// Changes the password after checking [currentPassword].
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Sets the profile photo (JPEG bytes), or removes it when null.
  Future<Result<AppUser>> setPhoto(Uint8List? photo);

  /// Updates the signed-in user's name and phone. An empty [phone] clears it.
  Future<Result<AppUser>> updateProfile({
    required String name,
    required String phone,
  });
}
