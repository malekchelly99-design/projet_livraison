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
}
