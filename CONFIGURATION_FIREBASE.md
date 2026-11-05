# Configuration de la Nouvelle Base de Données Firebase

## 🎯 Guide Complet de Configuration

### Méthode 1 : Configuration Automatique avec FlutterFire CLI (Recommandée)

#### Étape 1 : Installation de FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

#### Étape 2 : Créer un Nouveau Projet Firebase
1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Cliquez sur "Ajouter un projet"
3. Donnez un nom à votre projet (ex: "livraison-app-2024")
4. Suivez les étapes de création

#### Étape 3 : Configuration Automatique
```bash
flutterfire configure
```

Cette commande va :
- Vous connecter à votre compte Google
- Lister vos projets Firebase
- Vous permettre de sélectionner ou créer un projet
- Générer automatiquement le fichier `firebase_options.dart` avec toutes les bonnes clés

#### Étape 4 : Activer les Services Firebase

##### 4.1 Activer Authentication
1. Dans la console Firebase, allez dans **Authentication**
2. Cliquez sur **Commencer**
3. Activez le fournisseur **E-mail/Mot de passe**
4. Sauvegardez

##### 4.2 Créer la Base de Données Firestore
1. Dans la console Firebase, allez dans **Firestore Database**
2. Cliquez sur **Créer une base de données**
3. Choisissez le mode :
   - **Mode production** (recommandé) : Règles de sécurité strictes
   - **Mode test** : Accès ouvert (à éviter en production)
4. Sélectionnez la région la plus proche de vos utilisateurs
5. Cliquez sur **Activer**

##### 4.3 Configurer les Règles de Sécurité Firestore
Dans l'onglet **Règles** de Firestore, copiez ces règles :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Fonction pour vérifier si l'utilisateur est authentifié
    function isSignedIn() {
      return request.auth != null;
    }
    
    // Fonction pour vérifier si l'utilisateur possède un document
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    // Fonction pour obtenir le rôle de l'utilisateur
    function getUserRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
    }
    
    // Fonction pour vérifier si l'utilisateur est admin
    function isAdmin() {
      return isSignedIn() && getUserRole() == 'admin';
    }
    
    // Collection users - Lecture par l'utilisateur lui-même, admin peut tout lire
    match /users/{userId} {
      allow read: if isOwner(userId) || isAdmin();
      allow create: if isSignedIn();
      allow update: if isOwner(userId) || isAdmin();
      allow delete: if isAdmin();
    }
    
    // Collection boutiques
    match /boutiques/{boutiqueId} {
      allow read: if true; // Tout le monde peut voir les boutiques
      allow create: if isSignedIn();
      allow update: if isOwner(boutiqueId) || isAdmin();
      allow delete: if isAdmin();
    }
    
    // Collection products
    match /products/{productId} {
      allow read: if true; // Tout le monde peut voir les produits
      allow create: if isSignedIn();
      allow update: if isSignedIn();
      allow delete: if isSignedIn();
    }
    
    // Collection categories
    match /categories/{categoryId} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    // Collection orders
    match /orders/{orderId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn();
      allow update: if isSignedIn();
      allow delete: if isAdmin();
    }
    
    // Collection settings
    match /settings/{settingId} {
      allow read: if true;
      allow write: if isAdmin();
    }
  }
}
```

#### Étape 5 : Tester la Configuration
```bash
flutter run -d chrome
```

---

### Méthode 2 : Configuration Manuelle

Si vous préférez configurer manuellement :

#### Étape 1 : Récupérer les Clés de Configuration

##### Pour Web :
1. Dans Firebase Console, allez dans **Paramètres du projet** (icône engrenage)
2. Descendez à la section **Vos applications**
3. Cliquez sur l'icône Web `</>`
4. Enregistrez l'application avec un surnom
5. Copiez les valeurs de configuration

##### Pour Android :
1. Cliquez sur l'icône Android
2. Suivez les instructions
3. Téléchargez le fichier `google-services.json`
4. Placez-le dans `android/app/`

##### Pour iOS :
1. Cliquez sur l'icône iOS
2. Suivez les instructions
3. Téléchargez le fichier `GoogleService-Info.plist`
4. Placez-le dans `ios/Runner/`

#### Étape 2 : Modifier firebase_options.dart

Ouvrez le fichier `lib/firebase_options.dart` et remplacez toutes les valeurs `VOTRE_XXX` par vos vraies valeurs Firebase.

Exemple pour Web :
```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyAbc123def456ghi789jkl012mno345pqr',
  appId: '1:123456789012:web:abc123def456ghi789',
  messagingSenderId: '123456789012',
  projectId: 'mon-nouveau-projet',
  authDomain: 'mon-nouveau-projet.firebaseapp.com',
  storageBucket: 'mon-nouveau-projet.firebasestorage.app',
  measurementId: 'G-ABC123DEF4',
);
```

---

## 🗄️ Structure de la Base de Données

Votre application créera automatiquement ces collections :

### 1. **users**
Stocke les profils des utilisateurs (admin, vendeur, livreur, client)
```
users/{userId}
  - name: string
  - email: string
  - phone: string
  - role: string (admin|vendeur|livreur|client)
  - profile: map
  - createdAt: timestamp
  - updatedAt: timestamp
```

### 2. **boutiques**
Informations sur les boutiques des vendeurs
```
boutiques/{vendeurId}
  - nomBoutique: string
  - categorie: string
  - adresse: string
  - ville: string
  - description: string
  - etc.
```

### 3. **products**
Catalogue de produits
```
products/{productId}
  - name: string
  - price: number
  - category: string
  - vendorId: string
  - shopName: string
  - etc.
```

### 4. **orders**
Commandes
```
orders/{orderId}
  - clientId: string
  - clientName: string
  - items: array
  - totalAmount: number
  - status: string
  - createdAt: timestamp
  - etc.
```

### 5. **categories**
Catégories de produits (pré-remplies automatiquement)

### 6. **settings**
Paramètres de la plateforme

---

## ✅ Vérification de la Configuration

Une fois configuré, lancez l'application :

```bash
flutter run -d chrome
```

L'application va automatiquement :
1. Se connecter à Firebase
2. Initialiser les tables (collections) nécessaires
3. Créer les catégories par défaut
4. Créer les paramètres de base

---

## 🔧 Commandes Utiles

```bash
# Nettoyer le projet
flutter clean

# Récupérer les dépendances
flutter pub get

# Lancer l'application
flutter run -d chrome          # Pour le web
flutter run -d windows         # Pour Windows
flutter run                    # Pour mobile (si connecté)

# Reconfigurer Firebase
flutterfire configure
```

---

## 🆘 Dépannage

### Erreur : "No Firebase App '[DEFAULT]' has been created"
- Vérifiez que `firebase_options.dart` contient les bonnes clés
- Assurez-vous que `Firebase.initializeApp()` est appelé dans `main.dart`

### Erreur : "PERMISSION_DENIED"
- Vérifiez les règles de sécurité Firestore
- Assurez-vous que l'authentification est activée

### Erreur lors du lancement
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📱 Prochaines Étapes

1. ✅ Configurer Firebase avec une des méthodes ci-dessus
2. ✅ Activer Authentication (Email/Password)
3. ✅ Créer Firestore Database
4. ✅ Configurer les règles de sécurité
5. ✅ Tester l'application
6. 📊 Créer votre premier compte admin
7. 🚀 Commencer à utiliser l'application !

---

**Besoin d'aide ?** Consultez la [documentation Firebase](https://firebase.google.com/docs/flutter/setup)
