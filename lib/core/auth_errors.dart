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
        return 'Un compte existe déjà avec cet email.';
      case 'weak-password':
        return 'Mot de passe trop faible (6 caractères minimum).';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessaie plus tard.';
      case 'network-request-failed':
        return 'Problème de connexion internet.';
    }
  }
  return 'Une erreur est survenue. Réessaie.';
}
