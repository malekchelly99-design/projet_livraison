# Script de Configuration Firebase pour Windows
# Ce script vous guide dans la configuration de Firebase pour votre application Flutter

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   CONFIGURATION FIREBASE - ASSISTANT   " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier si Flutter est installé
Write-Host "Vérification de Flutter..." -ForegroundColor Yellow
$flutterVersion = flutter --version 2>&1 | Select-String "Flutter"
if ($flutterVersion) {
    Write-Host "✓ Flutter est installé" -ForegroundColor Green
} else {
    Write-Host "✗ Flutter n'est pas installé ou pas dans le PATH" -ForegroundColor Red
    Write-Host "  Installez Flutter depuis: https://flutter.dev/docs/get-started/install" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Choisissez votre méthode de configuration:" -ForegroundColor Yellow
Write-Host "1. Configuration automatique avec FlutterFire CLI (Recommandé)"
Write-Host "2. Configuration manuelle (vous avez déjà les clés)"
Write-Host "3. Voir le guide complet"
Write-Host "4. Quitter"
Write-Host ""
$choice = Read-Host "Votre choix (1-4)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "=== Configuration Automatique ===" -ForegroundColor Cyan
        Write-Host ""
        
        # Vérifier si dart est disponible
        $dartCheck = dart --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "✗ Dart n'est pas disponible" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "Installation de FlutterFire CLI..." -ForegroundColor Yellow
        dart pub global activate flutterfire_cli
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ FlutterFire CLI installé" -ForegroundColor Green
            Write-Host ""
            Write-Host "Lancement de la configuration Firebase..." -ForegroundColor Yellow
            Write-Host "Suivez les instructions à l'écran pour:" -ForegroundColor Yellow
            Write-Host "  1. Vous connecter à votre compte Google"
            Write-Host "  2. Sélectionner ou créer un projet Firebase"
            Write-Host "  3. Sélectionner les plateformes (Web, Android, iOS, Windows)"
            Write-Host ""
            
            flutterfire configure
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host ""
                Write-Host "✓ Configuration réussie!" -ForegroundColor Green
                Write-Host ""
                Write-Host "Prochaines étapes:" -ForegroundColor Yellow
                Write-Host "1. Activez Authentication (Email/Password) dans la console Firebase"
                Write-Host "2. Créez une base de données Firestore"
                Write-Host "3. Configurez les règles de sécurité (voir CONFIGURATION_FIREBASE.md)"
                Write-Host ""
                Write-Host "Voulez-vous ouvrir la console Firebase? (O/N)" -ForegroundColor Yellow
                $openConsole = Read-Host
                if ($openConsole -eq "O" -or $openConsole -eq "o") {
                    Start-Process "https://console.firebase.google.com/"
                }
            } else {
                Write-Host "✗ Erreur lors de la configuration" -ForegroundColor Red
            }
        } else {
            Write-Host "✗ Erreur lors de l'installation de FlutterFire CLI" -ForegroundColor Red
        }
    }
    
    "2" {
        Write-Host ""
        Write-Host "=== Configuration Manuelle ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Pour configurer manuellement:" -ForegroundColor Yellow
        Write-Host "1. Ouvrez lib/firebase_options.dart"
        Write-Host "2. Remplacez toutes les valeurs VOTRE_XXX par vos vraies clés Firebase"
        Write-Host "3. Récupérez vos clés depuis la console Firebase:"
        Write-Host ""
        Write-Host "Voulez-vous ouvrir la console Firebase? (O/N)" -ForegroundColor Yellow
        $openConsole = Read-Host
        if ($openConsole -eq "O" -or $openConsole -eq "o") {
            Start-Process "https://console.firebase.google.com/"
        }
        Write-Host ""
        Write-Host "Voulez-vous ouvrir le fichier firebase_options.dart? (O/N)" -ForegroundColor Yellow
        $openFile = Read-Host
        if ($openFile -eq "O" -or $openFile -eq "o") {
            code lib/firebase_options.dart
        }
    }
    
    "3" {
        Write-Host ""
        Write-Host "Ouverture du guide complet..." -ForegroundColor Yellow
        code CONFIGURATION_FIREBASE.md
    }
    
    "4" {
        Write-Host "Au revoir!" -ForegroundColor Cyan
        exit 0
    }
    
    default {
        Write-Host "Choix invalide" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Pour tester votre configuration:" -ForegroundColor Yellow
Write-Host "  flutter run -d chrome" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pour voir les logs de démarrage avec vérification:" -ForegroundColor Yellow
Write-Host "  Décommentez la ligne 'FirebaseChecker.printConfigReport()' dans lib/main.dart" -ForegroundColor Cyan
Write-Host ""
