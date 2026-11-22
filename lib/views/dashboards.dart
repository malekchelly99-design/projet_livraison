import 'package:flutter/material.dart';

import '../models/app_user.dart';
import 'admin/admin_dashboard_view.dart';
import 'client/client_dashboard_view.dart';
import 'livreur/livreur_dashboard_view.dart';
import 'vendeur/vendeur_dashboard_view.dart';

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
  Widget build(BuildContext context) => VendeurDashboardView(
        user: user,
        onLogout: onLogout,
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
  Widget build(BuildContext context) => AdminDashboardView(
        user: user,
        onLogout: onLogout,
      );
}
