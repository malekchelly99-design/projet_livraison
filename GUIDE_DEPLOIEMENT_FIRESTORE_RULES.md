# 🔐 Guide de Déploiement des Règles Firestore

## 📋 POURQUOI C'EST IMPORTANT

Les règles Firestore contrôlent **qui peut lire et écrire** dans votre base de données. Sans les bonnes règles, les clients ne peuvent pas voir les boutiques, même si elles existent.

**Symptôme si les règles sont incorrectes**:
- ❌ Les boutiques "disparaissent" dans l'interface client
- ❌ Erreurs `permission-denied` dans la console
- ❌ StreamBuilder ne reçoit aucune donnée

---

## 🚀 MÉTHODE 1: Firebase Console (RECOMMANDÉ)

### Étape 1: Ouvrir Firebase Console
1. Aller sur [https://console.firebase.google.com](https://console.firebase.google.com)
2. Se connecter avec votre compte Google
3. Sélectionner votre projet: **livraison-6f112**

### Étape 2: Accéder aux règles Firestore
1. Dans le menu latéral gauche, cliquer sur **"Firestore Database"**
2. Cliquer sur l'onglet **"Rules"** (Règles)
3. Vous verrez l'éditeur de règles avec vos règles actuelles

### Étape 3: Remplacer les règles
1. **SAUVEGARDER** vos règles actuelles (copier dans un fichier texte au cas où)
2. **SUPPRIMER** tout le contenu de l'éditeur
3. **COPIER** le contenu complet du fichier `firestore.rules`
4. **COLLER** dans l'éditeur Firebase

### Étape 4: Valider et publier
1. Cliquer sur le bouton **"Publish"** (Publier)
2. Attendre la confirmation (quelques secondes)
3. ✅ Un message de succès apparaît

### Étape 5: Vérifier le déploiement
1. Rafraîchir la page
2. Vérifier que les nouvelles règles sont affichées
3. Tester l'application

---

## 🚀 MÉTHODE 2: Firebase CLI (Pour utilisateurs avancés)

### Prérequis
```bash
# Installer Node.js (si pas encore installé)
# Télécharger depuis: https://nodejs.org

# Installer Firebase CLI
npm install -g firebase-tools

# Se connecter à Firebase
firebase login
```

### Étape 1: Initialiser Firebase (si pas déjà fait)
```bash
# Dans le répertoire du projet
firebase init firestore

# Sélectionner:
# - Use an existing project: livraison-6f112
# - Firestore Rules: firestore.rules
# - Firestore Indexes: firestore.indexes.json
```

### Étape 2: Déployer les règles
```bash
# Déployer uniquement les règles Firestore
firebase deploy --only firestore:rules

# Ou déployer tout (règles + indexes)
firebase deploy --only firestore
```

### Étape 3: Vérifier le déploiement
```bash
# Voir les déploiements récents
firebase deploy:history

# Tester les règles localement (optionnel)
firebase emulators:start --only firestore
```

---

## 🔍 VÉRIFICATION POST-DÉPLOIEMENT

### Test 1: Vérifier dans Firebase Console
1. Aller dans **Firestore Database** → **Rules**
2. Vérifier que la section `boutiques` contient:
   ```javascript
   match /boutiques/{boutiqueId} {
     allow read: if isAuthenticated();
     // ...
   }
   ```

### Test 2: Tester depuis l'application
```dart
// Ajouter temporairement dans lib/main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Dans main() après Firebase.initializeApp()
Future<void> testFirestoreRules() async {
  // 1. Vérifier l'authentification
  final user = FirebaseAuth.instance.currentUser;
  print('User: ${user?.uid}');
  
  // 2. Tester la lecture des boutiques
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('boutiques')
        .limit(1)
        .get();
    print('✅ Lecture autorisée - ${snapshot.docs.length} boutiques');
  } catch (e) {
    print('❌ Lecture refusée: $e');
    print('⚠️  Vérifiez les règles Firestore!');
  }
}

await testFirestoreRules();
```

### Test 3: Utiliser l'outil de diagnostic
```dart
import 'utils/boutique_diagnostics.dart';

final diagnostics = BoutiqueDiagnostics();
await diagnostics.printDiagnostic();
```

---

## 📝 RÈGLES IMPORTANTES

### Règle critique pour les boutiques:
```javascript
match /boutiques/{boutiqueId} {
  // ✅ LECTURE: Tous les utilisateurs authentifiés
  allow read: if isAuthenticated();
  
  // Création: Vendeur ou Admin
  allow create: if isAuthenticated() && 
                  (isOwner(boutiqueId) || isAdmin());
  
  // Mise à jour: Propriétaire ou Admin
  allow update: if isAuthenticated() && 
                  (isOwner(boutiqueId) || isAdmin());
  
  // Suppression: Admin uniquement
  allow delete: if isAdmin();
}
```

**Pourquoi `allow read: if isAuthenticated();` ?**
- Les clients doivent voir toutes les boutiques disponibles
- Les vendeurs doivent voir toutes les boutiques (pour comparaison)
- Les livreurs doivent voir les boutiques (pour livraisons)
- Seuls les admins peuvent supprimer

---

## 🛡️ SÉCURITÉ

### Ce que les règles protègent:

1. **Users** (Collection utilisateurs):
   - Lecture: Admin ou propriétaire uniquement
   - Écriture: Admin ou propriétaire uniquement

2. **Boutiques** (Collection boutiques):
   - Lecture: Tous les utilisateurs authentifiés ✅
   - Création: Vendeur (sa boutique) ou Admin
   - Modification: Propriétaire ou Admin
   - Suppression: Admin uniquement

3. **Products** (Collection produits):
   - Lecture: Tous les utilisateurs authentifiés ✅
   - Création: Vendeur ou Admin
   - Modification: Vendeur propriétaire ou Admin
   - Suppression: Vendeur propriétaire ou Admin

4. **Orders** (Collection commandes):
   - Lecture: Client, Vendeur concerné, Livreur assigné, Admin
   - Création: Client ou Admin
   - Modification: Toutes les parties concernées
   - Suppression: Admin uniquement

---

## ⚠️ PROBLÈMES COURANTS

### Problème 1: "permission-denied" dans la console
**Cause**: Les règles n'ont pas été déployées ou sont incorrectes

**Solution**:
1. Vérifier que les règles contiennent `allow read: if isAuthenticated();` pour `boutiques`
2. Redéployer les règles
3. Rafraîchir l'application

### Problème 2: Les règles ne se mettent pas à jour
**Cause**: Cache Firebase ou délai de propagation

**Solution**:
1. Attendre 30 secondes après déploiement
2. Rafraîchir la page Firebase Console
3. Se déconnecter et reconnecter dans l'app
4. Vider le cache du navigateur (si web)

### Problème 3: Erreur "Failed to get document"
**Cause**: L'utilisateur n'est pas authentifié

**Solution**:
```dart
// Vérifier l'authentification
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  print('❌ Utilisateur non authentifié');
  // Rediriger vers login
}
```

### Problème 4: Les boutiques sont visibles mais ne se mettent pas à jour
**Cause**: StreamBuilder déconnecté ou mauvaise implémentation

**Solution**:
- Vérifier que `.snapshots()` est utilisé (pas `.get()`)
- Vérifier qu'il n'y a pas de double StreamBuilder
- Voir `FIX_BOUTIQUES_DISPARITION.md`

---

## 🧪 TESTS DE VALIDATION

### Test complet des règles:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> validateFirestoreRules() async {
  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  
  print('=== TEST DES RÈGLES FIRESTORE ===\n');
  
  // Test 1: Authentification
  print('1. Authentification');
  final user = auth.currentUser;
  if (user == null) {
    print('   ❌ Non authentifié - connectez-vous d\'abord\n');
    return;
  }
  print('   ✅ Utilisateur: ${user.uid}\n');
  
  // Test 2: Lecture boutiques
  print('2. Lecture collection boutiques');
  try {
    final snapshot = await db.collection('boutiques').limit(1).get();
    print('   ✅ Lecture autorisée\n');
  } catch (e) {
    print('   ❌ Lecture refusée: $e\n');
  }
  
  // Test 3: Lecture products
  print('3. Lecture collection products');
  try {
    final snapshot = await db.collection('products').limit(1).get();
    print('   ✅ Lecture autorisée\n');
  } catch (e) {
    print('   ❌ Lecture refusée: $e\n');
  }
  
  // Test 4: Lecture users (devrait échouer si pas admin)
  print('4. Lecture collection users');
  try {
    final snapshot = await db.collection('users').limit(1).get();
    print('   ⚠️  Lecture autorisée (vous êtes probablement admin)\n');
  } catch (e) {
    print('   ✅ Lecture refusée (comportement normal pour client)\n');
  }
  
  print('=== FIN DES TESTS ===');
}

// Appeler dans main():
await validateFirestoreRules();
```

---

## 📞 SUPPORT

### Si les règles ne fonctionnent pas:

1. **Vérifier le contenu du fichier `firestore.rules`**
   ```bash
   cat firestore.rules
   ```

2. **Vérifier les règles déployées dans Firebase Console**
   - Aller dans Firestore Database → Rules
   - Comparer avec firestore.rules

3. **Consulter les logs Firebase**
   ```bash
   firebase deploy --only firestore:rules --debug
   ```

4. **Utiliser le diagnostic**
   ```dart
   BoutiqueDiagnostics().printDiagnostic();
   ```

---

## 📚 RÉFÉRENCES

- [Documentation Firestore Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase CLI Documentation](https://firebase.google.com/docs/cli)
- [Firestore Rules Playground](https://firebase.google.com/docs/rules/simulator)

---

**Date de création**: ${DateTime.now().toString().split('.')[0]}  
**Version**: 1.0  
**Status**: ✅ PRODUCTION-READY
