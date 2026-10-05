import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Les 4 rôles de l'application.
/// - client, vendeur, livreur : choisis à l'inscription
/// - admin : JAMAIS choisi depuis l'app, attribué à la main dans Firestore
enum UserRole { client, vendeur, livreur, admin }

/// Rôles qu'un utilisateur peut choisir lui-même à l'inscription.
const selfRegisterRoles = [UserRole.client, UserRole.vendeur, UserRole.livreur];

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    Map<String, dynamic> profile = const {},
  }) async {
    if (!selfRegisterRoles.contains(role)) {
      throw ArgumentError('Rôle non autorisé à l\'inscription');
    }
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user!.updateDisplayName(name.trim());
    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'role': role.name,
      'profile': profile, // infos pro (boutique ou véhicule), vide pour un client
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> login({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> resetPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> logout() => _auth.signOut();

  Future<String?> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['role'] as String?;
  }

  /// Écoute le rôle en temps réel : si le profil est créé juste après
  /// l'inscription, l'écran se met à jour automatiquement.
  Stream<String?> roleStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data()?['role'] as String?);
  }

  /// Messages d'erreur lisibles en français.
  static String errorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return "L'adresse email n'est pas valide.";
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email ou mot de passe incorrect.';
        case 'email-already-in-use':
          return 'Un compte existe déjà avec cet email.';
        case 'weak-password':
          return 'Mot de passe trop faible (6 caractères minimum).';
        case 'too-many-requests':
          return 'Trop de tentatives. Réessaie plus tard.';
        case 'network-request-failed':
          return 'Problème de connexion internet.';
      }
    }
    return 'Une erreur est survenue. Réessaie.';
  }
}