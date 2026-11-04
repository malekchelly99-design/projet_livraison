# Application de Livraison Rapide Multi-Rôles (Flutter & Firebase)

Application complète de livraison à la demande connectée en temps réel avec Firebase Firestore et Firebase Authentication, gérant 4 rôles distincts : **Client**, **Vendeur (Boutique)**, **Livreur** et **Administrateur**.

---

## 🗄️ Structure des Tables de la Base de Données (Firestore)

Les collections (tables) dans Firestore sont structurées comme suit :

### 1. Table `users` (Utilisateurs)
Stocke tous les comptes utilisateurs avec leurs informations personnelles et professionnelles.
- `uid` *(string)* : Identifiant unique de l'utilisateur (UID Firebase Auth).
- `name` *(string)* : Nom et prénom de l'utilisateur.
- `email` *(string)* : Adresse e-mail de connexion.
- `phone` *(string)* : Numéro de téléphone pour les livraisons.
- `role` *(string)* : Rôle de l'utilisateur (`client`, `vendeur`, `livreur`, `admin`).
- `profile` *(map)* : Données spécifiques au rôle :
  - **Pour un vendeur** : `shopName` (nom de l'enseigne), `category` (catégorie du commerce), `address` (adresse), `city` (ville), `taxId` (matricule fiscal), `isBlocked` (booléen).
  - **Pour un livreur** : `vehicleType` (type de véhicule), `plateNumber` (immatriculation), `cin` (carte d'identité), `city` (zone de livraison), `isBlocked` (booléen).
  - **Pour un client** : `address` (adresse par défaut), `city` (ville), `isBlocked` (booléen).
- `isAvailable` *(bool, livreurs)* : Disponibilité en temps réel pour recevoir des courses.
- `createdAt` *(timestamp)* : Date de création du compte.
- `updatedAt` *(timestamp)* : Date de dernière modification.

### 2. Table `products` (Catalogue des Produits)
Articles et plats mis en vente par les boutiques partenaires.
- `id` *(string)* : Identifiant unique du document produit.
- `name` *(string)* : Nom du produit / plat.
- `description` *(string)* : Ingrédients, description ou caractéristiques.
- `price` *(number)* : Prix unitaire en dinars (DT).
- `category` *(string)* : Catégorie (`Restauration`, `Pizzas & Fast-food`, `Épicerie`, `Boulangerie & Pâtisserie`, `Boissons & Cafés`, `Pharmacie & Santé`).
- `shopName` *(string)* : Nom de la boutique propriétaire.
- `vendorId` *(string)* : UID du vendeur propriétaire.
- `rating` *(number)* : Note moyenne (ex. 4.8 / 5).
- `deliveryTimeMinutes` *(number)* : Temps moyen de préparation / livraison estimé.
- `isPopular` *(bool)* : Indicateur pour mise en avant sur l'accueil.
- `imageUrl` *(string)* : URL de la photo du produit.
- `createdAt` *(timestamp)* : Date de création.

### 3. Table `orders` (Commandes & Livraisons)
Cycle de vie complet d'une commande du panier jusqu'à la remise au client.
- `id` *(string)* : Numéro unique de commande.
- `clientId` *(string)* : UID du client ayant passé commande.
- `clientName` *(string)* : Nom du client.
- `clientPhone` *(string)* : Téléphone du client pour le livreur.
- `deliveryAddress` *(string)* : Adresse physique de destination.
- `vendorName` *(string)* : Nom de la boutique préparatrice.
- `courierId` *(string, optionnel)* : UID du livreur ayant accepté la course.
- `courierName` *(string, optionnel)* : Nom du livreur.
- `courierPhone` *(string, optionnel)* : Téléphone du livreur.
- `items` *(array de maps)* :
  - `productId` *(string)* : ID du produit.
  - `name` *(string)* : Nom de l'article.
  - `price` *(number)* : Prix unitaire.
  - `quantity` *(number)* : Quantité commandée.
  - `shopName` *(string)* : Enseigne d'origine.
- `subtotal` *(number)* : Total des articles.
- `deliveryFee` *(number)* : Frais de livraison (4.500 DT).
- `discount` *(number)* : Montant de réduction (code promo).
- `total` *(number)* : Montant total net à régler.
- `status` *(string)* : Statut actuel de la commande :
  - `pending` : En attente de confirmation par le commerçant.
  - `preparing` : En cours de préparation en cuisine / magasin.
  - `ready` : Colis prêt pour ramassage par le coursier.
  - `assigned` : Livreur assigné à la course.
  - `pickedUp` : Colis récupéré chez le vendeur.
  - `delivering` : En cours d'acheminement vers le client.
  - `delivered` : Commande livrée avec succès au client.
  - `cancelled` : Commande annulée.
- `paymentMethod` *(string)* : `Paiement en espèces à la livraison` ou `Paiement par carte bancaire`.
- `notes` *(string, optionnel)* : Instructions spécifiques (étage, code interphone, repères).
- `createdAt` *(timestamp)* : Date et heure de passation.
- `deliveredAt` *(timestamp, optionnel)* : Date et heure de livraison finale.

### 4. Table `categories` (Catégories de Produits & Commerces)
- `id` *(string)* : Identifiant de la catégorie.
- `name` *(string)* : Libellé de la catégorie.
- `icon` *(string)* : Identifiant d'icône Material.
- `description` *(string)* : Courte description de la catégorie.

### 5. Table `settings` (Paramètres Système)
Document `platform` :
- `appName` *(string)* : `Livraison Rapide`
- `baseDeliveryFee` *(number)* : `4.5`
- `platformCommissionRate` *(number)* : `0.10` (10%)
- `currency` *(string)* : `DT`
- `supportPhone` *(string)* : `+216 71 000 000`
- `isMaintenance` *(bool)* : `false`

### 6. Table `boutiques` (Boutiques & Commerces Partenaires)
Créée automatiquement lors de l'inscription d'un vendeur avec tous les attributs de son commerce :
- `id` *(string)* : UID du vendeur (clé primaire du document).
- `vendeurId` *(string)* : UID Firebase du vendeur responsable.
- `nomBoutique` *(string)* : Nom commercial de la boutique / du restaurant.
- `categorie` *(string)* : Catégorie d'activité (`Restaurant`, `Fast-food`, `Pâtisserie / Boulangerie`, `Supermarché / Épicerie`, `Pharmacie`, etc.).
- `adresse` *(string)* : Adresse physique du commerce.
- `ville` *(string)* : Ville / région d'implantation.
- `matriculeFiscale` *(string, optionnel)* : Numéro fiscal du commerce.
- `nomResponsable` *(string)* : Nom et prénom du gérant / responsable.
- `email` *(string)* : Email professionnel de contact.
- `telephone` *(string)* : Numéro de téléphone pour les commandes.
- `description` *(string, optionnel)* : Spécialités ou description courte de la boutique.
- `horaires` *(string)* : Plage horaire d'ouverture (ex. `08:00 - 22:00`).
- `disponible` *(bool)* : Indicateur d'ouverture / disponibilité en direct.
- `rating` *(number)* : Note moyenne de satisfaction client (défaut 5.0).
- `totalVentes` *(number)* : Nombre total de commandes traitées.
- `createdAt` *(timestamp)* : Date d'inscription.
- `updatedAt` *(timestamp)* : Date de dernière modification.

---

## 🚀 Fonctionnalités par Rôle

### 1. Espace Client
- **Accueil / Dashboard** : KPIs (commandes en cours, livrées, montant total dépensé), statut de commande en direct, plats recommandés.
- **Catalogue & Recherche** : Filtres dynamiques par catégorie, recherche textuelle en temps réel, filtres par boutique, ajout rapide au panier.
- **Boutiques Partenaires** : Découverte des commerçants avec bouton direct « Voir le menu » pour commander.
- **Panier & Checkout** : Gestion complète des quantités (+/-), suppression, application de codes promo (`BIENVENUE`, `PROMO20`, `LIVRAISON`), choix de l'adresse de livraison, téléphone, instructions et confirmation de commande.
- **Suivi des Commandes** : Stepper visuel d'avancement de statut, coordonnées du livreur assigné avec numéro d'appel, bouton d'annulation si en attente.
- **Profil** : Modification des coordonnées (nom, téléphone, adresse, ville) avec synchronisation Firestore.

### 2. Espace Vendeur (Boutique)
- **Tableau de Bord** : Suivi des ventes du jour, chiffre d'affaires, commandes en attente et livrées.
- **Catalogue Produits** : Ajout, modification et suppression de produits avec gestion du prix, de la catégorie, du temps de préparation et mise en avant populaire.
- **Commandes Entrantes** : Gestion des commandes reçues avec bascule de statut (`En attente` ➔ `En préparation` ➔ `Prête`).
- **Paramètres de la Boutique** : Configuration des informations de l'établissement (nom d'enseigne, adresse, ville, matricule fiscal).

### 3. Espace Livreur
- **Disponibilité en Temps Réel** : Interrupteur En ligne / Hors ligne sauvegardé dans Firestore.
- **Missions Disponibles** : Affichage des courses prêtes à être livrées sans assignation, avec adresse du vendeur et du client.
- **Course Active & Cycle de Livraison** : Acceptation ➔ Confirmation de prise en charge (`pickedUp`) ➔ Démarrage de la course (`delivering`) ➔ Confirmation de remise en main propre (`delivered`).
- **Historique & Revenus** : Consultation des courses terminées et calcul des gains.
- **Profil Livreur** : Modification du véhicule (moto, scooter, voiture), plaque et zone de travail.

### 4. Espace Administrateur
- **Supervision Globale** : KPIs financiers (CA total, commissions 10%), volumétrie des commandes et répartition par statut.
- **Gestion des Commandes** : Liste complète, filtres par statut, recherche multicritères, assignation manuelle de livreur, annulation ou suppression.
- **Gestion des Utilisateurs** : Annuaire complet, modification des rôles (`client`, `vendeur`, `livreur`, `admin`), blocage/déblocage de comptes.
- **Catalogue Global** : Administration directe de tous les produits de la plateforme.
- **Gestion & Purge de la Base de Données** :
  - **Bouton de Purge** : Supprime en 1 clic toutes les données de test / démo présentes dans Firestore.
  - **Initialisation** : Génère automatiquement les tables et catégories initiales dans la base si vides.

---

## 🛠️ Règles de Sécurité Firestore

Le fichier `firestore.rules` est inclus à la racine du projet et applique les contrôles d'accès par rôle et par authentification pour toutes les tables.
