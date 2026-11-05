import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/auth_errors.dart';
import '../models/app_user.dart';
import '../models/profiles.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/boutique_service.dart';
import '../services/boutique_sync_service.dart';
import '../services/user_service.dart';
import 'base_controller.dart';

/// Résultat du submit pour distinguer succès / erreur / email existant.
enum RegisterResult {
  success,
  error,
  emailAlreadyExists,
}

class RegisterSubmitResult {
  final RegisterResult type;
  final String? errorMessage;
  final String? existingEmail; // rempli si emailAlreadyExists

  const RegisterSubmitResult.success()
      : type = RegisterResult.success,
        errorMessage = null,
        existingEmail = null;

  const RegisterSubmitResult.error(this.errorMessage)
      : type = RegisterResult.error,
        existingEmail = null;

  const RegisterSubmitResult.emailExists(this.existingEmail)
      : type = RegisterResult.emailAlreadyExists,
        errorMessage = null;
}

/// Inscription : état du formulaire (rôle, listes déroulantes)
/// et création du compte + du profil.
class RegisterController extends BaseController {
  static const shopCategories = [
    'Restaurant',
    'Fast-food',
    'Pâtisserie / Boulangerie',
    'Supermarché / Épicerie',
    'Pharmacie',
    'Boutique / Vêtements',
    'Autre',
  ];
  static const vehicleTypes = ['Moto', 'Vélo', 'Voiture', 'Camionnette'];

  final AuthService _auth;
  final UserService _users;
  final BoutiqueService _boutiques;
  final BoutiqueSyncService _boutiqueSync;

  RegisterController({
    AuthService? auth,
    UserService? users,
    BoutiqueService? boutiques,
    BoutiqueSyncService? boutiqueSync,
  })  : _auth = auth ?? AuthService(),
        _users = users ?? UserService(),
        _boutiques = boutiques ?? BoutiqueService(),
        _boutiqueSync = boutiqueSync ?? BoutiqueSyncService();

  UserRole _role = UserRole.client;
  String? _shopCategory;
  String? _vehicleType;
  bool _loading = false;

  UserRole get role => _role;
  String? get shopCategory => _shopCategory;
  String? get vehicleType => _vehicleType;
  bool get loading => _loading;

  bool get isVendeur => _role == UserRole.vendeur;
  bool get isLivreur => _role == UserRole.livreur;

  /// Un vélo n'a pas de plaque d'immatriculation.
  bool get needsPlate => _vehicleType != null && _vehicleType != 'Vélo';

  void selectRole(UserRole role) {
    _role = role;
    notifyListeners();
  }

  void selectShopCategory(String? value) {
    _shopCategory = value;
    notifyListeners();
  }

  void selectVehicleType(String? value) {
    _vehicleType = value;
    notifyListeners();
  }

  /// Soumission du formulaire d'inscription.
  /// Renvoie un [RegisterSubmitResult] qui indique :
  ///   - success → tout est OK
  ///   - error   → message d'erreur générique
  ///   - emailAlreadyExists → l'email est déjà dans Firebase Auth
  Future<RegisterSubmitResult> submitWithResult({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String city,
    String shopName = '',
    String shopAddress = '',
    String taxId = '',
    String description = '',
    String horaires = '08:00 - 22:00',
    String cin = '',
    String plate = '',
  }) async {
    if (!selfRegisterRoles.contains(_role)) {
      return const RegisterSubmitResult.error('Rôle non autorisé à l\'inscription');
    }

    _loading = true;
    notifyListeners();

    try {
      // ── Étape 1 : Créer le compte Firebase Auth ──────────────────────────
      final String uid;
      try {
        uid = await _auth.signUp(
          name: name,
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Cas clé : le compte Auth existe mais pas forcément le profil Firestore
          return RegisterSubmitResult.emailExists(email.trim());
        }
        return RegisterSubmitResult.error(authErrorMessage(e));
      }

      // ── Étape 2 : Vérifier si le doc Firestore n'existe pas déjà ─────────
      // (sécurité anti-doublon si l'appel est répété)
      final alreadyInFirestore = await _users.exists(uid);
      if (!alreadyInFirestore) {
        // ── Étape 3 : Construire et sauvegarder le profil ──────────────────
        final appUser = AppUser(
          uid: uid,
          name: name.trim(),
          email: email.trim(),
          phone: phone.trim(),
          role: _role,
          profile: _buildProfile(
            city: city,
            shopName: shopName,
            shopAddress: shopAddress,
            taxId: taxId,
            description: description,
            horaires: horaires,
            cin: cin,
            plate: plate,
          ),
        );
        await _users.create(appUser);
      }

      // ── Étape 4 : Si vendeur, créer/synchroniser la boutique ──────────────
      if (_role == UserRole.vendeur) {
        await _createBoutiqueOrSync(
          uid: uid,
          shopName: shopName,
          name: name,
          shopAddress: shopAddress,
          city: city,
          taxId: taxId,
          email: email,
          phone: phone,
          description: description,
          horaires: horaires,
        );
      }

      return const RegisterSubmitResult.success();
    } catch (e) {
      debugPrint('Erreur inscription: $e');
      return RegisterSubmitResult.error(authErrorMessage(e));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Conservé pour rétro-compatibilité si besoin.
  Future<String?> submit({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String city,
    String shopName = '',
    String shopAddress = '',
    String taxId = '',
    String description = '',
    String horaires = '08:00 - 22:00',
    String cin = '',
    String plate = '',
  }) async {
    final result = await submitWithResult(
      name: name,
      email: email,
      password: password,
      phone: phone,
      city: city,
      shopName: shopName,
      shopAddress: shopAddress,
      taxId: taxId,
      description: description,
      horaires: horaires,
      cin: cin,
      plate: plate,
    );
    switch (result.type) {
      case RegisterResult.success:
        return null;
      case RegisterResult.emailAlreadyExists:
        return 'Un compte existe déjà avec cet email. Veuillez vous connecter.';
      case RegisterResult.error:
        return result.errorMessage;
    }
  }

  // ── Helpers privés ──────────────────────────────────────────────────────

  Future<void> _createBoutiqueOrSync({
    required String uid,
    required String shopName,
    required String name,
    required String shopAddress,
    required String city,
    required String taxId,
    required String email,
    required String phone,
    required String description,
    required String horaires,
  }) async {
    final nomBoutique = shopName.trim().isNotEmpty
        ? shopName.trim()
        : (name.trim().isNotEmpty ? 'Boutique $name' : 'Boutique');

    try {
      // Use the new boutique sync service for automatic creation
      await _boutiqueSync.createBoutiqueForNewSeller(
        vendeurId: uid,
        shopName: nomBoutique,
        category: _shopCategory ?? 'Autre',
        address: shopAddress,
        city: city,
        phone: phone,
        email: email,
        name: name,
        taxId: taxId,
        description: description,
        horaires: horaires,
      );
      debugPrint('[RegisterController] Boutique created successfully for $uid');
    } catch (e) {
      debugPrint('[RegisterController] Error creating boutique: $e');
      // Try sync as fallback
      try {
        await _boutiqueSync.syncBoutiqueForSeller(
          vendeurId: uid,
          shopName: nomBoutique,
          category: _shopCategory ?? 'Autre',
          address: shopAddress,
          city: city,
          phone: phone,
          email: email,
          name: name,
          taxId: taxId,
          description: description,
          horaires: horaires,
        );
      } catch (e2) {
        debugPrint('[RegisterController] Boutique sync also failed: $e2');
      }
    }
  }

  Map<String, dynamic> _buildProfile({
    required String city,
    required String shopName,
    required String shopAddress,
    required String taxId,
    String description = '',
    String horaires = '08:00 - 22:00',
    required String cin,
    required String plate,
  }) {
    switch (_role) {
      case UserRole.vendeur:
        return ShopProfile(
          shopName: shopName.trim(),
          category: _shopCategory,
          address: shopAddress.trim(),
          city: city.trim(),
          taxId: taxId.trim(),
          description: description.trim(),
          horaires: horaires.trim(),
        ).toMap();
      case UserRole.livreur:
        return CourierProfile(
          cin: cin.trim(),
          vehicleType: _vehicleType,
          plateNumber: plate.trim(),
          city: city.trim(),
        ).toMap();
      default:
        return {};
    }
  }
}
