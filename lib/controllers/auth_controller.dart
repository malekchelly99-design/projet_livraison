import 'package:firebase_auth/firebase_auth.dart';

import '../core/auth_errors.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/boutique_sync_service.dart';
import '../services/user_service.dart';
import 'base_controller.dart';

/// Connexion / mot de passe oublié.
/// Les méthodes renvoient `null` en cas de succès, ou un message d'erreur.
class AuthController extends BaseController {
  final AuthService _auth;
  final UserService _users;
  final BoutiqueSyncService _boutiqueSync;

  AuthController({
    AuthService? auth,
    UserService? users,
    BoutiqueSyncService? boutiqueSync,
  })  : _auth = auth ?? AuthService(),
        _users = users ?? UserService(),
        _boutiqueSync = boutiqueSync ?? BoutiqueSyncService();

  bool _loading = false;
  bool get loading => _loading;

  Stream<User?> get authStateChanges => _auth.authStateChanges;

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final credential = await _auth.login(email: email, password: password);
      final user = credential.user;

      if (user != null) {
        // ── Vérifier que le doc Firestore existe ────────────────────────────
        // Cas courant après migration : Auth existe, Firestore a été supprimé.
        final exists = await _users.exists(user.uid);
        if (!exists) {
          // Restaurer automatiquement le profil avec les données Auth
          await _users.createOrRestoreProfile(
            uid: user.uid,
            email: user.email ?? email,
            displayName: user.displayName,
            phoneNumber: user.phoneNumber,
          );
        }

        // ── Vérifier si c'est un vendeur et si sa boutique existe ──────────
        final appUser = await _users.getUser(user.uid);
        if (appUser != null && appUser.role == UserRole.vendeur) {
          // Restore missing boutique if needed (rare edge case)
          await _boutiqueSync.restoreMissingBoutiqueIfNeeded(user.uid);
        }
      }

      return null; // AuthGate bascule vers HomeView
    } on FirebaseAuthException catch (e) {
      return authErrorMessage(e);
    } catch (e) {
      return authErrorMessage(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.resetPassword(email);
      return null;
    } catch (e) {
      return authErrorMessage(e);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
