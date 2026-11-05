import 'dart:async';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'base_controller.dart';

/// Écoute le profil de l'utilisateur connecté (en temps réel)
/// et signale un délai dépassé si le profil n'apparaît pas.
/// Si le profil Firestore est manquant (migration), il est restauré automatiquement.
class HomeController extends BaseController {
  final AuthService _auth;
  final UserService _users;
  final String uid;
  final Stream<AppUser?> userStream;
  Timer? _timeout;
  bool _timedOut = false;
  bool _attemptedRestore = false;

  HomeController({
    required this.uid,
    AuthService? auth,
    UserService? users,
    Duration timeout = const Duration(seconds: 10),
  })  : _auth = auth ?? AuthService(),
        _users = users ?? UserService(),
        userStream = (users ?? UserService()).watch(uid) {
    // Avant d'afficher l'erreur de timeout, on tente de restaurer le profil.
    _timeout = Timer(timeout, () async {
      if (!_attemptedRestore) {
        _attemptedRestore = true;
        await _attemptRestoreProfile();
      }
      _timedOut = true;
      notifyListeners();
    });
  }

  bool get timedOut => _timedOut;

  /// Tente de créer le document Firestore manquant à partir de Firebase Auth.
  Future<void> _attemptRestoreProfile() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == uid) {
        final exists = await _users.exists(uid);
        if (!exists) {
          await _users.createOrRestoreProfile(
            uid: uid,
            email: currentUser.email ?? '',
            displayName: currentUser.displayName,
            phoneNumber: currentUser.phoneNumber,
          );
        }
      }
    } catch (e) {
      // Silencieux : on affichera l'erreur via timedOut
    }
  }

  Future<void> logout() => _auth.logout();

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }
}
