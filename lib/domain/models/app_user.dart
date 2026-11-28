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
    this.preferredName,
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

  /// What the user likes to be called, e.g. "Paul" or "PM"; null when not
  /// set.
  final String? preferredName;

  /// The name to greet the user by: [preferredName] when set, otherwise
  /// the first word of [name].
  String get displayName {
    final preferred = preferredName?.trim() ?? '';
    if (preferred.isNotEmpty) return preferred;
    return name.trim().split(RegExp(r'\s+')).first;
  }

  /// Up to two initials from [name], e.g. "PM" for "Paul Mubanga".
  String get initials => name
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  /// Returns a copy with a new [name], [phone] and/or [preferredName].
  /// Pass [clearPhone] or [clearPreferredName] to remove those.
  AppUser copyWith({
    String? name,
    String? phone,
    bool clearPhone = false,
    String? preferredName,
    bool clearPreferredName = false,
  }) => AppUser(
    id: id,
    name: name ?? this.name,
    email: email,
    phone: clearPhone ? null : (phone ?? this.phone),
    createdAt: createdAt,
    photo: photo,
    preferredName: clearPreferredName
        ? null
        : (preferredName ?? this.preferredName),
  );

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.name == name &&
      other.email == email &&
      other.phone == phone &&
      other.preferredName == preferredName &&
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
  int get hashCode => Object.hash(
    id,
    name,
    email,
    phone,
    preferredName,
    createdAt,
    photo?.length,
  );

  @override
  String toString() => 'AppUser($id, $name, $email)';
}
