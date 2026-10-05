import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// Squelette commun : barre du haut + déconnexion + contenu du rôle.
class _DashboardScaffold extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;

  const _DashboardScaffold({
    required this.title,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final user = auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: auth.logout,
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
              Text('Bonjour ${user?.displayName ?? ''} 👋',
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
  const ClientHome({super.key});
  @override
  Widget build(BuildContext context) => const _DashboardScaffold(
    title: 'Espace client',
    icon: Icons.shopping_bag_outlined,
    message: 'Ici : catalogue, panier et suivi de vos commandes.',
  );
}

class VendeurHome extends StatelessWidget {
  const VendeurHome({super.key});
  @override
  Widget build(BuildContext context) => const _DashboardScaffold(
    title: 'Espace vendeur',
    icon: Icons.storefront,
    message: 'Ici : votre boutique, vos produits et les commandes reçues.',
  );
}

class LivreurHome extends StatelessWidget {
  const LivreurHome({super.key});
  @override
  Widget build(BuildContext context) => const _DashboardScaffold(
    title: 'Espace livreur',
    icon: Icons.two_wheeler,
    message: 'Ici : les commandes à livrer et leur statut.',
  );
}

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});
  @override
  Widget build(BuildContext context) => const _DashboardScaffold(
    title: 'Administration',
    icon: Icons.admin_panel_settings_outlined,
    message: 'Ici : gestion des utilisateurs, vendeurs, livreurs et commandes.',
  );
}