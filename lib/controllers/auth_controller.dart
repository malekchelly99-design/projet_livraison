import 'package:firebase_auth/firebase_auth.dart';

import '../core/auth_errors.dart';
import '../services/auth_service.dart';
import 'base_controller.dart';

/// Connexion / mot de passe oublié. Les méthodes renvoient
/// `null` en cas de succès, ou un message d'erreur à afficher.
class AuthController extends BaseController {
  final AuthService _auth;

  AuthController({AuthService? auth}) : _auth = auth ?? AuthService();

  bool _loading = false;
  bool get loading => _loading;

  Stream<User?> get authStateChanges => _auth.authStateChanges;

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _auth.login(email: email, password: password);
      return null; // AuthGate bascule automatiquement vers l'accueil.
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
