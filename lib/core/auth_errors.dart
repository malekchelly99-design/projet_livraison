import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Messages d'erreur lisibles en français.
String authErrorMessage(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email':
        return "L'adresse email n'est pas valide.";
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet email. Veuillez vous connecter ou utiliser un autre email.';
      case 'weak-password':
        return 'Mot de passe trop faible (8 caractères minimum).';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessaie plus tard.';
      case 'network-request-failed':
        return 'Problème de connexion internet.';
      default:
        return e.message ?? 'Erreur d\'authentification (${e.code}).';
    }
  }

  if (e is FirebaseException) {
    if (e.code == 'permission-denied') {
      return "Accès refusé par les règles de sécurité Firestore. Veuillez copier le contenu de 'firestore.rules' dans la console Firebase (onglet Firestore > Règles) et cliquer sur Publier.";
    }
    return e.message ?? 'Erreur Firestore (${e.code}).';
  }

  final str = e.toString();
  if (str.contains('permission-denied')) {
    return "Permission refusée sur Firestore. Assurez-vous de publier les règles dans la console Firebase (onglet Rules).";
  }

  return 'Erreur : $e';
}
