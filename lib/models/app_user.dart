import 'user_role.dart';

/// Profil d'un utilisateur, tel que stocké dans la collection `users`.
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;

  /// Infos pro (boutique ou véhicule), vide pour un client.
  final Map<String, dynamic> profile;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profile = const {},
  });

  /// Lève une [FormatException] si le rôle est absent ou inconnu.
  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    final role = UserRole.fromName(data['role'] as String?);
    if (role == null) {
      throw FormatException('Rôle inconnu : ${data['role']}');
    }
    return AppUser(
      uid: uid,
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      role: role,
      profile: Map<String, dynamic>.from((data['profile'] as Map?) ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name,
        'profile': profile,
      };
}
