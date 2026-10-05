import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'dashboards.dart';

/// Écoute le rôle de l'utilisateur dans Firestore (en temps réel)
/// et affiche le bon espace.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = AuthService();
  late final Stream<String?> _roleStream;
  Timer? _timeout;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _roleStream = _auth.roleStream(_auth.currentUser!.uid);
    // Si le profil n'apparaît pas au bout de 10 s, on affiche une erreur.
    _timeout = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: _roleStream,
      builder: (context, snap) {
        final role = snap.data;

        switch (role) {
          case 'admin':
            return const AdminHome();
          case 'vendeur':
            return const VendeurHome();
          case 'livreur':
            return const LivreurHome();
          case 'client':
            return const ClientHome();
        }

        // Rôle inconnu, erreur Firestore, ou profil toujours absent après 10 s
        if (role != null || snap.hasError || _timedOut) {
          return _errorScreen();
        }

        // Profil en cours de création : on patiente
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget _errorScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Erreur')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Profil introuvable.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _auth.logout,
              child: const Text('Se déconnecter'),
            ),
          ],
        ),
      ),
    );
  }
}