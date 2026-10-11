import 'dart:async';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'base_controller.dart';

/// Écoute le profil de l'utilisateur connecté (en temps réel)
/// et signale un délai dépassé si le profil n'apparaît pas.
class HomeController extends BaseController {
  final AuthService _auth;
  final Stream<AppUser?> userStream;
  Timer? _timeout;
  bool _timedOut = false;

  HomeController({
    required String uid,
    AuthService? auth,
    UserService? users,
    Duration timeout = const Duration(seconds: 10),
  })  : _auth = auth ?? AuthService(),
        userStream = (users ?? UserService()).watch(uid) {
    // Si le profil n'apparaît pas au bout de [timeout], on affiche une erreur.
    _timeout = Timer(timeout, () {
      _timedOut = true;
      notifyListeners();
    });
  }

  bool get timedOut => _timedOut;

  Future<void> logout() => _auth.logout();

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }
}
