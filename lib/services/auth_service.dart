import 'package:firebase_auth/firebase_auth.dart';

/// Accès à Firebase Authentication. Aucune logique d'affichage ici.
class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Utilisateur actuellement connecté (null si déconnecté)
  User? get currentUser => _auth.currentUser;

  /// Crée un nouveau compte Firebase Auth et renvoie l'UID.
  /// Lève [FirebaseAuthException] avec code 'email-already-in-use'
  /// si le compte existe déjà dans Authentication.
  Future<String> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user!.updateDisplayName(name.trim());
    return cred.user!.uid;
  }

  /// Connexion avec email/password, retourne le [UserCredential].
  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> resetPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> logout() => _auth.signOut();
}
