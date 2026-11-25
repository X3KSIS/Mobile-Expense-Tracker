/// Form field validators. Each returns an error message, or null when the
/// value is valid, so they plug straight into `TextFormField.validator`.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final RegExp _zambianPhone = RegExp(r'^(\+260|260|0)[79]\d{8}$');
  static final RegExp _letter = RegExp('[A-Za-z]');
  static final RegExp _digit = RegExp(r'\d');
  static final RegExp _phoneSeparators = RegExp(r'[\s-]');

  /// Minimum length for new passwords.
  static const int minPasswordLength = 8;

  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your name';
    if (text.length < 2) return 'Name is too short';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your email';
    if (!_email.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }

  /// For signing in: only checks that something was typed.
  static String? existingPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password';
    return null;
  }

  /// For new passwords: at least 8 characters with a letter and a number.
  static String? newPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Enter a password';
    if (text.length < minPasswordLength) {
      return 'Use at least $minPasswordLength characters';
    }
    if (!_letter.hasMatch(text) || !_digit.hasMatch(text)) {
      return 'Include at least one letter and one number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != password) return "Passwords don't match";
    return null;
  }

  /// Optional Zambian mobile number, e.g. `097 123 4567` or `+260971234567`.
  static String? optionalPhone(String? value) {
    final text = normalisePhone(value ?? '');
    if (text.isEmpty) return null;
    if (!_zambianPhone.hasMatch(text)) {
      return 'Enter a valid number, e.g. 097 123 4567';
    }
    return null;
  }

  /// Strips spaces and dashes from a phone number.
  static String normalisePhone(String value) =>
      value.trim().replaceAll(_phoneSeparators, '');
}
