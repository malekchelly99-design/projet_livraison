import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/user_role.dart';

/// Accès à la collection Firestore `users`.
class UserService {
  final FirebaseFirestore _db;

  UserService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  // ── CRUD de base ─────────────────────────────────────────────────────────

  /// Crée un nouveau document utilisateur dans Firestore.
  /// L'ID du document est toujours = uid Firebase Auth.
  Future<void> create(AppUser user) {
    return _users.doc(user.uid).set({
      ...user.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Vérifie si un document utilisateur existe dans Firestore.
  Future<bool> exists(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists;
  }

  /// Récupère un utilisateur par UID (lecture unique).
  Future<AppUser?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    try {
      return AppUser.fromMap(doc.id, data);
    } catch (_) {
      return null;
    }
  }

  /// Écoute le profil en temps réel.
  /// Émet `null` tant que le document n'existe pas.
  Stream<AppUser?> watch(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      try {
        return AppUser.fromMap(doc.id, data);
      } catch (_) {
        return null;
      }
    });
  }

  // ── Restauration après migration ─────────────────────────────────────────

  /// Crée ou restaure un profil Firestore à partir des données Firebase Auth.
  ///
  /// Utilisé dans deux cas :
  ///   1. L'utilisateur se connecte mais son doc Firestore a été supprimé.
  ///   2. Un utilisateur Auth orphelin est détecté au démarrage.
  ///
  /// RÈGLE : ne jamais écraser un document existant.
  Future<void> createOrRestoreProfile({
    required String uid,
    required String email,
    String? displayName,
    String? phoneNumber,
    UserRole defaultRole = UserRole.client,
  }) async {
    // Sécurité : ne pas écraser si le profil existe déjà
    if (await exists(uid)) return;

    final appUser = AppUser(
      uid: uid,
      name: displayName?.isNotEmpty == true
          ? displayName!
          : email.split('@').first,
      email: email,
      phone: phoneNumber ?? '',
      role: defaultRole,
      profile: const {},
    );

    await create(appUser);
  }

  // ── Mise à jour ──────────────────────────────────────────────────────────

  /// Met à jour les informations de profil sans toucher au rôle.
  Future<void> updateProfile(String uid, Map<String, dynamic> data) {
    return _users.doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Met à jour le rôle d'un utilisateur (action admin).
  /// Ne change jamais automatiquement admin/vendeur/livreur → client.
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

  // ── Lecture admin ────────────────────────────────────────────────────────

  /// Écoute tous les utilisateurs en temps réel (admin uniquement).
  Stream<List<AppUser>> watchAllUsers() {
    return _users.snapshots().map((snapshot) {
      final list = <AppUser>[];
      for (final doc in snapshot.docs) {
        try {
          list.add(AppUser.fromMap(doc.id, doc.data()));
        } catch (_) {
          // Ignore les docs au schéma invalide
        }
      }
      return list;
    });
  }

  // ── Suppression ──────────────────────────────────────────────────────────

  /// Supprime un utilisateur de Firestore (pas de Firebase Auth).
  Future<void> deleteUser(String uid) async {
    await _users.doc(uid).delete();
    await _db.collection('boutiques').doc(uid).delete();
  }

  /// Purge les utilisateurs de test / démo.
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
