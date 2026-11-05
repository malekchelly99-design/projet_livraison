import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Utilitaire pour vérifier la configuration Firebase
class FirebaseChecker {
  /// Vérifie que Firebase est correctement configuré
  static Future<Map<String, dynamic>> checkConfiguration() async {
    final results = <String, dynamic>{};

    try {
      // 1. Vérifier que Firebase est initialisé
      final app = Firebase.app();
      results['firebase_initialized'] = true;
      results['project_id'] = app.options.projectId;

      // 2. Vérifier Firebase Auth
      try {
        final auth = FirebaseAuth.instance;
        results['auth_configured'] = true;
        results['current_user'] = auth.currentUser?.email ?? 'Non connecté';
      } catch (e) {
        results['auth_configured'] = false;
        results['auth_error'] = e.toString();
      }

      // 3. Vérifier Firestore
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore
            .collection('_test')
            .doc('connection_test')
            .set({'timestamp': FieldValue.serverTimestamp()}, SetOptions(merge: true));
        
        results['firestore_configured'] = true;
        results['firestore_write'] = true;

        // Nettoyer le test
        await firestore.collection('_test').doc('connection_test').delete();
      } catch (e) {
        results['firestore_configured'] = true;
        results['firestore_write'] = false;
        results['firestore_error'] = e.toString();
      }

      // 4. Vérifier les collections principales
      try {
        final firestore = FirebaseFirestore.instance;
        final collections = ['users', 'boutiques', 'products', 'orders', 'payments', 'categories', 'settings'];
        final collectionStatus = <String, bool>{};

        for (final collection in collections) {
          try {
            await firestore.collection(collection).limit(1).get();
            collectionStatus[collection] = true;
          } catch (e) {
            collectionStatus[collection] = false;
          }
        }

        results['collections_status'] = collectionStatus;
      } catch (e) {
        results['collections_check_error'] = e.toString();
      }

      results['overall_status'] = 'success';
    } catch (e) {
      results['overall_status'] = 'error';
      results['error'] = e.toString();
    }

    return results;
  }

  /// Affiche un rapport de configuration dans la console
  static Future<void> printConfigReport() async {
    print('\n========================================');
    print('   RAPPORT DE CONFIGURATION FIREBASE   ');
    print('========================================\n');

    final results = await checkConfiguration();

    if (results['overall_status'] == 'error') {
      print('❌ ERREUR : Firebase n\'est pas correctement configuré');
      print('   Erreur : ${results['error']}');
      print('\n⚠️  Consultez CONFIGURATION_FIREBASE.md pour les instructions\n');
      return;
    }

    print('✅ Firebase initialisé');
    print('   Project ID: ${results['project_id']}');
    print('');

    if (results['auth_configured'] == true) {
      print('✅ Firebase Authentication configuré');
      print('   Utilisateur actuel: ${results['current_user']}');
    } else {
      print('❌ Firebase Authentication : erreur');
      print('   ${results['auth_error']}');
    }
    print('');

    if (results['firestore_configured'] == true) {
      if (results['firestore_write'] == true) {
        print('✅ Firestore configuré et accessible en écriture');
      } else {
        print('⚠️  Firestore configuré mais accès en écriture refusé');
        print('   Vérifiez les règles de sécurité Firestore');
        print('   Erreur: ${results['firestore_error']}');
      }
    } else {
      print('❌ Firestore : erreur de configuration');
    }
    print('');

    if (results.containsKey('collections_status')) {
      print('📊 Collections Firestore:');
      final collectionStatus = results['collections_status'] as Map<String, bool>;
      collectionStatus.forEach((collection, accessible) {
        if (accessible) {
          print('   ✅ $collection');
        } else {
          print('   ⚠️  $collection (non accessible ou vide)');
        }
      });
    }

    print('\n========================================');
    print('Configuration terminée avec succès ! 🎉');
    print('========================================\n');
  }

  /// Vérifie si les clés Firebase sont toujours des placeholders
  static bool hasPlaceholderKeys(String projectId) {
    return projectId.contains('VOTRE_') || 
           projectId == 'VOTRE_PROJECT_ID' ||
           projectId.isEmpty;
  }
}
