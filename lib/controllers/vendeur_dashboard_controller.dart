import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/category_model.dart';
import '../models/order_model.dart';
import '../models/product.dart';
import '../services/boutique_service.dart';
import '../services/catalog_service.dart';
import '../services/notification_service.dart';
import '../services/order_service.dart';
import '../services/user_service.dart';
import '../utils/category_matcher.dart';
import 'base_controller.dart';

class VendeurDashboardController extends BaseController {
  final AppUser user;
  final CatalogService _catalogService;
  final OrderService _orderService;
  final UserService _userService;
  final BoutiqueService _boutiqueService;

  StreamSubscription<List<Product>>? _productsSub;
  StreamSubscription<List<OrderModel>>? _ordersSub;
  StreamSubscription<List<CategoryModel>>? _categoriesSub;

  // Catégories dynamiques depuis Firestore
  List<CategoryModel> _firestoreCategories = [];
  List<CategoryModel> get firestoreCategories => _firestoreCategories;

  /// Noms des catégories disponibles (incluant "Tous" en premier)
  List<String> get categoryNames {
    final Set<String> namesSet = {'Tous'};
    for (final c in _firestoreCategories) {
      if (c.name.trim().isNotEmpty) {
        namesSet.add(c.name.trim());
      }
    }
    for (final p in _products) {
      if (p.category.trim().isNotEmpty) {
        namesSet.add(p.category.trim());
      }
    }
    if (namesSet.length == 1) {
      namesSet.addAll(CategoryMatcher.defaultCategoryNames);
    }
    return namesSet.toList();
  }

  /// Noms des catégories sans "Tous" (pour le formulaire produit)
  List<String> get productCategoryNames {
    final Set<String> names = {};
    for (final c in _firestoreCategories) {
      if (c.name.trim().isNotEmpty && c.name.trim().toLowerCase() != 'tous') {
        names.add(c.name.trim());
      }
    }
    for (final p in _products) {
      if (p.category.trim().isNotEmpty && p.category.trim().toLowerCase() != 'tous') {
        names.add(p.category.trim());
      }
    }
    if (names.isEmpty) {
      return CategoryMatcher.defaultCategoryNames;
    }
    return names.toList();
  }

  int _currentTab = 0;
  int get currentTab => _currentTab;

  List<Product> _products = [];
  List<Product> get products => _products;

  List<OrderModel> _orders = [];
  List<OrderModel> get orders => _orders;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Filtres catalogue
  String _selectedCategory = 'Tous';
  String get selectedCategory => _selectedCategory;

  String _productSearchQuery = '';
  String get productSearchQuery => _productSearchQuery;

  // Filtre commandes
  OrderStatus? _selectedOrderStatus;
  OrderStatus? get selectedOrderStatus => _selectedOrderStatus;

  String _orderSearchQuery = '';
  String get orderSearchQuery => _orderSearchQuery;

  // Statut boutique
  bool _isOpen = true;
  bool get isOpen => _isOpen;

  VendeurDashboardController({
    required this.user,
    CatalogService? catalogService,
    OrderService? orderService,
    UserService? userService,
    BoutiqueService? boutiqueService,
  })  : _catalogService = catalogService ?? CatalogService(),
        _orderService = orderService ?? OrderService(),
        _userService = userService ?? UserService(),
        _boutiqueService = boutiqueService ?? BoutiqueService() {
    _initSubscriptions();
    _initCategories();
  }

  String get shopName => (user.profile['shopName'] as String?)?.trim().isNotEmpty == true
      ? (user.profile['shopName'] as String).trim()
      : (user.name.isNotEmpty ? 'Boutique ${user.name}' : 'Ma Boutique');

  String get shopCategory => (user.profile['category'] as String?) ?? 'Général';
  String get shopAddress => (user.profile['address'] as String?) ?? '';
  String get shopCity => (user.profile['city'] as String?) ?? '';
  String get shopTaxId => (user.profile['taxId'] as String?) ?? '';

  void _initSubscriptions() {
    _isLoading = true;
    notifyListeners();

    // S'assure que la fiche existe dans la collection `boutiques`
    _boutiqueService.sync(
      vendeurId: user.uid,
      nomBoutique: shopName,
      categorie: shopCategory,
      adresse: shopAddress,
      ville: shopCity,
      matriculeFiscale: shopTaxId,
      nomResponsable: user.name,
      email: user.email,
      telephone: user.phone,
    ).catchError((e) {
      debugPrint('Sync boutique error: $e');
    });

    // Assurer qu'une notification de bienvenue existe pour ce vendeur
    NotificationService().ensureWelcomeNotification(
      userId: user.uid,
      userName: shopName,
      isVendor: true,
    );

    _productsSub = _catalogService
        .watchVendorProducts(shopName: shopName, vendorId: user.uid)
        .listen(
      (list) {
        if (list.isNotEmpty || _products.isEmpty) {
          _products = list;
          _isLoading = false;
          notifyListeners();
          // Ré-abonnement commandes avec la liste actualisée des IDs de produits
          _subscribeOrders();
        }
      },
      onError: (err) {
        debugPrint('[VendeurController] Erreur produits: $err');
        _isLoading = false;
        notifyListeners();
      },
    );

    _subscribeOrders();
  }

  void _subscribeOrders() {
    _ordersSub?.cancel();
    final productIds = _products.map((p) => p.id).toSet();

    _ordersSub = _orderService
        .watchVendorOrders(shopName, vendorProductIds: productIds)
        .listen(
      (list) {
        if (list.isNotEmpty || _orders.isEmpty) {
          _orders = list;
          notifyListeners();
        }
      },
      onError: (err) {
        debugPrint('[VendeurController] Erreur commandes: $err');
      },
    );
  }

  void setTab(int index) {
    if (_currentTab != index) {
      _currentTab = index;
      notifyListeners();
    }
  }

  void _initCategories() {
    _categoriesSub = _catalogService.watchCategories().listen(
      (list) {
        _firestoreCategories = list;
        notifyListeners();
      },
      onError: (err) {
        debugPrint('[VendeurController] Erreur catégories: $err');
      },
    );
    // S'assurer que les catégories par défaut existent dans Firestore
    _catalogService.ensureDefaultCategories().catchError((e) {
      debugPrint('[VendeurController] ensureDefaultCategories error: $e');
    });
  }

  /// Ajoute une nouvelle catégorie si elle n'existe pas déjà.
  Future<String?> addNewCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Le nom de la catégorie est requis.';
    try {
      await _catalogService.addCategoryIfNotExists(trimmed);
      return null; // succès
    } catch (e) {
      return 'Erreur lors de l\'ajout de la catégorie : $e';
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setProductSearch(String query) {
    _productSearchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void setOrderStatusFilter(OrderStatus? status) {
    _selectedOrderStatus = status;
    notifyListeners();
  }

  void setOrderSearchQuery(String query) {
    _orderSearchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void toggleShopOpen(bool value) {
    _isOpen = value;
    notifyListeners();
    // Garde le champ `disponible` de la collection `boutiques` à jour.
    _boutiqueService.setDisponible(user.uid, value).catchError((e) {
      _errorMessage = 'Impossible de mettre à jour la disponibilité : $e';
      notifyListeners();
    });
  }

  // --- STATS / KPI ---
  double get totalRevenue {
    return _orders
        .where((o) => o.status == OrderStatus.delivered)
        .fold(0.0, (sum, o) => sum + o.total);
  }

  int get pendingOrdersCount {
    return _orders
        .where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.preparing)
        .length;
  }

  int get deliveringOrdersCount {
    return _orders.where((o) =>
        o.status == OrderStatus.delivering ||
        o.status == OrderStatus.assigned ||
        o.status == OrderStatus.pickedUp ||
        o.status == OrderStatus.ready).length;
  }

  int get completedOrdersCount {
    return _orders.where((o) => o.status == OrderStatus.delivered).length;
  }

  List<Product> get filteredProducts {
    return _products.where((p) {
      final matchesCat = CategoryMatcher.matches(p.category, _selectedCategory);
      final matchesSearch = _productSearchQuery.isEmpty ||
          p.name.toLowerCase().contains(_productSearchQuery) ||
          p.description.toLowerCase().contains(_productSearchQuery) ||
          p.category.toLowerCase().contains(_productSearchQuery);
      return matchesCat && matchesSearch;
    }).toList();
  }

  List<OrderModel> get filteredOrders {
    List<OrderModel> list = _orders;
    if (_selectedOrderStatus != null) {
      list = list.where((o) {
        if (_selectedOrderStatus == OrderStatus.delivering) {
          return o.status == OrderStatus.delivering ||
              o.status == OrderStatus.assigned ||
              o.status == OrderStatus.pickedUp;
        }
        return o.status == _selectedOrderStatus;
      }).toList();
    }
    if (_orderSearchQuery.isNotEmpty) {
      final q = _orderSearchQuery;
      list = list.where((o) {
        return o.id.toLowerCase().contains(q) ||
            o.clientName.toLowerCase().contains(q) ||
            o.clientPhone.toLowerCase().contains(q) ||
            o.deliveryAddress.toLowerCase().contains(q) ||
            o.items.any((item) => item.name.toLowerCase().contains(q));
      }).toList();
    }
    return list;
  }

  // --- OPÉRATIONS PRODUITS ---
  Future<bool> addProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    required int deliveryTimeMinutes,
    required bool isPopular,
    required String imageUrl,
  }) async {
    try {
      final newProduct = Product(
        id: '',
        name: name,
        description: description,
        price: price,
        category: category,
        shopName: shopName,
        rating: 5.0,
        deliveryTimeMinutes: deliveryTimeMinutes,
        isPopular: isPopular,
        imageUrl: imageUrl,
        vendorId: user.uid,
      );

      await _catalogService.addProduct(newProduct);
      return true;
    } catch (e) {
      _errorMessage = 'Échec de l\'ajout du produit : $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct({
    required String id,
    required String name,
    required String description,
    required double price,
    required String category,
    required int deliveryTimeMinutes,
    required bool isPopular,
    required String imageUrl,
  }) async {
    try {
      final updatedProduct = Product(
        id: id,
        name: name,
        description: description,
        price: price,
        category: category,
        shopName: shopName,
        deliveryTimeMinutes: deliveryTimeMinutes,
        isPopular: isPopular,
        imageUrl: imageUrl,
        vendorId: user.uid,
      );

      await _catalogService.updateProduct(updatedProduct);
      return true;
    } catch (e) {
      _errorMessage = 'Échec de la mise à jour : $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _catalogService.deleteProduct(productId);
      return true;
    } catch (e) {
      _errorMessage = 'Échec de la suppression : $e';
      notifyListeners();
      return false;
    }
  }

  // --- OPÉRATIONS COMMANDES ---
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      await _orderService.updateStatus(orderId, newStatus);
      // Notifier le client du changement de statut en temps réel
      try {
        final order = _orders.firstWhere((o) => o.id == orderId);
        if (order.clientId.isNotEmpty) {
          await NotificationService().notifyClientOrderStatus(
            clientId: order.clientId,
            orderId: orderId,
            status: newStatus,
            shopName: shopName,
          );
        }
      } catch (_) {}
      return true;
    } catch (e) {
      _errorMessage = 'Échec de la mise à jour du statut : $e';
      notifyListeners();
      return false;
    }
  }

  // --- MISE À JOUR PROFIL BOUTIQUE ---
  Future<bool> updateShopProfile({
    required String newShopName,
    required String newCategory,
    required String newAddress,
    required String newCity,
    required String newTaxId,
  }) async {
    try {
      final updatedProfile = {
        'shopName': newShopName,
        'category': newCategory,
        'address': newAddress,
        'city': newCity,
        'taxId': newTaxId,
      };

      await _userService.updateProfile(user.uid, {'profile': updatedProfile});
      await _boutiqueService.sync(
        vendeurId: user.uid,
        nomBoutique: newShopName,
        categorie: newCategory,
        adresse: newAddress,
        ville: newCity,
        matriculeFiscale: newTaxId,
        nomResponsable: user.name,
        email: user.email,
        telephone: user.phone,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour : $e';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    _ordersSub?.cancel();
    _categoriesSub?.cancel();
    super.dispose();
  }
}
