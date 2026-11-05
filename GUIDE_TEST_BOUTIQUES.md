# 🛍️ Guide de Test - Boutiques dans le Tableau de Bord Client

## ✅ Problème Résolu

Vous avez signalé que les boutiques n'apparaissaient pas dans le tableau de bord client. La solution a été implémentée : **5 boutiques de démonstration sont maintenant créées automatiquement** au premier démarrage de l'application.

---

## 🚀 Étapes pour Tester

### 1. Redémarrer l'application

```bash
flutter run -d chrome
```

L'application va :
- Se connecter à Firebase
- Vérifier si la collection `boutiques` est vide
- **Créer automatiquement 5 boutiques de démonstration** si aucune boutique n'existe

### 2. Se connecter en tant que Client

- Utilisez vos identifiants client existants, OU
- Créez un nouveau compte avec le rôle "Client"

### 3. Accéder à l'onglet "Boutiques"

Dans le tableau de bord client, vous avez **2 façons** d'accéder aux boutiques :

#### Option A : Navigation Principale (Mobile)
- En bas de l'écran, cliquez sur l'onglet **"Boutiques"** (3ème icône : 🏪)

#### Option B : Navigation Latérale (Desktop)
- Dans la barre latérale gauche, cliquez sur **"Boutiques partenaires"**

---

## 🏪 Boutiques de Démonstration Créées

Voici les **5 boutiques** qui seront créées automatiquement :

### 1. **Pizza Express** 🍕
- **Catégorie** : Restaurant
- **Adresse** : 15 Avenue Habib Bourguiba, Tunis
- **Horaires** : 11:00 - 23:00
- **Description** : Pizzas au feu de bois, pâtes fraîches maison
- **Contact** : +216 71 123 456

### 2. **Burger House** 🍔
- **Catégorie** : Fast-food
- **Adresse** : 42 Rue de la Liberté, Tunis
- **Horaires** : 12:00 - 22:30
- **Description** : Burgers artisanaux, frites maison
- **Contact** : +216 71 234 567

### 3. **Sushi Deluxe** 🍱
- **Catégorie** : Restaurant
- **Adresse** : 8 Avenue Mohamed V, Tunis
- **Horaires** : 12:00 - 22:00
- **Description** : Sushi frais, cuisine japonaise authentique
- **Contact** : +216 71 345 678

### 4. **Boulangerie Gourmande** 🥐
- **Catégorie** : Pâtisserie / Boulangerie
- **Adresse** : 23 Rue de Marseille, Tunis
- **Horaires** : 06:00 - 20:00
- **Description** : Pain frais, viennoiseries, pâtisseries
- **Contact** : +216 71 456 789

### 5. **Superette du Coin** 🛒
- **Catégorie** : Supermarché / Épicerie
- **Adresse** : 67 Avenue de Carthage, Tunis
- **Horaires** : 08:00 - 21:00
- **Description** : Produits frais, épicerie, boissons
- **Contact** : +216 71 567 890

---

## 🔍 Fonctionnalités à Tester

### ✨ Recherche de Boutiques
1. Dans l'onglet Boutiques, utilisez la **barre de recherche** en haut
2. Tapez un nom de boutique (ex: "Pizza"), une catégorie (ex: "Restaurant"), ou une ville (ex: "Tunis")
3. Les résultats se filtrent automatiquement

### 📋 Affichage des Détails
Chaque carte de boutique affiche :
- ✅ Nom de la boutique
- ✅ Catégorie
- ✅ Ville
- ✅ Horaires d'ouverture
- ✅ Description
- ✅ Téléphone de contact

### 🛒 Commander depuis une Boutique
1. Cliquez sur une boutique
2. Vous verrez les produits de cette boutique (si elle a des produits)
3. Ajoutez des articles au panier

---

## 🔧 Vérification Firebase

Si les boutiques n'apparaissent toujours pas, vérifiez dans la **Firebase Console** :

### 1. Accéder à Firestore
1. Ouvrez [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet : **livraison-6f112**
3. Allez dans **Firestore Database**

### 2. Vérifier la Collection `boutiques`
- Vous devriez voir une collection **`boutiques`**
- Elle doit contenir **5 documents** avec les IDs :
  - `demo_pizzeria_001`
  - `demo_burger_002`
  - `demo_sushi_003`
  - `demo_bakery_004`
  - `demo_grocery_005`

### 3. Vérifier les Règles de Sécurité
Dans **Firestore → Règles**, assurez-vous que :

```javascript
match /boutiques/{boutiqueId} {
  allow read: if true; // Tout le monde peut voir les boutiques
  allow create: if isSignedIn();
  allow update, delete: if isSignedIn() && 
    request.auth.uid == resource.data.vendeurId;
}
```

---

## ❌ Dépannage

### Problème : Les boutiques ne s'affichent pas après le démarrage

**Solution 1 : Forcer la recréation**
1. Ouvrez la **Firebase Console**
2. Allez dans **Firestore Database**
3. Supprimez manuellement la collection `boutiques` (si elle existe)
4. Redémarrez l'application : `flutter run -d chrome`
5. Les boutiques de démo seront recréées automatiquement

**Solution 2 : Vérifier la console du navigateur**
1. Appuyez sur **F12** dans Chrome
2. Allez dans l'onglet **Console**
3. Cherchez des erreurs liées à Firestore ou aux boutiques
4. Partagez ces erreurs si nécessaire

**Solution 3 : Vérifier l'authentification**
- Assurez-vous que vous êtes bien connecté en tant que **Client**
- Vérifiez que votre rôle est bien "client" dans Firestore (`users` collection)

---

## 📊 Que se Passe-t-il en Arrière-Plan ?

### Flux d'Initialisation

```
1. Application démarre (main.dart)
   ↓
2. Firebase s'initialise
   ↓
3. DatabaseInitService.initializeTables() s'exécute
   ↓
4. Vérification : collection 'boutiques' est-elle vide ?
   ↓
5. Si OUI → _createDemoBoutiques() crée 5 boutiques
   ↓
6. Boutiques sauvegardées dans Firestore
   ↓
7. Client peut maintenant voir les boutiques
```

### Code Responsable

Le code qui crée les boutiques se trouve dans :
- **Fichier** : `lib/services/database_init_service.dart`
- **Méthode** : `_createDemoBoutiques()`
- **Déclenchement** : Automatique au démarrage si `boutiques` est vide

---

## ✅ Résultat Attendu

Après avoir suivi ces étapes, vous devriez voir :

1. **Dans l'onglet "Boutiques partenaires"** :
   - 5 cartes de boutiques affichées
   - Chaque carte montre le nom, catégorie, ville, horaires

2. **Barre de recherche fonctionnelle** :
   - Recherche par nom, catégorie, ou ville

3. **Possibilité de cliquer sur une boutique** :
   - Affiche les produits de cette boutique (si disponibles)

---

## 🎯 Prochaines Étapes

Une fois les boutiques visibles, vous pouvez :

1. **Ajouter des produits** (en tant que vendeur)
   - Connectez-vous avec un compte vendeur
   - Ajoutez des produits à votre boutique
   - Ces produits apparaîtront aux clients

2. **Tester une commande complète** :
   - Client parcourt les boutiques
   - Client ajoute des produits au panier
   - Client passe commande
   - Vendeur reçoit la commande
   - Livreur récupère et livre

---

## 📞 Besoin d'Aide ?

Si les boutiques n'apparaissent toujours pas :
1. Vérifiez la console Firebase (étape "Vérification Firebase")
2. Vérifiez la console Chrome (F12) pour des erreurs
3. Assurez-vous que les règles Firestore autorisent la lecture de `boutiques`
4. Partagez les logs d'erreur pour un diagnostic approfondi

---

**Date de création** : Novembre 2026  
**Fichier modifié** : `lib/services/database_init_service.dart`  
**Statut** : ✅ Implémenté et Prêt à Tester
