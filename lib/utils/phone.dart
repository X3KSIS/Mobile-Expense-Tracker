/// Formats a stored Zambian mobile number for display:
/// `0971234567` becomes `097 123 4567` and `+260971234567` becomes
/// `+260 97 123 4567`. Anything else is returned unchanged.
String formatPhone(String phone) {
  final local = RegExp(r'^0(\d{2})(\d{3})(\d{4})$').firstMatch(phone);
  if (local != null) {
    return '0${local[1]} ${local[2]} ${local[3]}';
  }
  final international = RegExp(r'^\+?260(\d{2})(\d{3})(\d{4})$')
      .firstMatch(phone);
  if (international != null) {
    return '+260 ${international[1]} ${international[2]} ${international[3]}';
  }
  return phone;
}
