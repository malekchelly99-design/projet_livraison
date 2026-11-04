import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

/// Accès à la collection Firestore `users`.
class UserService {
  final FirebaseFirestore _db;

  UserService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Future<void> create(AppUser user) {
    return _users.doc(user.uid).set({
      ...user.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Écoute le profil en temps réel : si le profil est créé juste après
  /// l'inscription, l'écran se met à jour automatiquement.
  /// Émet `null` tant que le document n'existe pas, et une erreur
  /// si le rôle stocké est inconnu.
  Stream<AppUser?> watch(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      final data = doc.data();
      return data == null ? null : AppUser.fromMap(doc.id, data);
    });
  }

  /// Met à jour les informations du profil utilisateur.
  Future<void> updateProfile(String uid, Map<String, dynamic> data) {
    return _users.doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Écoute tous les utilisateurs en temps réel (pour l'administration).
  Stream<List<AppUser>> watchAllUsers() {
    return _users.snapshots().map((snapshot) {
      final list = <AppUser>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        try {
          list.add(AppUser.fromMap(doc.id, data));
        } catch (_) {
          // Ignore documents with invalid schema
        }
      }
      return list;
    });
  }

  /// Met à jour le rôle d'un utilisateur.
  Future<void> updateRole(String uid, String roleName) {
    return _users.doc(uid).update({
      'role': roleName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Bloque ou débloque un utilisateur.
  Future<void> toggleUserBlocked(String uid, bool isBlocked) {
    return _users.doc(uid).update({
      'profile.isBlocked': isBlocked,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Supprime un utilisateur de Firestore.
  Future<void> deleteUser(String uid) async {
    await _users.doc(uid).delete();
    // Si c'était un vendeur, on retire aussi sa fiche boutique.
    await _db.collection('boutiques').doc(uid).delete();
  }

  /// Supprime tous les utilisateurs de test / démo de la collection users.
  Future<int> purgeDemoUsers() async {
    final snapshot = await _users.get();
    int count = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final email = (data['email'] as String? ?? '').toLowerCase();
      final uid = doc.id.toLowerCase();
      final name = (data['name'] as String? ?? '').toLowerCase();

      final isDemo = uid.startsWith('demo_') ||
          email.contains('demo') ||
          email.endsWith('@livraison.com') ||
          email.contains('bellanapoli.tn') ||
          name.contains('ali ben salah') ||
          name.contains('karim gharbi') ||
          name.contains('marco bellini');

      if (isDemo) {
        await doc.reference.delete();
        await _db.collection('boutiques').doc(doc.id).delete();
        count++;
      }
    }
    return count;
  }
}
