import 'package:flutter/material.dart';

import '../controllers/home_controller.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import 'dashboards.dart';

/// Écoute le profil de l'utilisateur (en temps réel)
/// et affiche l'espace correspondant à son rôle.
class HomeView extends StatefulWidget {
  final String uid;
  const HomeView({super.key, required this.uid});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeController _controller = HomeController(uid: widget.uid);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => StreamBuilder<AppUser?>(
        stream: _controller.userStream,
        builder: (context, snap) {
          final user = snap.data;
          if (user != null) return _dashboardFor(user);

          // Erreur Firestore, rôle inconnu, ou profil absent après 10 s
          if (snap.hasError || _controller.timedOut) return _errorView();

          // Profil en cours de création : on patiente
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),
    );
  }

  Widget _dashboardFor(AppUser user) {
    switch (user.role) {
      case UserRole.admin:
        return AdminHome(user: user, onLogout: _controller.logout);
      case UserRole.vendeur:
        return VendeurHome(user: user, onLogout: _controller.logout);
      case UserRole.livreur:
        return LivreurHome(user: user, onLogout: _controller.logout);
      case UserRole.client:
        return ClientHome(user: user, onLogout: _controller.logout);
    }
  }

  Widget _errorView() {
    return Scaffold(
      appBar: AppBar(title: const Text('Erreur')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Profil introuvable.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _controller.logout,
              child: const Text('Se déconnecter'),
            ),
          ],
        ),
      ),
    );
  }
}
