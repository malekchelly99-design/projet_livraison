# 🧪 Plan de Test: Validation du Fix Boutiques

## 📋 OBJECTIF

Valider que les boutiques restent affichées de manière permanente et stable dans l'interface CLIENT après la correction.

---

## ✅ PRÉ-REQUIS

Avant de commencer les tests:

- [ ] Règles Firestore déployées (voir `GUIDE_DEPLOIEMENT_FIRESTORE_RULES.md`)
- [ ] Application compilée: `flutter run`
- [ ] Au moins 1 compte VENDEUR existant
- [ ] Au moins 1 boutique dans Firestore
- [ ] Firebase projet: `livraison-6f112` configuré

---

## 🧪 SCÉNARIOS DE TEST

### TEST 1: Affichage Initial des Boutiques ✅

**Objectif**: Vérifier que les boutiques s'affichent lors de la connexion

**Prérequis**: 
- Au moins 1 vendeur inscrit
- Collection `boutiques` contient au moins 1 document

**Étapes**:
1. Lancer l'application
2. Se connecter avec un compte CLIENT
3. Naviguer vers l'onglet "Boutiques"

**Résultat attendu**:
- ✅ Les boutiques s'affichent dans une liste
- ✅ Chaque boutique affiche: nom, catégorie, adresse, statut (Ouvert/Fermé)
- ✅ Pas de message "Aucune boutique trouvée"
- ✅ Pas de spinner de chargement infini

**En cas d'échec**:
- Vérifier nombre de boutiques: `await FirebaseFirestore.instance.collection('boutiques').get().then((s) => s.docs.length)`
- Exécuter diagnostic: `BoutiqueDiagnostics().printDiagnostic()`

---

### TEST 2: Persistance après Navigation ✅

**Objectif**: Vérifier que les boutiques restent affichées après navigation

**Prérequis**: TEST 1 réussi

**Étapes**:
1. Afficher les boutiques (onglet "Boutiques")
2. Noter mentalement le nombre de boutiques affichées
3. Naviguer vers l'onglet "Catalogue"
4. Attendre 2 secondes
5. Revenir à l'onglet "Boutiques"

**Résultat attendu**:
- ✅ Les boutiques s'affichent immédiatement (pas de rechargement visible)
- ✅ Le même nombre de boutiques est affiché
- ✅ Pas de disparition temporaire
- ✅ Pas de flicker/clignotement

**En cas d'échec**:
- Vérifier que StreamBuilder utilise `.snapshots()` et non `.get()`
- Vérifier qu'il n'y a pas de double StreamBuilder
- Consulter `FIX_BOUTIQUES_DISPARITION.md`

---

### TEST 3: Persistance après Refresh ✅

**Objectif**: Vérifier la persistance après rafraîchissement de l'application

**Prérequis**: TEST 1 réussi

**Étapes**:
1. Afficher les boutiques
2. Appuyer sur F5 (web) ou tirer pour rafraîchir (mobile)
3. Attendre le rechargement complet de l'application
4. Se reconnecter si nécessaire
5. Naviguer vers "Boutiques"

**Résultat attendu**:
- ✅ Les boutiques réapparaissent après reconnexion
- ✅ Aucune perte de données
- ✅ Affichage stable

**En cas d'échec**:
- Vérifier l'authentification après refresh
- Vérifier que les données Firestore existent toujours

---

### TEST 4: Persistance après Déconnexion/Reconnexion ✅

**Objectif**: Vérifier que les boutiques s'affichent après un cycle complet déco/reco

**Prérequis**: TEST 1 réussi

**Étapes**:
1. Afficher les boutiques (noter le nombre)
2. Se déconnecter (bouton logout)
3. Attendre 2 secondes
4. Se reconnecter avec le même compte CLIENT
5. Naviguer vers "Boutiques"

**Résultat attendu**:
- ✅ Les boutiques s'affichent normalement
- ✅ Même nombre de boutiques qu'avant
- ✅ Pas de différence de comportement

**En cas d'échec**:
- Vérifier les règles Firestore
- Vérifier l'authentification

---

### TEST 5: Ajout d'une Nouvelle Boutique ✅

**Objectif**: Vérifier que les nouvelles boutiques apparaissent automatiquement

**Prérequis**: 
- Possibilité de créer un nouveau compte VENDEUR
- TEST 1 réussi

**Étapes**:
1. Connecté comme CLIENT, afficher les boutiques
2. Noter le nombre de boutiques (exemple: 3)
3. Ouvrir un nouvel onglet/fenêtre
4. S'inscrire comme nouveau VENDEUR
5. Remplir toutes les informations de boutique
6. Valider l'inscription
7. Retourner à la fenêtre CLIENT
8. Attendre 3-5 secondes (temps réel Firestore)

**Résultat attendu**:
- ✅ La nouvelle boutique apparaît automatiquement dans la liste
- ✅ Nombre de boutiques: nombre initial + 1
- ✅ Pas besoin de rafraîchir manuellement
- ✅ StreamBuilder met à jour en temps réel

**En cas d'échec**:
- Vérifier que BoutiqueSyncService crée bien la boutique à l'inscription
- Vérifier dans Firebase Console que la boutique existe
- Vérifier les règles Firestore (lecture)

---

### TEST 6: Recherche de Boutiques ✅

**Objectif**: Vérifier que la recherche fonctionne sans affecter la persistance

**Prérequis**: TEST 1 réussi, au moins 2 boutiques

**Étapes**:
1. Afficher les boutiques
2. Taper "Pizza" dans la barre de recherche
3. Observer le filtrage
4. Effacer la recherche (clic sur X)
5. Observer le retour à la liste complète

**Résultat attendu**:
- ✅ Seules les boutiques correspondantes s'affichent lors de la recherche
- ✅ Toutes les boutiques réapparaissent après effacement
- ✅ Pas de disparition permanente
- ✅ Filtrage instantané

**En cas d'échec**:
- Vérifier la logique de filtrage dans `_buildBoutiquesList`

---

### TEST 7: Gestion des Erreurs Firestore ✅

**Objectif**: Vérifier que les erreurs sont gérées correctement

**Prérequis**: TEST 1 réussi

**Étapes**:
1. Afficher les boutiques normalement
2. Couper la connexion internet (mode avion)
3. Naviguer vers un autre onglet puis revenir à "Boutiques"
4. Observer le comportement
5. Rétablir la connexion internet
6. Observer la récupération

**Résultat attendu**:
- ✅ Avec cache Firestore: boutiques restent affichées même hors ligne
- ✅ Sans cache: message d'erreur approprié (pas de crash)
- ✅ Après reconnexion: boutiques se rechargent automatiquement
- ✅ Pas de perte de données

**En cas d'échec**:
- Vérifier la gestion d'erreur dans le StreamBuilder
- Activer la persistance hors ligne Firestore

---

### TEST 8: Performance et Temps de Chargement ✅

**Objectif**: Vérifier que l'affichage est rapide et fluide

**Prérequis**: TEST 1 réussi

**Étapes**:
1. Se déconnecter complètement
2. Fermer l'application
3. Relancer l'application
4. Se connecter comme CLIENT
5. Mesurer le temps jusqu'à l'affichage des boutiques

**Résultat attendu**:
- ✅ Affichage des boutiques < 2 secondes (connexion normale)
- ✅ Pas de lag ou freeze de l'UI
- ✅ Animations fluides

**En cas d'échec**:
- Optimiser les requêtes Firestore
- Vérifier les index Firestore

---

### TEST 9: Boutiques Multiples (Scalabilité) ✅

**Objectif**: Vérifier le comportement avec beaucoup de boutiques

**Prérequis**: Créer 10+ boutiques de test

**Étapes**:
1. Créer 10-15 comptes VENDEUR (ou utiliser script)
2. Se connecter comme CLIENT
3. Afficher les boutiques
4. Faire défiler la liste
5. Naviguer et revenir

**Résultat attendu**:
- ✅ Toutes les boutiques s'affichent
- ✅ Scroll fluide
- ✅ Pas de perte de boutiques lors du scroll
- ✅ Persistance maintenue

**En cas d'échec**:
- Implémenter pagination si > 50 boutiques
- Optimiser le rendu ListView

---

### TEST 10: Compatibilité Multi-Plateforme ✅

**Objectif**: Vérifier le fonctionnement sur différentes plateformes

**Prérequis**: TEST 1 réussi

**Étapes**:
1. Tester sur Web (Chrome)
2. Tester sur Android (si disponible)
3. Tester sur iOS (si disponible)

**Résultat attendu**:
- ✅ Comportement identique sur toutes les plateformes
- ✅ Persistance fonctionne partout
- ✅ Pas de bug spécifique à une plateforme

**En cas d'échec**:
- Vérifier la configuration Firebase par plateforme
- Consulter les logs spécifiques à la plateforme

---

## 🔍 DIAGNOSTIC AUTOMATISÉ

### Test de Santé Automatique

Ajouter temporairement dans `lib/main.dart`:

```dart
import 'utils/boutique_diagnostics.dart';

// Après Firebase.initializeApp() et avant runApp()
Future<void> runHealthCheck() async {
  print('\n═══════════════════════════════════════');
  print('    HEALTH CHECK: SYSTÈME BOUTIQUES    ');
  print('═══════════════════════════════════════\n');
  
  final diagnostics = BoutiqueDiagnostics();
  final report = await diagnostics.runFullDiagnostic();
  print(report);
  
  print('\n═══════════════════════════════════════');
  print('    TEST DE PERSISTANCE (10 secondes)  ');
  print('═══════════════════════════════════════\n');
  
  final persistenceReport = await diagnostics.testRealTimePersistence();
  print(persistenceReport);
  
  print('\n✅ Health Check terminé!');
}

await runHealthCheck();
```

**Exécuter**:
```bash
flutter run --verbose
```

**Analyser les résultats**:
- Nombre de boutiques détecté
- État des règles Firestore
- Mises à jour en temps réel

---

## 📊 TABLEAU DE VALIDATION

| Test | Description | Statut | Notes |
|------|-------------|--------|-------|
| TEST 1 | Affichage initial | ⬜ | |
| TEST 2 | Persistance navigation | ⬜ | |
| TEST 3 | Persistance refresh | ⬜ | |
| TEST 4 | Déco/Reco | ⬜ | |
| TEST 5 | Nouvelle boutique | ⬜ | |
| TEST 6 | Recherche | ⬜ | |
| TEST 7 | Gestion erreurs | ⬜ | |
| TEST 8 | Performance | ⬜ | |
| TEST 9 | Scalabilité | ⬜ | |
| TEST 10 | Multi-plateforme | ⬜ | |

Légende: ⬜ Non testé | ✅ Réussi | ❌ Échoué | ⚠️ Partiel

---

## 🐛 RAPPORT DE BUG

Si un test échoue, remplir:

**Test échoué**: [Numéro du test]

**Comportement observé**:
[Décrire ce qui se passe]

**Comportement attendu**:
[Décrire ce qui devrait se passer]

**Étapes pour reproduire**:
1. 
2. 
3. 

**Logs/Erreurs**:
```
[Copier les erreurs de la console]
```

**Diagnostic exécuté**:
```dart
BoutiqueDiagnostics().printDiagnostic()
```

**Résultat du diagnostic**:
```
[Copier le résultat complet]
```

---

## ✅ CRITÈRES DE SUCCÈS GLOBAL

Le fix est considéré comme **validé** si:

- ✅ Au moins 8/10 tests réussis
- ✅ TEST 1, 2, 3, 4 OBLIGATOIRES réussis
- ✅ Aucun crash de l'application
- ✅ Pas de régression sur d'autres fonctionnalités
- ✅ Performance acceptable (< 3 secondes affichage)

---

## 📞 SUPPORT

En cas de problème:

1. **Consulter**: `FIX_BOUTIQUES_DISPARITION.md`
2. **Exécuter**: `BoutiqueDiagnostics().printDiagnostic()`
3. **Vérifier**: Règles Firestore déployées
4. **Référence rapide**: `QUICK_FIX_BOUTIQUES.txt`

---

**Date de création**: ${DateTime.now().toString().split('.')[0]}  
**Version**: 1.0  
**Status**: Prêt pour validation
