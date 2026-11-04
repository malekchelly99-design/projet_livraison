import 'package:cloud_firestore/cloud_firestore.dart';
import 'boutique_service.dart';
import 'catalog_service.dart';
import 'order_service.dart';
import 'user_service.dart';

/// Service d'initialisation et d'intégrité des tables (collections) Firestore.
class DatabaseInitService {
  final FirebaseFirestore _db;
  final CatalogService _catalogService;
  final OrderService _orderService;
  final UserService _userService;
  final BoutiqueService _boutiqueService;

  DatabaseInitService({
    FirebaseFirestore? db,
    CatalogService? catalogService,
    OrderService? orderService,
    UserService? userService,
    BoutiqueService? boutiqueService,
  })  : _db = db ?? FirebaseFirestore.instance,
        _catalogService = catalogService ?? CatalogService(),
        _orderService = orderService ?? OrderService(),
        _userService = userService ?? UserService(),
        _boutiqueService = boutiqueService ?? BoutiqueService();

  /// Initialise la structure des tables nécessaires dans Firestore si elles sont vides.
  Future<void> initializeTables() async {
    // 1. Initialisation de la table / collection 'categories'
    await _catalogService.ensureDefaultCategories();

    // 2. Initialisation de la table / collection 'settings'
    final settingsDoc = _db.collection('settings').doc('platform');
    final snap = await settingsDoc.get();
    if (!snap.exists) {
      await settingsDoc.set({
        'appName': 'Livraison Rapide',
        'baseDeliveryFee': 4.5,
        'platformCommissionRate': 0.10,
        'currency': 'DT',
        'supportPhone': '+216 71 000 000',
        'isMaintenance': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // 3. Synchronisation de la collection 'boutiques' pour tout vendeur existant
    try {
      final vendorUsers = await _db.collection('users').where('role', isEqualTo: 'vendeur').get();
      for (final doc in vendorUsers.docs) {
        final data = doc.data();
        final boutiqueDoc = await _db.collection('boutiques').doc(doc.id).get();
        if (!boutiqueDoc.exists) {
          final profile = Map<String, dynamic>.from(data['profile'] as Map? ?? {});
          await _boutiqueService.create(
            vendeurId: doc.id,
            nomBoutique: (profile['shopName'] as String?) ?? (data['name'] as String?) ?? 'Boutique',
            categorie: (profile['category'] as String?) ?? 'Restaurant',
            adresse: (profile['address'] as String?) ?? (profile['city'] as String?) ?? 'Tunis',
            ville: (profile['city'] as String?) ?? 'Tunis',
            matriculeFiscale: (profile['taxId'] as String?) ?? '',
            nomResponsable: (data['name'] as String?) ?? '',
            email: (data['email'] as String?) ?? '',
            telephone: (data['phone'] as String?) ?? '',
            description: (profile['description'] as String?) ?? '',
            horaires: (profile['horaires'] as String?) ?? '08:00 - 22:00',
          );
        }
      }
    } catch (_) {
      // Ignorer si pas encore authentifié au démarrage
    }
  }

  /// Purge définitivement toutes les données de test / démo de la base de données.
  Future<String> purgeAllDemoData() async {
    final ordersCount = await _orderService.purgeDemoOrders();
    final usersCount = await _userService.purgeDemoUsers();
    final productsCount = await _catalogService.purgeDemoProducts();

    return '$ordersCount commande(s), $usersCount utilisateur(s) et $productsCount produit(s) démo nettoyés avec succès.';
  }
}

