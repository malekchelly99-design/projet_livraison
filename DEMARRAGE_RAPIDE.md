# 🚀 Démarrage Rapide - Nouvelle Base Firebase

## ⚡ Configuration en 3 Étapes

### Étape 1️⃣ : Lancer l'Assistant de Configuration

**Option A - Avec PowerShell (Recommandé):**
```powershell
.\configure_firebase.ps1
```

**Option B - Manuellement:**
```bash
# Installer FlutterFire CLI
dart pub global activate flutterfire_cli

# Configurer Firebase automatiquement
flutterfire configure
```

### Étape 2️⃣ : Activer les Services Firebase

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet
3. **Activez Authentication:**
   - Menu → Authentication → Get Started
   - Activez "Email/Password"
4. **Créez Firestore:**
   - Menu → Firestore Database → Create Database
   - Choisissez "Production mode"
   - Sélectionnez une région

### Étape 3️⃣ : Configurer les Règles de Sécurité

Dans Firestore → Règles, copiez-collez ceci :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    function isAdmin() {
      return isSignedIn() && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    match /users/{userId} {
      allow read: if isOwner(userId) || isAdmin();
      allow create: if isSignedIn();
      allow update: if isOwner(userId) || isAdmin();
      allow delete: if isAdmin();
    }
    
    match /boutiques/{boutiqueId} {
      allow read: if true;
      allow create: if isSignedIn();
      allow update: if isOwner(boutiqueId) || isAdmin();
      allow delete: if isAdmin();
    }
    
    match /products/{productId} {
      allow read: if true;
      allow create, update, delete: if isSignedIn();
    }
    
    match /categories/{categoryId} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    match /orders/{orderId} {
      allow read, create, update: if isSignedIn();
      allow delete: if isAdmin();
    }
    
    match /settings/{settingId} {
      allow read: if true;
      allow write: if isAdmin();
    }
  }
}
```

Cliquez sur **Publier**.

---

## ✅ Tester la Configuration

```bash
# Nettoyer le projet
flutter clean
flutter pub get

# Lancer l'application
flutter run -d chrome
```

---

## 🎯 Vérifier la Configuration

Pour voir un rapport détaillé de votre configuration, éditez `lib/main.dart` et décommentez cette ligne :

```dart
await FirebaseChecker.printConfigReport();
```

Puis relancez l'application.

---

## 📋 Ce qui a été modifié

### ✅ Fichiers nettoyés :
- `lib/firebase_options.dart` - Anciennes clés supprimées, prêt pour la nouvelle config

### ✅ Nouveaux fichiers créés :
- `CONFIGURATION_FIREBASE.md` - Guide complet détaillé
- `DEMARRAGE_RAPIDE.md` - Ce guide rapide
- `configure_firebase.ps1` - Script d'assistance Windows
- `lib/utils/firebase_checker.dart` - Outil de vérification
- `lib/main.dart` - Mis à jour avec gestion d'erreurs améliorée

### ✅ Fichiers préservés :
Tous vos services et modèles existants :
- `lib/services/` - auth_service, user_service, order_service, etc.
- `lib/models/` - Tous vos modèles de données
- `lib/controllers/` - Tous vos contrôleurs
- `lib/views/` - Toutes vos vues

---

## 🔄 Anciennes Données

L'ancienne base de données (`livraison-6f112`) n'est plus connectée.

Si vous avez besoin de migrer des données :
1. Exportez depuis l'ancienne base (Firebase Console → Firestore → Export)
2. Importez dans la nouvelle base

---

## 🆘 Besoin d'aide ?

### Problème : "No Firebase App has been created"
➡️ Exécutez `flutterfire configure`

### Problème : "Permission denied"
➡️ Vérifiez les règles Firestore (Étape 3 ci-dessus)

### Problème : "Invalid API key"
➡️ Vérifiez que `firebase_options.dart` contient les bonnes clés

### Documentation complète
➡️ Consultez `CONFIGURATION_FIREBASE.md`

---

## 🎉 Prêt !

Une fois configuré, l'application :
- Se connectera à votre nouvelle base Firebase
- Créera automatiquement les collections nécessaires
- Initialisera les catégories par défaut
- Sera prête à l'emploi !

**Bon développement ! 🚀**
