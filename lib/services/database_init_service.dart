import 'package:cloud_firestore/cloud_firestore.dart';
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
  final BoutiqueSyncService _boutiqueSyncService;

  DatabaseInitService({
    FirebaseFirestore? db,
    CatalogService? catalogService,
    OrderService? orderService,
    UserService? userService,
    BoutiqueSyncService? boutiqueSyncService,
  })  : _db = db ?? FirebaseFirestore.instance,
        _catalogService = catalogService ?? CatalogService(),
        _orderService = orderService ?? OrderService(),
        _userService = userService ?? UserService(),
        _boutiqueSyncService = boutiqueSyncService ?? BoutiqueSyncService();

  /// Initialise la structure des tables nécessaires dans Firestore si elles sont vides.
  Future<void> initializeTables() async {
    try {
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
      await _boutiqueSyncService.migrateMissingBoutiques();

      // 4. Initialisation de la table 'notifications' pour qu'elle soit visible dans la console Firebase
      await ensureNotificationsTable();
    } catch (e) {
      // Silencieux au démarrage si l'utilisateur n'est pas encore connecté
      print('ℹ️  Initialisation Firestore (différée après connexion): $e');
    }
  }

  /// S'assure que la collection 'notifications' existe et est visible dans Firestore.
  Future<void> ensureNotificationsTable() async {
    try {
      final notifsSnap = await _db.collection('notifications').limit(1).get();
      if (notifsSnap.docs.isEmpty) {
        await _db.collection('notifications').doc('init_welcome').set({
          'userId': 'system',
          'title': '🔔 Bienvenue sur Livraison Rapide !',
          'message': 'Le système de notifications en temps réel est actif.',
          'type': 'info',
          'isRead': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  /// Purge définitivement toutes les données de test / démo de la base de données.
  Future<String> purgeAllDemoData() async {
    final ordersCount = await _orderService.purgeDemoOrders();
    final usersCount = await _userService.purgeDemoUsers();
    final productsCount = await _catalogService.purgeDemoProducts();

    return '$ordersCount commande(s), $usersCount utilisateur(s) et $productsCount produit(s) démo nettoyés avec succès.';
  }
}

