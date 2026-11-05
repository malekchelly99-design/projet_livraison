# 🧪 Guide de Test - Système d'Authentification Corrigé

## 🚀 Lancement de l'Application

```bash
flutter run -d chrome
```

---

## 📋 Tests à Effectuer

### Test 1 : Inscription Nouveau Compte ✅

**Objectif :** Vérifier qu'un nouvel utilisateur peut s'inscrire normalement.

**Étapes :**
1. Cliquez sur "S'inscrire" depuis la page de connexion
2. Sélectionnez le rôle "Client"
3. Remplissez le formulaire :
   - Nom : `Test User`
   - Téléphone : `+216 12 345 678`
   - Email : `newuser@test.com` (un email jamais utilisé)
   - Mot de passe : `password123`
   - Confirmer : `password123`
4. Cliquez sur "S'inscrire"

**Résultat attendu :**
- ✅ Inscription réussie
- ✅ Redirection automatique vers le dashboard client
- ✅ Pas d'erreur affichée

---

### Test 2 : Inscription avec Email Existant (CAS CLÉ) ✅

**Objectif :** Vérifier la gestion des emails déjà dans Firebase Authentication.

**Étapes :**
1. Depuis la page d'inscription
2. Sélectionnez "Client"
3. Entrez un email **déjà utilisé** (ex: l'email que vous avez créé au Test 1)
4. Remplissez le reste du formulaire
5. Cliquez sur "S'inscrire"

**Résultat attendu :**
- ✅ Dialog s'affiche avec le titre "Compte déjà existant"
- ✅ Message explique que le compte existe avec cet email
- ✅ Champ mot de passe présent dans le dialog
- ✅ Deux boutons : "Annuler" et "Se connecter"

**Test du dialog :**
1. Entrez le mauvais mot de passe
   - ✅ Message d'erreur sous le champ "Email ou mot de passe incorrect"
2. Entrez le bon mot de passe
   - ✅ Connexion automatique
   - ✅ Dialog se ferme
   - ✅ Redirection vers le dashboard
   - ✅ Si le profil Firestore était manquant → restauré automatiquement

---

### Test 3 : Connexion Normale ✅

**Objectif :** Vérifier que la connexion standard fonctionne.

**Étapes :**
1. Page de connexion
2. Entrez email et mot de passe d'un compte existant
3. Cliquez sur "Se connecter"

**Résultat attendu :**
- ✅ Connexion immédiate
- ✅ Redirection vers le dashboard approprié selon le rôle
- ✅ Pas de délai anormal

---

### Test 4 : Connexion avec Profil Firestore Manquant ✅

**Objectif :** Simuler le cas de migration (Auth existe, Firestore supprimé).

**Préparation :**
1. Ouvrez Firebase Console → Firestore Database
2. Allez dans la collection `users`
3. Supprimez manuellement UN document utilisateur (pas admin!)
4. Notez l'email de ce compte

**Test :**
1. Tentez de vous connecter avec cet email et son mot de passe
2. Cliquez sur "Se connecter"

**Résultat attendu :**
- ✅ Connexion réussie (Firebase Auth fonctionne)
- ✅ Écran de chargement bref
- ✅ Profil automatiquement restauré dans Firestore
- ✅ Redirection vers dashboard client (rôle par défaut)
- ✅ Vérifiez dans Firestore : le document a été recréé

---

### Test 5 : Déconnexion / Reconnexion ✅

**Objectif :** Vérifier le cycle complet.

**Étapes :**
1. Depuis le dashboard, déconnectez-vous
2. Reconnectez-vous immédiatement
3. Vérifiez que tout fonctionne

**Résultat attendu :**
- ✅ Déconnexion instantanée → page de login
- ✅ Reconnexion fonctionne normalement
- ✅ Dashboard approprié s'affiche

---

### Test 6 : Inscription Vendeur ✅

**Objectif :** Tester avec un rôle différent.

**Étapes :**
1. Page d'inscription
2. Sélectionnez "Vendeur"
3. Remplissez tous les champs requis :
   - Nom responsable
   - Téléphone
   - Nom boutique
   - Catégorie
   - Adresse boutique
   - Ville
   - Email (nouveau)
   - Mot de passe
4. Cliquez sur "S'inscrire"

**Résultat attendu :**
- ✅ Compte Auth créé
- ✅ Document `users` créé avec role=vendeur
- ✅ Document `boutiques` créé automatiquement
- ✅ Redirection vers dashboard vendeur

**Vérification Firebase :**
- Collection `users` → nouveau doc avec `role: "vendeur"`
- Collection `boutiques` → nouveau doc avec infos boutique

---

### Test 7 : Mot de Passe Oublié ✅

**Objectif :** Vérifier que la réinitialisation fonctionne.

**Étapes :**
1. Page de connexion
2. Entrez un email valide
3. Cliquez sur "Mot de passe oublié ?"

**Résultat attendu :**
- ✅ Message "Email de réinitialisation envoyé"
- ✅ Email reçu dans la boîte (vérifiez spam)
- ✅ Lien de réinitialisation fonctionnel

---

## 🔍 Vérifications Firebase Console

### Dans Authentication
1. Ouvrez Firebase Console → Authentication → Users
2. Vérifiez que chaque compte test apparaît
3. Notez les UID

### Dans Firestore
1. Ouvrez Firebase Console → Firestore Database
2. Collection `users` :
   - Vérifiez que chaque UID Auth a un document correspondant
   - Vérifiez les champs : name, email, phone, role, profile
3. Collection `boutiques` (si vendeur) :
   - Vérifiez qu'un doc existe pour chaque vendeur
   - ID du doc = UID du vendeur

### Règle d'Or ✅
**1 compte Auth = 1 document Firestore users**  
**ID du document = UID Auth**

---

## 🐛 Tests de Cas Limites

### Cas 1 : Email Invalide
**Test :** Essayez de vous inscrire avec `invalidemail`  
**Attendu :** ✅ Erreur de validation inline "L'adresse email n'est pas valide."

### Cas 2 : Mot de Passe Faible
**Test :** Essayez `123` comme mot de passe  
**Attendu :** ✅ Erreur "Au moins 8 caractères requis"

### Cas 3 : Mots de Passe Non Correspondants
**Test :** `password123` vs `password456`  
**Attendu :** ✅ Erreur "Les mots de passe ne correspondent pas"

### Cas 4 : Connexion avec Mauvais Mot de Passe
**Test :** Email valide + mauvais password  
**Attendu :** ✅ "Email ou mot de passe incorrect"

### Cas 5 : Champs Obligatoires Vides
**Test :** Laissez des champs vides  
**Attendu :** ✅ Messages de validation appropriés

---

## 📊 Checklist de Validation Complète

### Inscription
- [ ] Nouveau compte client créé avec succès
- [ ] Nouveau compte vendeur créé avec succès
- [ ] Nouveau compte livreur créé avec succès
- [ ] Email déjà utilisé → Dialog affiché
- [ ] Connexion depuis dialog fonctionne
- [ ] Validation des champs fonctionne

### Connexion
- [ ] Connexion normale réussie
- [ ] Connexion avec profil manquant restauré
- [ ] Mauvais mot de passe → erreur claire
- [ ] Email inexistant → erreur claire
- [ ] Mot de passe oublié fonctionne

### Navigation
- [ ] Dashboard client s'affiche (role=client)
- [ ] Dashboard vendeur s'affiche (role=vendeur)
- [ ] Dashboard livreur s'affiche (role=livreur)
- [ ] Dashboard admin s'affiche (role=admin)
- [ ] Déconnexion fonctionne

### Firebase Sync
- [ ] Chaque compte Auth a un doc Firestore
- [ ] ID document = UID Auth
- [ ] Pas de doublons
- [ ] Profils manquants restaurés automatiquement

### UX
- [ ] Messages d'erreur clairs
- [ ] Pas de crash
- [ ] Loading states visibles
- [ ] Boutons disabled pendant chargement
- [ ] Navigation fluide

---

## 🎯 Scénario de Test Complet (10 min)

### Minute 1-2 : Nouvelle Inscription
```
1. S'inscrire comme Client avec newuser1@test.com ✅
2. Vérifier redirection dashboard ✅
3. Se déconnecter ✅
```

### Minute 3-4 : Test Email Existant
```
1. Retenter inscription avec newuser1@test.com ✅
2. Dialog "Compte existant" s'affiche ✅
3. Entrer mauvais mot de passe → erreur ✅
4. Entrer bon mot de passe → connexion ✅
5. Vérifier dashboard ✅
6. Se déconnecter ✅
```

### Minute 5-6 : Simuler Migration
```
1. Firebase Console → Firestore → users ✅
2. Supprimer le doc de newuser1@test.com ✅
3. Se reconnecter avec newuser1@test.com ✅
4. Vérifier restauration automatique ✅
5. Dashboard s'affiche ✅
6. Firestore : doc recréé ✅
```

### Minute 7-8 : Inscription Vendeur
```
1. S'inscrire comme Vendeur ✅
2. Remplir tous les champs boutique ✅
3. Vérifier dashboard vendeur ✅
4. Firestore : boutiques collection créée ✅
```

### Minute 9-10 : Validation Finale
```
1. Tester mot de passe oublié ✅
2. Tester validation des champs ✅
3. Vérifier Firebase Console complète ✅
4. Confirmer : Aucun crash, aucune erreur ✅
```

---

## 🛠️ Outils de Debug

### Console Browser (F12)
```javascript
// Voir les erreurs
console.log()

// Vérifier l'utilisateur actuel
firebase.auth().currentUser
```

### Firebase Console
- **Authentication** → Liste des comptes
- **Firestore** → Collections users/boutiques
- **Règles** → Vérifier permissions

### Logs Flutter
```bash
flutter run -d chrome --verbose
```

---

## 📞 Si un Test Échoue

### 1. Email Already in Use ne déclenche pas le dialog
**Cause :** RegisterController pas à jour  
**Solution :** Vérifier `submitWithResult()` et `RegisterResult`

### 2. Profil pas restauré après connexion
**Cause :** AuthController pas mis à jour  
**Solution :** Vérifier `createOrRestoreProfile()` est appelé

### 3. Crash au chargement du dashboard
**Cause :** Stream reçoit null  
**Solution :** Vérifier HomeController timeout et restauration

### 4. Permission Denied Firestore
**Cause :** Règles de sécurité strictes  
**Solution :** Mettre à jour les règles (voir AUTHENTICATION_FIX_REPORT.md)

---

## ✅ Validation Finale

Une fois tous les tests passés :

```bash
✅ Nouvelle inscription fonctionne
✅ Email existant géré avec dialog
✅ Connexion depuis dialog fonctionne
✅ Profil manquant restauré automatiquement
✅ Tous les rôles fonctionnent
✅ Firebase Console cohérent
✅ Aucun crash
✅ UX fluide et claire
```

**→ Système prêt pour production ! 🚀**

---

**Temps de test estimé :** 10-15 minutes  
**Tests critiques :** 2, 4 (email existant, profil manquant)  
**Prérequis :** Firebase configuré, règles Firestore publiées
