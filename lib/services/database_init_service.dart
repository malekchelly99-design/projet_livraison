import 'package:cloud_firestore/cloud_firestore.dart';
import 'boutique_service.dart';
import 'boutique_sync_service.dart';
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
  final BoutiqueSyncService _boutiqueSyncService;

  DatabaseInitService({
    FirebaseFirestore? db,
    CatalogService? catalogService,
    OrderService? orderService,
    UserService? userService,
    BoutiqueService? boutiqueService,
    BoutiqueSyncService? boutiqueSyncService,
  })  : _db = db ?? FirebaseFirestore.instance,
        _catalogService = catalogService ?? CatalogService(),
        _orderService = orderService ?? OrderService(),
        _userService = userService ?? UserService(),
        _boutiqueService = boutiqueService ?? BoutiqueService(),
        _boutiqueSyncService = boutiqueSyncService ?? BoutiqueSyncService();

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

    // 3. Migration: Create missing boutiques for existing sellers
    try {
      await _boutiqueSyncService.migrateMissingBoutiques();
    } catch (e) {
      print('⚠️  Erreur lors de la migration des boutiques: $e');
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

