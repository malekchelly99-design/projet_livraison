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

  bool get isBlocked => (profile['isBlocked'] as bool?) ?? false;
  String get shopName => (profile['shopName'] as String?) ?? '';
  String get vehicleType => (profile['vehicleType'] as String?) ?? '';
  String get plateNumber => (profile['plateNumber'] as String?) ?? '';
  String get city => (profile['city'] as String?) ?? '';

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    Map<String, dynamic>? profile,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profile: profile ?? this.profile,
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

