import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'services/database_init_service.dart';
// Décommentez la ligne suivante pour utiliser FirebaseChecker
// import 'utils/firebase_checker.dart';
import 'views/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialisation de Firebase avec la nouvelle configuration
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    // Activer la persistance locale Firestore illimitée pour éviter que les données ne disparaissent
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Initialisation des tables et catégories requises dans Firestore
    await DatabaseInitService().initializeTables().catchError((e) {
      print('⚠️  Erreur lors de l\'initialisation de la base de données: $e');
    });

    runApp(const DeliveryApp());
  } catch (e) {
    print('❌ ERREUR DE CONFIGURATION FIREBASE');
    print('   $e');
    print('\n📖 Consultez le fichier CONFIGURATION_FIREBASE.md pour les instructions détaillées\n');
    
    // Afficher une interface d'erreur
    runApp(FirebaseConfigErrorApp(error: e.toString()));
  }
}

/// Application affichée en cas d'erreur de configuration Firebase
class FirebaseConfigErrorApp extends StatelessWidget {
  final String? error;
  const FirebaseConfigErrorApp({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Erreur de Configuration',
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Erreur de Configuration Firebase',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  error != null
                      ? 'Détail de l\'erreur :\n$error\n\n'
                      : 'Firebase n\'est pas correctement configuré.\n\n',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade700,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Consultez le fichier CONFIGURATION_FIREBASE.md à la racine du projet.\n\n'
                  'Note : Si vous lancez l\'application sur Windows Desktop, '
                  'lancez-la plutôt sur Chrome (Web) ou Android :\n'
                  'flutter run -d chrome\n'
                  'ou sur un émulateur Android.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // L'utilisateur devra redémarrer l'app après configuration
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Redémarrer après configuration'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Livraison Rapide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
