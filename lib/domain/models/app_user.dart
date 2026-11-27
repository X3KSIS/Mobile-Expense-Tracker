import 'dart:typed_data';

/// The signed-in person's profile.
///
/// Named `AppUser` so it never clashes with Supabase's `User`.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.phone,
    this.photo,
  });

  final String id;
  final String name;
  final String email;

  /// Optional mobile number, e.g. `0971234567`.
  final String? phone;

  /// When the account was created.
  final DateTime createdAt;

  /// Profile photo (JPEG bytes), or null to show [initials].
  final Uint8List? photo;

  /// Up to two initials from [name], e.g. "PM" for "Paul Mubanga".
  String get initials => name
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  /// Returns a copy with a new [name] and/or [phone]. Pass [clearPhone] to
  /// remove the phone number.
  AppUser copyWith({String? name, String? phone, bool clearPhone = false}) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: clearPhone ? null : (phone ?? this.phone),
        createdAt: createdAt,
        photo: photo,
      );

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.name == name &&
      other.email == email &&
      other.phone == phone &&
      other.createdAt == createdAt &&
      _sameBytes(other.photo, photo);

  static bool _sameBytes(Uint8List? a, Uint8List? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, email, phone, createdAt, photo?.length);

  @override
  String toString() => 'AppUser($id, $name, $email)';
}
