import 'dart:async';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/category_model.dart';
import '../models/courier_location.dart';
import '../models/order_model.dart';
import '../models/product.dart';
import '../services/boutique_service.dart';
import '../services/catalog_service.dart';
import '../services/location_tracking_service.dart';
import '../services/order_service.dart';
import '../services/user_service.dart';
import '../utils/route_coordinates_helper.dart';
import 'base_controller.dart';

class ClientDashboardController extends BaseController {
  final CatalogService _catalogService;
  final OrderService _orderService;
  final UserService _userService;
  final LocationTrackingService _trackingService;
  final BoutiqueService _boutiqueService;

  ClientDashboardController({
    CatalogService? catalogService,
    OrderService? orderService,
    UserService? userService,
    LocationTrackingService? trackingService,
    BoutiqueService? boutiqueService,
  })  : _catalogService = catalogService ?? CatalogService(),
        _orderService = orderService ?? OrderService(),
        _userService = userService ?? UserService(),
        _trackingService = trackingService ?? LocationTrackingService(),
        _boutiqueService = boutiqueService ?? BoutiqueService() {
    _initCatalog();
    _initCategories();
  }

  // --- NAVIGATION ONGLETS ---
  // 0: Accueil/Dashboard, 1: Catalogue & Produits, 2: Boutiques, 3: Panier/Checkout, 4: Commandes, 5: Profil
  int _currentTab = 0;
  int get currentTab => _currentTab;

  void setTab(int index) {
    if (_currentTab != index) {
      _currentTab = index;
      notifyListeners();
    }
  }

  // --- CATÉGORIES DYNAMIQUES DEPUIS FIRESTORE ---
  List<CategoryModel> _firestoreCategories = [];
  StreamSubscription<List<CategoryModel>>? _categoriesSub;

  List<CategoryModel> get firestoreCategories => _firestoreCategories;

  /// Renvoie les catégories pour la vue catalogue (avec "Tous" en tête)
  List<Map<String, dynamic>> get dynamicCategories {
    final List<Map<String, dynamic>> result = [
      {'name': 'Tous', 'icon': Icons.apps},
    ];
    for (final cat in _firestoreCategories) {
      result.add({'name': cat.name, 'icon': _iconForCategory(cat.icon)});
    }
    return result;
  }

  IconData _iconForCategory(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'restaurant': return Icons.restaurant;
      case 'local_pizza': return Icons.local_pizza;
      case 'local_grocery_store': return Icons.local_grocery_store;
      case 'bakery_dining': return Icons.bakery_dining;
      case 'local_cafe': return Icons.local_cafe;
      case 'local_pharmacy': return Icons.local_pharmacy;
      case 'fastfood': return Icons.fastfood;
      case 'lunch_dining': return Icons.lunch_dining;
      case 'dinner_dining': return Icons.dinner_dining;
      case 'icecream': return Icons.icecream;
      case 'emoji_food_beverage': return Icons.emoji_food_beverage;
      default: return Icons.category;
    }
  }

  void _initCategories() {
    _categoriesSub = _catalogService.watchCategories().listen(
      (list) {
        _firestoreCategories = list;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[ClientController] Erreur catégories: $e');
      },
    );
  }

  // --- CATALOGUE ET FILTRES ---
  List<Product> _allProducts = CatalogService.defaultProducts;
  StreamSubscription<List<Product>>? _catalogSub;
  String _selectedCategory = 'Tous';
  String? _selectedShopName;
  String _searchQuery = '';

  String get selectedCategory => _selectedCategory;
  String? get selectedShopName => _selectedShopName;
  String get searchQuery => _searchQuery;

  void _initCatalog() {
    _catalogSub = _catalogService.watchProducts().listen(
      (list) {
        // Ne pas effacer la liste si des produits étaient déjà affichés
        // lors d'un événement transitoire de reconnexion
        if (list.isNotEmpty || _allProducts.isEmpty) {
          _allProducts = list;
          notifyListeners();
        }
      },
      onError: (e) {
        debugPrint('[ClientController] Erreur catalogue: $e');
      },
    );
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSelectedShop(String? shopName) {
    _selectedShopName = shopName;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  List<Product> get filteredProducts {
    return _allProducts.where((p) {
      final matchesCategory =
          _selectedCategory == 'Tous' || _selectedCategory == 'Toutes' || p.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesShop = _selectedShopName == null ||
          _selectedShopName!.isEmpty ||
          p.shopName.toLowerCase() == _selectedShopName!.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery) ||
          p.description.toLowerCase().contains(_searchQuery) ||
          p.shopName.toLowerCase().contains(_searchQuery);
      return matchesCategory && matchesShop && matchesSearch;
    }).toList();
  }

  List<Product> get popularProducts =>
      _allProducts.where((p) => p.isPopular).toList();

  /// Regroupe tous les produits par boutique (nom de la boutique)
  Map<String, List<Product>> get productsByShop {
    final Map<String, List<Product>> map = {};
    for (final p in _allProducts) {
      final name = p.shopName.trim().isNotEmpty ? p.shopName.trim() : 'Boutique Partenaire';
      map.putIfAbsent(name, () => []).add(p);
    }
    return map;
  }

  /// Liste de tous les noms de boutiques ayant des plats au catalogue
  List<String> get availableShops => productsByShop.keys.toList();

  /// Renvoie pour chaque boutique ses meilleurs plats triés :
  /// 1. Plats populaires (isPopular) en priorité
  /// 2. Plats avec la meilleure note (rating)
  /// 3. Plats les plus abordables
  Map<String, List<Product>> get bestDishesByShop {
    final grouped = productsByShop;
    final Map<String, List<Product>> result = {};

    for (final entry in grouped.entries) {
      final list = List<Product>.from(entry.value);
      list.sort((a, b) {
        if (a.isPopular && !b.isPopular) return -1;
        if (!a.isPopular && b.isPopular) return 1;
        final ratingCmp = b.rating.compareTo(a.rating);
        if (ratingCmp != 0) return ratingCmp;
        return a.price.compareTo(b.price);
      });
      result[entry.key] = list;
    }
    return result;
  }

  // --- GESTION DU PANIER ---
  final Map<String, CartItem> _cart = {};

  List<CartItem> get cartItems => _cart.values.toList();
  int get totalItemCount =>
      _cart.values.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _cart.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get deliveryFee => _cart.isEmpty ? 0.0 : 4.5;

  String? _appliedPromo;
  String? get appliedPromo => _appliedPromo;
  double _discountPercentage = 0.0;

  double get discountAmount => subtotal * _discountPercentage;

  double get total =>
      (subtotal - discountAmount + deliveryFee).clamp(0.0, double.infinity);

  void addToCart(Product product) {
    if (_cart.containsKey(product.id)) {
      _cart[product.id]!.quantity += 1;
    } else {
      _cart[product.id] = CartItem(product: product, quantity: 1);
    }
    notifyListeners();
  }

  void incrementQuantity(Product product) {
    addToCart(product);
  }

  void decrementQuantity(Product product) {
    if (!_cart.containsKey(product.id)) return;
    if (_cart[product.id]!.quantity > 1) {
      _cart[product.id]!.quantity -= 1;
    } else {
      _cart.remove(product.id);
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cart.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _appliedPromo = null;
    _discountPercentage = 0.0;
    notifyListeners();
  }

  bool applyPromo(String code) {
    final clean = code.trim().toUpperCase();
    if (clean == 'BIENVENUE' || clean == 'PROMO20') {
      _appliedPromo = clean;
      _discountPercentage = 0.20; // 20% discount
      notifyListeners();
      return true;
    } else if (clean == 'LIVRAISON') {
      _appliedPromo = clean;
      _discountPercentage = 0.10; // 10% discount
      notifyListeners();
      return true;
    }
    return false;
  }

  // --- PROCESSUS DE COMMANDE (CHECKOUT) ---
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();
  String selectedPaymentMethod = 'Paiement en espèces à la livraison';

  bool _isSubmittingOrder = false;
  bool get isSubmittingOrder => _isSubmittingOrder;

  void initUserInfo(AppUser user) {
    if (addressCtrl.text.isEmpty) {
      final userAddress = (user.profile['address'] as String?) ??
          (user.profile['city'] as String?) ??
          '';
      if (userAddress.isNotEmpty) {
        addressCtrl.text = userAddress;
      }
    }
    if (phoneCtrl.text.isEmpty && user.phone.isNotEmpty) {
      phoneCtrl.text = user.phone;
    }
  }

  Future<String?> placeOrder(AppUser user) async {
    if (_cart.isEmpty) {
      return 'Votre panier est vide.';
    }

    final address = addressCtrl.text.trim();
    if (address.isEmpty) {
      return 'Veuillez renseigner votre adresse de livraison.';
    }

    final phone = phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : user.phone;
    if (phone.isEmpty) {
      return 'Veuillez renseigner un numéro de téléphone pour le livreur.';
    }

    _isSubmittingOrder = true;
    notifyListeners();

    try {
      final firstProduct = _cart.values.isNotEmpty ? _cart.values.first.product : null;
      final vendorName = firstProduct?.shopName ?? '';
      final vendorUid = firstProduct?.vendorId ?? firstProduct?.boutiqueId ?? '';

      String vendorAddress = '';
      String vendorPhone = '';

      if (vendorUid.isNotEmpty) {
        try {
          final b = await _boutiqueService.getBoutique(vendorUid);
          if (b != null) {
            vendorAddress = b.adresse.isNotEmpty
                ? (b.ville.isNotEmpty ? '${b.adresse}, ${b.ville}' : b.adresse)
                : b.ville;
            vendorPhone = b.telephone;
          }
        } catch (_) {}
      }

      final clientCoords = RouteCoordinatesHelper.resolveAddress(address);
      final vendorCoords = RouteCoordinatesHelper.resolveAddress(
          vendorAddress.isNotEmpty ? vendorAddress : vendorName);

      final order = OrderModel(
        id: '',
        clientId: user.uid,
        clientName: user.name.isNotEmpty ? user.name : 'Client',
        clientPhone: phone,
        deliveryAddress: address,
        vendorName: vendorName,
        vendorAddress: vendorAddress,
        vendorPhone: vendorPhone,
        items: _cart.values
            .map((item) => OrderItem(
                  productId: item.product.id,
                  name: item.product.name,
                  price: item.product.price,
                  quantity: item.quantity,
                  shopName: item.product.shopName,
                ))
            .toList(),
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        discount: discountAmount,
        total: total,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        paymentMethod: selectedPaymentMethod,
        notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
        vendorLatitude: vendorCoords?.latitude,
        vendorLongitude: vendorCoords?.longitude,
        clientLatitude: clientCoords?.latitude,
        clientLongitude: clientCoords?.longitude,
      );

      await _orderService.createOrder(order);

      clearCart();
      notesCtrl.clear();
      _isSubmittingOrder = false;
      return null;
    } catch (e) {
      _isSubmittingOrder = false;
      notifyListeners();
      return 'Erreur lors de la commande: $e';
    }
  }

  // --- SUIVI DES COMMANDES ET GÉOLOCALISATION ---
  Stream<List<OrderModel>> watchOrders(String clientId) {
    return _orderService.watchClientOrders(clientId);
  }

  /// Écoute la position GPS en temps réel du livreur pour une commande spécifique
  Stream<CourierLocation?> watchCourierLocation(String orderId) {
    return _trackingService.watchCourierLocation(orderId);
  }

  Future<void> cancelOrder(String orderId) async {
    await _orderService.updateStatus(orderId, OrderStatus.cancelled);
  }

  // --- PROFIL ---
  Future<bool> updateProfile(String uid, {
    required String name,
    required String phone,
    required String address,
    required String city,
  }) async {
    try {
      await _userService.updateProfile(uid, {
        'name': name,
        'phone': phone,
        'profile.address': address,
        'profile.city': city,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _catalogSub?.cancel();
    _categoriesSub?.cancel();
    addressCtrl.dispose();
    phoneCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }
}
