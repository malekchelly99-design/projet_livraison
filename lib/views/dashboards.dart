import 'package:flutter/material.dart';

import '../models/app_user.dart';
import 'client/client_dashboard_view.dart';
import 'livreur/livreur_dashboard_view.dart';

/// Squelette commun : barre du haut + déconnexion + contenu du rôle.
class _DashboardScaffold extends StatelessWidget {
  final AppUser user;
  final VoidCallback onLogout;
  final String title;
  final IconData icon;
  final String message;

  const _DashboardScaffold({
    required this.user,
    required this.onLogout,
    required this.title,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: onLogout,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text('Bonjour ${user.name} 👋',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class ClientHome extends StatelessWidget {
  final AppUser user;
  final VoidCallback onLogout;
  const ClientHome({super.key, required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) => ClientDashboardView(
        user: user,
        onLogout: onLogout,
      );
}

class VendeurHome extends StatelessWidget {
  final AppUser user;
  final VoidCallback onLogout;
  const VendeurHome({super.key, required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) => _DashboardScaffold(
        user: user,
        onLogout: onLogout,
        title: 'Espace vendeur',
        icon: Icons.storefront,
        message: 'Ici : votre boutique, vos produits et les commandes reçues.',
      );
}

class LivreurHome extends StatelessWidget {
  final AppUser user;
  final VoidCallback onLogout;
  const LivreurHome({super.key, required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) => LivreurDashboardView(
        user: user,
        onLogout: onLogout,
      );
}

class AdminHome extends StatelessWidget {
  final AppUser user;
  final VoidCallback onLogout;
  const AdminHome({super.key, required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) => _DashboardScaffold(
        user: user,
        onLogout: onLogout,
        title: 'Administration',
        icon: Icons.admin_panel_settings_outlined,
        message: 'Ici : gestion des utilisateurs, vendeurs, livreurs et commandes.',
      );
}
