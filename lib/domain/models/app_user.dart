/// The signed-in person's profile.
///
/// Named `AppUser` so it never clashes with Firebase's `User` once Firebase
/// Auth is added.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.phone,
  });

  final String id;
  final String name;
  final String email;

  /// Optional mobile number, e.g. `0971234567`.
  final String? phone;

  /// When the account was created.
  final DateTime createdAt;

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
      );

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.name == name &&
      other.email == email &&
      other.phone == phone &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, name, email, phone, createdAt);

  @override
  String toString() => 'AppUser($id, $name, $email)';
}
