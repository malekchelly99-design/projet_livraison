import 'package:flutter/foundation.dart';

/// ChangeNotifier qui ignore les notifications après `dispose()`.
/// Utile car un écran peut disparaître pendant un appel réseau
/// (ex. : après connexion, AuthGate remplace l'écran de login).
abstract class BaseController extends ChangeNotifier {
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
