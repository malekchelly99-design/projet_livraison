# 🛠️ Commandes Utiles - Projet Livraison

## 🚀 Configuration Initiale

### Configurer Firebase (PREMIÈRE ÉTAPE OBLIGATOIRE)

```powershell
# Option 1 : Avec l'assistant (Recommandé)
.\configure_firebase.ps1

# Option 2 : Directement avec FlutterFire CLI
dart pub global activate flutterfire_cli
flutterfire configure
```

---

## 📦 Gestion des Dépendances

### Installer/Mettre à jour les packages

```bash
# Récupérer les dépendances
flutter pub get

# Voir les packages obsolètes
flutter pub outdated

# Mettre à jour les packages (dans pubspec.yaml)
flutter pub upgrade
```

---

## 🏃 Lancer l'Application

### Sur différentes plateformes

```bash
# Web (Chrome) - Développement rapide
flutter run -d chrome

# Windows
flutter run -d windows

# Android (émulateur ou appareil connecté)
flutter run -d android

# iOS (Mac seulement)
flutter run -d ios

# Voir tous les appareils disponibles
flutter devices
```

### Mode Release (Production)

```bash
# Web
flutter build web

# Windows
flutter build windows

# Android APK
flutter build apk

# Android App Bundle (pour Play Store)
flutter build appbundle
```

---

## 🧹 Nettoyage du Projet

### Quand l'application ne compile pas bien

```bash
# Nettoyer complètement le projet
flutter clean

# Récupérer les dépendances
flutter pub get

# Relancer
flutter run
```

### Nettoyage complet avec cache

```bash
flutter clean
flutter pub cache clean
flutter pub get
```

---

## 🔍 Analyse et Vérification

### Vérifier le code

```bash
# Analyser le code pour les erreurs
flutter analyze

# Formater le code automatiquement
dart format .

# Formater un fichier spécifique
dart format lib/main.dart
```

### Vérifier la configuration Firebase

Dans `lib/main.dart`, décommentez :
```dart
await FirebaseChecker.printConfigReport();
```

Puis :
```bash
flutter run -d chrome
```

Regardez la console pour le rapport détaillé.

---

## 🧪 Tests

### Lancer les tests

```bash
# Tous les tests
flutter test

# Tests avec couverture
flutter test --coverage

# Un fichier de test spécifique
flutter test test/services/auth_service_test.dart
```

---

## 🔥 Firebase - Commandes Utiles

### Reconfigurer Firebase

```bash
# Changer de projet Firebase
flutterfire configure

# Forcer la reconfiguration
flutterfire configure --force

# Configurer seulement certaines plateformes
flutterfire configure --platforms=web,android
```

### Vérifier la configuration Firebase

```bash
# Voir les projets Firebase disponibles
firebase projects:list

# Login à Firebase CLI
firebase login

# Logout
firebase logout
```

---

## 📱 Android Spécifique

### Générer un keystore pour la signature

```bash
# Windows (PowerShell)
keytool -genkey -v -keystore C:\Users\USER\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Vérifier le keystore
keytool -list -v -keystore C:\Users\USER\upload-keystore.jks
```

### Build pour production

```bash
# APK (pour tests)
flutter build apk --release

# App Bundle (pour Play Store)
flutter build appbundle --release

# APK split par architecture (fichiers plus petits)
flutter build apk --split-per-abi
```

---

## 🌐 Web Spécifique

### Build et deploy

```bash
# Build optimisé pour production
flutter build web --release

# Build avec profil spécifique
flutter build web --web-renderer canvaskit
flutter build web --web-renderer html

# Les fichiers sont dans : build/web/
```

### Serveur local pour tester le build

```bash
# Avec Python 3
cd build/web
python -m http.server 8000

# Avec Node.js (si http-server installé)
npx http-server build/web

# Ouvrir : http://localhost:8000
```

---

## 🪟 Windows Spécifique

### Build pour Windows

```bash
# Build en mode release
flutter build windows --release

# Le fichier .exe est dans : build\windows\runner\Release\
```

---

## 🐛 Débogage

### Logs et diagnostics

```bash
# Voir les logs en temps réel
flutter run --verbose

# Activer les DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Doctor - Vérifier l'environnement Flutter
flutter doctor
flutter doctor -v
```

### Hot Reload

Pendant que l'app tourne :
- `r` - Hot reload (recharge rapide)
- `R` - Hot restart (redémarre l'app)
- `q` - Quitter
- `h` - Aide

---

## 📊 Base de Données Firestore

### Opérations via Firebase CLI

```bash
# Export de la base (backup)
firebase firestore:export gs://BUCKET_NAME/backups/backup-$(date +%Y%m%d)

# Import dans la base
firebase firestore:import gs://BUCKET_NAME/backups/backup-20261104

# Supprimer une collection (ATTENTION!)
firebase firestore:delete COLLECTION_NAME --recursive
```

---

## 🔐 Sécurité

### Règles Firestore

```bash
# Déployer les règles
firebase deploy --only firestore:rules

# Tester les règles localement
firebase emulators:start
```

### Vérifier les clés Firebase

```bash
# Vérifier que firebase_options.dart n'a pas de placeholders
findstr /C:"VOTRE_" lib\firebase_options.dart

# Si résultat : ERREUR - Vous devez configurer Firebase
# Si aucun résultat : OK - Firebase est configuré
```

---

## 📦 Dépendances du Projet

### Packages Firebase utilisés

```yaml
dependencies:
  firebase_core: ^4.15.0        # Core Firebase
  firebase_auth: ^6.7.0          # Authentication
  cloud_firestore: ^6.10.0      # Base de données
```

### Ajouter un nouveau package

```bash
# Ajouter un package
flutter pub add nom_du_package

# Ajouter en dev dependency
flutter pub add --dev nom_du_package

# Exemple : Ajouter provider
flutter pub add provider
```

---

## 🎨 Génération de Code

### Icons et Assets

```bash
# Si vous ajoutez des assets, mettre à jour pubspec.yaml
# Puis lancer :
flutter pub get
```

---

## 📝 Maintenance

### Mise à jour de Flutter

```bash
# Vérifier les mises à jour
flutter upgrade

# Passer à un channel spécifique
flutter channel stable
flutter channel beta

# Voir la version actuelle
flutter --version
```

### Migration de version

```bash
# Migrer vers null-safety
dart migrate

# Fix automatique de code
dart fix --apply
```

---

## 🚨 Commandes d'Urgence

### L'app ne compile plus

```bash
# 1. Tout nettoyer
flutter clean
rm -rf pubspec.lock
rm -rf .dart_tool

# 2. Récupérer les dépendances
flutter pub get

# 3. Relancer
flutter run
```

### Erreur Firebase

```bash
# 1. Vérifier la configuration
flutterfire configure

# 2. Nettoyer et reconstruire
flutter clean
flutter pub get
flutter run
```

### Erreur de version/dépendance

```bash
# 1. Supprimer le lock file
rm pubspec.lock

# 2. Récupérer avec résolution de conflits
flutter pub get

# 3. Si ça ne marche pas, downgrade
flutter pub downgrade
```

---

## 📚 Documentation et Aide

### Ouvrir la documentation

```bash
# Documentation Flutter
flutter help

# Documentation d'une commande spécifique
flutter help run
flutter help build

# Ouvrir la doc API dans le navigateur
flutter pub global activate dartdoc
dartdoc
```

### Liens Utiles

- [Flutter Docs](https://flutter.dev/docs)
- [Firebase Docs](https://firebase.google.com/docs/flutter)
- [Dart Packages](https://pub.dev/)
- [FlutterFire](https://firebase.flutter.dev/)

---

## 🎯 Workflow Typique de Développement

```bash
# 1. Démarrer le jour
git pull                          # Récupérer les changements
flutter pub get                   # Mettre à jour les dépendances

# 2. Développer
flutter run -d chrome             # Lancer l'app
# Coder avec hot reload (r)

# 3. Avant de commit
flutter analyze                   # Vérifier les erreurs
dart format .                     # Formater le code
flutter test                      # Lancer les tests

# 4. Commit
git add .
git commit -m "Description"
git push

# 5. Build pour production (si nécessaire)
flutter build web --release
```

---

## 💡 Astuces

### Performance

```bash
# Profiler les performances
flutter run --profile

# Analyser la taille de l'app
flutter build apk --analyze-size
```

### Générer un APK de debug pour tester

```bash
flutter build apk --debug
# Plus rapide que --release pour les tests
```

### Changer de version Flutter

```bash
# Lister les versions disponibles
flutter version

# Passer à une version spécifique
flutter version 3.16.0
```

---

**Raccourcis à retenir :**

| Commande | Usage |
|----------|-------|
| `flutter run -d chrome` | Lancer rapidement |
| `flutter clean && flutter pub get` | Nettoyer et réinstaller |
| `r` | Hot reload pendant l'exécution |
| `flutterfire configure` | Reconfigurer Firebase |
| `flutter doctor` | Diagnostiquer l'environnement |
| `.\configure_firebase.ps1` | Assistant de configuration |

---

**Bon développement ! 🚀**
