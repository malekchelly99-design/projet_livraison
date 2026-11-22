import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Utilitaire de diagnostic pour identifier les problèmes de boutiques
class BoutiqueDiagnostics {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  BoutiqueDiagnostics({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Exécute un diagnostic complet et retourne un rapport détaillé
  Future<String> runFullDiagnostic() async {
    final buffer = StringBuffer();
    buffer.writeln('=== DIAGNOSTIC BOUTIQUES ===');
    buffer.writeln('Date: ${DateTime.now()}');
    buffer.writeln('');

    // 1. Vérifier l'authentification
    buffer.writeln('1. AUTHENTIFICATION');
    final user = _auth.currentUser;
    if (user == null) {
      buffer.writeln('   ❌ Utilisateur non authentifié');
      return buffer.toString();
    } else {
      buffer.writeln('   ✅ Utilisateur: ${user.uid}');
      buffer.writeln('   ✅ Email: ${user.email}');
    }
    buffer.writeln('');

    // 2. Compter les boutiques
    buffer.writeln('2. COLLECTION BOUTIQUES');
    try {
      final boutiquesSnapshot = await _db.collection('boutiques').get();
      buffer.writeln('   ✅ Connexion réussie');
      buffer.writeln('   📊 Nombre total: ${boutiquesSnapshot.docs.length}');
      
      if (boutiquesSnapshot.docs.isEmpty) {
        buffer.writeln('   ⚠️  Aucune boutique trouvée dans la collection');
      } else {
        buffer.writeln('   📋 Liste des boutiques:');
        for (final doc in boutiquesSnapshot.docs) {
          final data = doc.data();
          final nom = data['nomBoutique'] ?? data['shopName'] ?? 'Sans nom';
          final disponible = data['disponible'] ?? data['isOpen'] ?? true;
          final vendeurId = data['vendeurId'] ?? doc.id;
          buffer.writeln('      • $nom (ID: ${doc.id}, Vendeur: $vendeurId, Disponible: $disponible)');
        }
      }
    } catch (e) {
      buffer.writeln('   ❌ Erreur: $e');
      buffer.writeln('   ⚠️  Possible problème de règles Firestore');
    }
    buffer.writeln('');

    // 3. Compter les vendeurs
    buffer.writeln('3. VENDEURS ENREGISTRÉS');
    try {
      final vendeursSnapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'vendeur')
          .get();
      buffer.writeln('   ✅ Connexion réussie');
      buffer.writeln('   📊 Nombre total: ${vendeursSnapshot.docs.length}');
      
      if (vendeursSnapshot.docs.isEmpty) {
        buffer.writeln('   ⚠️  Aucun vendeur enregistré');
      } else {
        buffer.writeln('   📋 Liste des vendeurs:');
        for (final doc in vendeursSnapshot.docs) {
          final data = doc.data();
          final nom = data['name'] ?? 'Sans nom';
          final email = data['email'] ?? 'Sans email';
          final profile = data['profile'] as Map<String, dynamic>? ?? {};
          final shopName = profile['shopName'] ?? 'Pas de boutique définie';
          buffer.writeln('      • $nom ($email) - Boutique: $shopName');
        }
      }
    } catch (e) {
      buffer.writeln('   ❌ Erreur: $e');
    }
    buffer.writeln('');

    // 4. Vérifier la cohérence vendeurs <-> boutiques
    buffer.writeln('4. COHÉRENCE VENDEURS <-> BOUTIQUES');
    try {
      final vendeursSnapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'vendeur')
          .get();
      
      int vendeursAvecBoutique = 0;
      int vendeursSansBoutique = 0;
      
      for (final vendeurDoc in vendeursSnapshot.docs) {
        final boutiqueDoc = await _db.collection('boutiques').doc(vendeurDoc.id).get();
        if (boutiqueDoc.exists) {
          vendeursAvecBoutique++;
        } else {
          vendeursSansBoutique++;
          final nom = vendeurDoc.data()['name'] ?? 'Sans nom';
          buffer.writeln('   ⚠️  Vendeur sans boutique: $nom (ID: ${vendeurDoc.id})');
        }
      }
      
      buffer.writeln('   ✅ Vendeurs avec boutique: $vendeursAvecBoutique');
      if (vendeursSansBoutique > 0) {
        buffer.writeln('   ⚠️  Vendeurs SANS boutique: $vendeursSansBoutique');
        buffer.writeln('   💡 Suggestion: Exécutez la migration automatique');
      } else {
        buffer.writeln('   ✅ Tous les vendeurs ont une boutique');
      }
    } catch (e) {
      buffer.writeln('   ❌ Erreur: $e');
    }
    buffer.writeln('');

    // 5. Vérifier les règles Firestore (test de lecture)
    buffer.writeln('5. TEST DES RÈGLES FIRESTORE');
    try {
      // Test de lecture simple
      await _db.collection('boutiques').limit(1).get();
      buffer.writeln('   ✅ Lecture autorisée sur collection boutiques');
    } catch (e) {
      buffer.writeln('   ❌ Lecture REFUSÉE sur collection boutiques');
      buffer.writeln('   ⚠️  Erreur: $e');
      buffer.writeln('   💡 Vérifiez les règles Firestore - les clients doivent pouvoir lire les boutiques');
    }
    buffer.writeln('');

    // 6. Recommandations
    buffer.writeln('6. RECOMMANDATIONS');
    try {
      final boutiquesCount = (await _db.collection('boutiques').get()).docs.length;
      final vendeursCount = (await _db.collection('users').where('role', isEqualTo: 'vendeur').get()).docs.length;
      
      if (boutiquesCount == 0 && vendeursCount == 0) {
        buffer.writeln('   💡 Aucun vendeur enregistré. Inscrivez un vendeur pour créer des boutiques.');
      } else if (boutiquesCount == 0 && vendeursCount > 0) {
        buffer.writeln('   ⚠️  Des vendeurs existent mais aucune boutique n\'a été créée.');
        buffer.writeln('   💡 Exécutez: BoutiqueSyncService().migrateMissingBoutiques()');
      } else if (boutiquesCount < vendeursCount) {
        buffer.writeln('   ⚠️  Certains vendeurs n\'ont pas de boutique associée.');
        buffer.writeln('   💡 Exécutez: BoutiqueSyncService().migrateMissingBoutiques()');
      } else {
        buffer.writeln('   ✅ Tout semble correct!');
      }
    } catch (e) {
      buffer.writeln('   ❌ Impossible de générer les recommandations: $e');
    }
    buffer.writeln('');

    buffer.writeln('=== FIN DU DIAGNOSTIC ===');
    return buffer.toString();
  }

  /// Test de streaming en temps réel pour vérifier la persistance
  Stream<String> watchBoutiquesStatus() {
    return _db.collection('boutiques').snapshots().map((snapshot) {
      final count = snapshot.docs.length;
      final timestamp = DateTime.now().toIso8601String();
      return '[$timestamp] Boutiques: $count | Documents: ${snapshot.docs.map((d) => d.data()['nomBoutique'] ?? d.data()['shopName'] ?? d.id).join(', ')}';
    });
  }

  /// Teste la persistance en temps réel (écoute pendant 10 secondes)
  Future<String> testRealTimePersistence() async {
    final buffer = StringBuffer();
    buffer.writeln('=== TEST DE PERSISTANCE EN TEMPS RÉEL ===');
    buffer.writeln('Écoute pendant 10 secondes...');
    buffer.writeln('');

    int updateCount = 0;
    final subscription = _db.collection('boutiques').snapshots().listen((snapshot) {
      updateCount++;
      buffer.writeln('[Update #$updateCount] ${snapshot.docs.length} boutiques détectées');
      for (final doc in snapshot.docs) {
        final nom = doc.data()['nomBoutique'] ?? doc.data()['shopName'] ?? 'Sans nom';
        buffer.writeln('   • $nom (ID: ${doc.id})');
      }
    });

    await Future.delayed(const Duration(seconds: 10));
    await subscription.cancel();

    buffer.writeln('');
    buffer.writeln('Test terminé. Nombre total de mises à jour: $updateCount');
    if (updateCount == 0) {
      buffer.writeln('⚠️  Aucune mise à jour reçue - possible problème de connexion Firestore');
    } else if (updateCount == 1) {
      buffer.writeln('✅ Une seule mise à jour - données stables (bon signe)');
    } else {
      buffer.writeln('⚠️  Plusieurs mises à jour - vérifiez si les données changent de manière inattendue');
    }
    buffer.writeln('=== FIN DU TEST ===');

    return buffer.toString();
  }

  /// Affiche le diagnostic dans la console (debug mode uniquement)
  Future<void> printDiagnostic() async {
    if (kDebugMode) {
      final report = await runFullDiagnostic();
      debugPrint(report);
    }
  }

  /// Affiche le test de persistance dans la console (debug mode uniquement)
  Future<void> printPersistenceTest() async {
    if (kDebugMode) {
      final report = await testRealTimePersistence();
      debugPrint(report);
    }
  }
}
