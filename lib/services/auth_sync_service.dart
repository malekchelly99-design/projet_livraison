import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_role.dart';
import 'user_service.dart';

/// Service pour synchroniser Firebase Auth et Firestore
/// Utile après une migration ou suppression de base de données
class AuthSyncService {
  final FirebaseAuth _auth;
  final UserService _userService;

  AuthSyncService({
    FirebaseAuth? auth,
    UserService? userService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _userService = userService ?? UserService();

  /// Vérifie si un utilisateur a un profil Firestore correspondant
  Future<bool> hasFirestoreProfile(User user) async {
    return await _userService.exists(user.uid);
  }

  /// Crée un profil Firestore pour un utilisateur Auth existant
  Future<void> syncUserProfile(User user, {UserRole defaultRole = UserRole.client}) async {
    final exists = await hasFirestoreProfile(user);
    if (exists) {
      return; // Le profil existe déjà
    }

    // Créer le profil manquant
    await _userService.createOrRestoreProfile(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      phoneNumber: user.phoneNumber,
      defaultRole: defaultRole,
    );
  }

  /// Synchronise tous les utilisateurs Auth avec Firestore
  /// ATTENTION : À utiliser uniquement pour la maintenance
  Future<Map<String, dynamic>> syncAllUsers() async {
    int totalAuth = 0;
    int synced = 0;
    int errors = 0;
    final List<String> syncedEmails = [];
    final List<String> errorEmails = [];

    try {
      // Note : listUsers() nécessite Firebase Admin SDK
      // Dans une vraie app, cela devrait être fait via Cloud Functions
      // Pour l'instant, on ne peut synchroniser que l'utilisateur actuel
      
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        totalAuth = 1;
        try {
          await syncUserProfile(currentUser);
          synced = 1;
          syncedEmails.add(currentUser.email ?? currentUser.uid);
        } catch (e) {
          errors = 1;
          errorEmails.add(currentUser.email ?? currentUser.uid);
        }
      }

      return {
        'success': true,
        'totalAuth': totalAuth,
        'synced': synced,
        'errors': errors,
        'syncedEmails': syncedEmails,
        'errorEmails': errorEmails,
        'message': 'Synchronisation terminée. $synced/$totalAuth utilisateurs synchronisés.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la synchronisation : $e',
      };
    }
  }

  /// Compte les utilisateurs Auth sans profil Firestore
  /// (uniquement l'utilisateur connecté dans cette version client)
  Future<int> countOrphanedAuthUsers() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return 0;

    final hasProfile = await hasFirestoreProfile(currentUser);
    return hasProfile ? 0 : 1;
  }

  /// Diagnostic complet de l'état de synchronisation
  Future<Map<String, dynamic>> diagnosticSync() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return {
        'authenticated': false,
        'message': 'Aucun utilisateur connecté',
      };
    }

    final hasProfile = await hasFirestoreProfile(currentUser);

    return {
      'authenticated': true,
      'uid': currentUser.uid,
      'email': currentUser.email,
      'displayName': currentUser.displayName,
      'hasFirestoreProfile': hasProfile,
      'needsSync': !hasProfile,
      'message': hasProfile
          ? 'Profil synchronisé correctement'
          : 'Profil Firestore manquant - synchronisation requise',
    };
  }
}
