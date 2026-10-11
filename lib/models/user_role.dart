/// Les 4 rôles de l'application.
/// - client, vendeur, livreur : choisis à l'inscription
/// - admin : JAMAIS choisi depuis l'app, attribué à la main dans Firestore
enum UserRole {
  client,
  vendeur,
  livreur,
  admin;

  /// Retrouve un rôle à partir de son nom stocké dans Firestore.
  static UserRole? fromName(String? name) {
    for (final role in values) {
      if (role.name == name) return role;
    }
    return null;
  }
}

/// Rôles qu'un utilisateur peut choisir lui-même à l'inscription.
const selfRegisterRoles = [
  UserRole.client,
  UserRole.vendeur,
  UserRole.livreur,
];
