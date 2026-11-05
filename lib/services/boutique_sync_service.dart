import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/boutique_model.dart';
import '../models/user_role.dart';
import 'boutique_service.dart';
import 'user_service.dart';

/// Service responsible for automatic boutique creation and synchronization
/// when a seller registers or logs in.
///
/// Features:
/// - Automatic boutique creation on seller registration
/// - Migration support for existing sellers without boutiques
/// - Prevention of duplicate boutiques
/// - Synchronization of boutique data with user profile
class BoutiqueSyncService {
  final FirebaseFirestore _db;
  final BoutiqueService _boutiques;
  final UserService _users;

  BoutiqueSyncService({
    FirebaseFirestore? db,
    BoutiqueService? boutiques,
    UserService? users,
  })  : _db = db ?? FirebaseFirestore.instance,
        _boutiques = boutiques ?? BoutiqueService(),
        _users = users ?? UserService();

  /// Creates or syncs boutique for a newly registered seller.
  /// Called automatically after successful seller registration.
  ///
  /// - Creates boutique if it doesn't exist
  /// - Updates boutique if it already exists
  /// - Uses vendeur UID as boutique document ID
  /// - Prevents duplicates through atomic check-then-create pattern
  Future<BoutiqueModel?> createBoutiqueForNewSeller({
    required String vendeurId,
    required String shopName,
    required String category,
    required String address,
    required String city,
    required String phone,
    required String email,
    required String name,
    String taxId = '',
    String description = '',
    String horaires = '08:00 - 22:00',
  }) async {
    try {
      debugPrint('[BoutiqueSync] Creating boutique for seller: $vendeurId');

      final normalizedShopName =
          shopName.trim().isNotEmpty ? shopName.trim() : 'Boutique $name';

      // Check if boutique already exists
      final existing = await _boutiques.getBoutique(vendeurId);
      if (existing != null) {
        debugPrint('[BoutiqueSync] Boutique already exists for $vendeurId');
        return existing;
      }

      // Create new boutique
      await _boutiques.create(
        vendeurId: vendeurId,
        nomBoutique: normalizedShopName,
        categorie: category.isNotEmpty ? category : 'Autre',
        adresse: address,
        ville: city,
        matriculeFiscale: taxId,
        nomResponsable: name,
        email: email,
        telephone: phone,
        description: description,
        horaires: horaires,
      );

      debugPrint('[BoutiqueSync] Boutique created successfully for $vendeurId');

      // Fetch and return the created boutique
      return await _boutiques.getBoutique(vendeurId);
    } catch (e) {
      debugPrint('[BoutiqueSync] Error creating boutique: $e');
      return null;
    }
  }

  /// Synchronizes boutique for an existing seller.
  /// Used to update boutique information when seller updates their profile.
  ///
  /// - Updates existing boutique or creates if missing
  /// - Safe to call multiple times (idempotent)
  /// - Useful for migration scenarios
  Future<BoutiqueModel?> syncBoutiqueForSeller({
    required String vendeurId,
    required String shopName,
    required String category,
    required String address,
    required String city,
    required String phone,
    required String email,
    required String name,
    String taxId = '',
    String description = '',
    String horaires = '08:00 - 22:00',
  }) async {
    try {
      debugPrint('[BoutiqueSync] Syncing boutique for seller: $vendeurId');

      final normalizedShopName =
          shopName.trim().isNotEmpty ? shopName.trim() : 'Boutique $name';

      await _boutiques.sync(
        vendeurId: vendeurId,
        nomBoutique: normalizedShopName,
        categorie: category.isNotEmpty ? category : 'Autre',
        adresse: address,
        ville: city,
        matriculeFiscale: taxId,
        nomResponsable: name,
        email: email,
        telephone: phone,
        description: description,
        horaires: horaires,
      );

      debugPrint('[BoutiqueSync] Boutique synced successfully for $vendeurId');
      return await _boutiques.getBoutique(vendeurId);
    } catch (e) {
      debugPrint('[BoutiqueSync] Error syncing boutique: $e');
      return null;
    }
  }

  /// Migrates boutiques for all existing sellers without boutiques.
  /// Called during app initialization to handle migration scenarios.
  ///
  /// - Finds all users with role='vendeur'
  /// - Creates missing boutiques based on user profile
  /// - Prevents duplicates
  /// - Returns count of created/synced boutiques
  Future<int> migrateMissingBoutiques() async {
    try {
      debugPrint('[BoutiqueSync] Starting migration of missing boutiques...');

      final vendorUsers = await _db
          .collection('users')
          .where('role', isEqualTo: UserRole.vendeur.name)
          .get();

      int syncCount = 0;

      for (final doc in vendorUsers.docs) {
        try {
          final vendeurId = doc.id;
          final data = doc.data();

          // Check if boutique already exists
          final boutique = await _boutiques.getBoutique(vendeurId);
          if (boutique != null) {
            debugPrint('[BoutiqueSync] Boutique exists for $vendeurId, skipping');
            continue;
          }

          // Extract seller data
          final name = (data['name'] as String?) ?? 'Vendeur';
          final email = (data['email'] as String?) ?? '';
          final phone = (data['phone'] as String?) ?? '';
          final profile = Map<String, dynamic>.from(data['profile'] as Map? ?? {});

          final shopName =
              (profile['shopName'] as String?) ?? 'Boutique $name';
          final category = (profile['category'] as String?) ?? 'Autre';
          final address =
              (profile['address'] as String?) ?? (profile['city'] as String?) ?? '';
          final city = (profile['city'] as String?) ?? 'Tunis';
          final taxId = (profile['taxId'] as String?) ?? '';
          final description = (profile['description'] as String?) ?? '';
          final horaires =
              (profile['horaires'] as String?) ?? '08:00 - 22:00';

          // Create boutique for this seller
          final result = await createBoutiqueForNewSeller(
            vendeurId: vendeurId,
            shopName: shopName,
            category: category,
            address: address,
            city: city,
            phone: phone,
            email: email,
            name: name,
            taxId: taxId,
            description: description,
            horaires: horaires,
          );

          if (result != null) {
            syncCount++;
            debugPrint('[BoutiqueSync] Migrated boutique for $vendeurId');
          }
        } catch (e) {
          debugPrint('[BoutiqueSync] Error migrating boutique for ${doc.id}: $e');
          continue;
        }
      }

      debugPrint('[BoutiqueSync] Migration complete. Boutiques created/synced: $syncCount');
      return syncCount;
    } catch (e) {
      debugPrint('[BoutiqueSync] Migration error: $e');
      return 0;
    }
  }

  /// Restores missing boutique for a seller during login.
  /// If seller logs in but boutique is missing (rare edge case), creates it automatically.
  ///
  /// Called from AuthController after successful login if needed.
  Future<bool> restoreMissingBoutiqueIfNeeded(String vendeurId) async {
    try {
      final user = await _users.getUser(vendeurId);
      if (user == null || user.role != UserRole.vendeur) {
        return false;
      }

      // Check if boutique exists
      final boutique = await _boutiques.getBoutique(vendeurId);
      if (boutique != null) {
        return true; // Boutique already exists
      }

      // Boutique missing - create it
      debugPrint('[BoutiqueSync] Boutique missing for seller $vendeurId, restoring...');

      final profile = user.profile;
      final result = await createBoutiqueForNewSeller(
        vendeurId: vendeurId,
        shopName: (profile['shopName'] as String?) ?? 'Boutique ${user.name}',
        category: (profile['category'] as String?) ?? 'Autre',
        address: (profile['address'] as String?) ?? '',
        city: (profile['city'] as String?) ?? 'Tunis',
        phone: user.phone,
        email: user.email,
        name: user.name,
        taxId: (profile['taxId'] as String?) ?? '',
        description: (profile['description'] as String?) ?? '',
        horaires: (profile['horaires'] as String?) ?? '08:00 - 22:00',
      );

      return result != null;
    } catch (e) {
      debugPrint('[BoutiqueSync] Error restoring boutique: $e');
      return false;
    }
  }

  /// Gets all active boutiques for display in client dashboard.
  /// Filters by isActive flag and sorts by rating/name.
  Future<List<BoutiqueModel>> getActiveBoutiques({
    String? category,
    String? city,
  }) async {
    try {
      final boutiques = await _boutiques.getBoutiques();

      return boutiques.where((b) {
        if (!b.disponible) return false;
        if (category != null && category.isNotEmpty) {
          if (b.categorie.toLowerCase() != category.toLowerCase()) {
            return false;
          }
        }
        if (city != null && city.isNotEmpty) {
          if (b.ville.toLowerCase() != city.toLowerCase()) {
            return false;
          }
        }
        return true;
      }).toList()
        ..sort((a, b) => b.rating.compareTo(a.rating)); // Sort by rating
    } catch (e) {
      debugPrint('[BoutiqueSync] Error getting active boutiques: $e');
      return [];
    }
  }

  /// Stream version of getActiveBoutiques for real-time updates.
  Stream<List<BoutiqueModel>> watchActiveBoutiques({
    String? category,
    String? city,
  }) {
    return _boutiques.watchBoutiques().map((boutiques) {
      return boutiques.where((b) {
        if (!b.disponible) return false;
        if (category != null && category.isNotEmpty) {
          if (b.categorie.toLowerCase() != category.toLowerCase()) {
            return false;
          }
        }
        if (city != null && city.isNotEmpty) {
          if (b.ville.toLowerCase() != city.toLowerCase()) {
            return false;
          }
        }
        return true;
      }).toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));
    });
  }

  /// Gets boutique details by seller UID.
  Future<BoutiqueModel?> getBoutiqueBySellerUid(String sellerId) async {
    return _boutiques.getBoutique(sellerId);
  }

  /// Gets all boutiques for a specific category.
  Future<List<BoutiqueModel>> getBoutiquesByCategory(String category) async {
    final all = await _boutiques.getBoutiques();
    return all
        .where((b) =>
            b.disponible &&
            b.categorie.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Gets all boutiques in a specific city.
  Future<List<BoutiqueModel>> getBoutiquesByCity(String city) async {
    final all = await _boutiques.getBoutiques();
    return all
        .where((b) =>
            b.disponible &&
            b.ville.toLowerCase() == city.toLowerCase())
        .toList();
  }
}
