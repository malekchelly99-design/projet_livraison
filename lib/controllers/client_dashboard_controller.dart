import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/app_user.dart';
import '../models/category_model.dart';
import '../models/courier_location.dart';
import '../models/notification_model.dart';
import '../models/order_model.dart';
import '../models/product.dart';
import '../services/boutique_service.dart';
import '../services/catalog_service.dart';
import '../services/location_tracking_service.dart';
import '../services/notification_service.dart';
import '../services/order_service.dart';
import '../services/user_service.dart';
import '../utils/category_matcher.dart';
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
    final Set<String> seen = {'tous'};

    // 1. Catégories depuis Firestore
    for (final cat in _firestoreCategories) {
      final name = cat.name.trim();
      if (name.isNotEmpty && !seen.contains(name.toLowerCase())) {
        seen.add(name.toLowerCase());
        result.add({
          'name': name,
          'icon': CategoryMatcher.iconForCategory(cat.icon.isNotEmpty ? cat.icon : cat.name),
        });
      }
    }

    // 2. Catégories réelles des produits ajoutés par les vendeurs
    for (final p in _allProducts) {
      final cat = p.category.trim();
      if (cat.isNotEmpty && !seen.contains(cat.toLowerCase())) {
        bool alreadyCovered = false;
        for (final s in seen) {
          if (CategoryMatcher.matches(cat, s)) {
            alreadyCovered = true;
            break;
          }
        }
        if (!alreadyCovered) {
          seen.add(cat.toLowerCase());
          result.add({
            'name': cat,
            'icon': CategoryMatcher.iconForCategory(cat),
          });
        }
      }
    }

    // 3. Fallback standard si Firestore est vide
    if (result.length == 1) {
      for (final defCat in CategoryMatcher.defaultCategoryNames) {
        if (!seen.contains(defCat.toLowerCase())) {
          seen.add(defCat.toLowerCase());
          result.add({
            'name': defCat,
            'icon': CategoryMatcher.iconForCategory(defCat),
          });
        }
      }
    }

    return result;
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
    // S'assurer que les catégories par défaut existent dans Firestore
    _catalogService.ensureDefaultCategories().catchError((e) {
      debugPrint('[ClientController] ensureDefaultCategories error: $e');
    });
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
      final matchesCategory = CategoryMatcher.matches(p.category, _selectedCategory);
      final matchesShop = _selectedShopName == null ||
          _selectedShopName!.trim().isEmpty ||
          p.shopName.trim().toLowerCase() == _selectedShopName!.trim().toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery) ||
          p.description.toLowerCase().contains(_searchQuery) ||
          p.category.toLowerCase().contains(_searchQuery) ||
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
      _cart.values.fold(0, (acc, item) => acc + item.quantity);

  double get subtotal =>
      _cart.values.fold(0.0, (acc, item) => acc + item.totalPrice);

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

  LatLng? _clientDeviceLocation;
  LatLng? get clientDeviceLocation => _clientDeviceLocation;

  bool _isLocating = false;
  bool get isLocating => _isLocating;

  /// Récupère la position GPS réelle du client sur son appareil (téléphone ou PC)
  Future<LatLng?> fetchClientPosition({bool updateAddressText = false}) async {
    _isLocating = true;
    notifyListeners();
    try {
      final pos = await _trackingService.getCurrentPosition();
      if (pos != null) {
        _clientDeviceLocation = LatLng(pos.latitude, pos.longitude);
        if (updateAddressText) {
          addressCtrl.text = 'Position GPS (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})';
        }
        notifyListeners();
        return _clientDeviceLocation;
      }
    } catch (e) {
      debugPrint('[ClientDashboardController] Erreur récupération GPS client: $e');
    } finally {
      _isLocating = false;
      notifyListeners();
    }
    return null;
  }

  /// Synchronise automatiquement la position GPS du client sur une commande existante si elle était manquante
  Future<void> syncOrderClientLocation(OrderModel order) async {
    if (order.clientLatitude != null &&
        order.clientLongitude != null &&
        order.clientLatitude != 0.0) {
      return;
    }
    if (_clientDeviceLocation == null) {
      await fetchClientPosition();
    }
    if (_clientDeviceLocation != null) {
      try {
        await FirebaseFirestore.instance.collection('orders').doc(order.id).update({
          'clientLatitude': _clientDeviceLocation!.latitude,
          'clientLongitude': _clientDeviceLocation!.longitude,
        });
        debugPrint('[ClientDashboardController] Commande ${order.id} synchronisée avec GPS client: ${_clientDeviceLocation!.latitude}, ${_clientDeviceLocation!.longitude}');
      } catch (e) {
        debugPrint('[ClientDashboardController] Erreur syncOrderClientLocation: $e');
      }
    }
  }

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

    // Assurer qu'une notification de bienvenue existe pour ce client
    NotificationService().ensureWelcomeNotification(
      userId: user.uid,
      userName: user.name.isNotEmpty ? user.name : 'Client',
      isVendor: false,
    );

    // Détecter la position GPS de l'appareil en arrière-plan
    fetchClientPosition();
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
      String vendorUid = firstProduct?.vendorId ?? firstProduct?.boutiqueId ?? '';

      // Recherche de vendorUid dans tous les articles du panier
      if (vendorUid.isEmpty) {
        for (final item in _cart.values) {
          final id = item.product.vendorId ?? item.product.boutiqueId;
          if (id != null && id.trim().isNotEmpty) {
            vendorUid = id.trim();
            break;
          }
        }
      }

      // Si vendorUid n'est pas renseigné sur le produit, le retrouver via le nom de la boutique ou les utilisateurs
      if (vendorUid.isEmpty && vendorName.isNotEmpty) {
        try {
          // 1. Recherche dans 'boutiques' par nomBoutique
          final snap = await FirebaseFirestore.instance
              .collection('boutiques')
              .where('nomBoutique', isEqualTo: vendorName)
              .limit(1)
              .get();
          if (snap.docs.isNotEmpty) {
            vendorUid = (snap.docs.first.data()['vendeurId'] as String?) ?? snap.docs.first.id;
          } else {
            // 2. Recherche dans 'boutiques' par shopName
            final snapShop = await FirebaseFirestore.instance
                .collection('boutiques')
                .where('shopName', isEqualTo: vendorName)
                .limit(1)
                .get();
            if (snapShop.docs.isNotEmpty) {
              vendorUid = (snapShop.docs.first.data()['vendeurId'] as String?) ?? snapShop.docs.first.id;
            }
          }

          // 3. Recherche dans 'users' où role == 'vendeur'
          if (vendorUid.isEmpty) {
            final userSnap = await FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'vendeur')
                .get();
            for (final d in userSnap.docs) {
              final prof = d.data()['profile'] as Map? ?? {};
              final sName = (prof['shopName'] ?? prof['nomBoutique'] ?? d.data()['name'] ?? '') as String;
              if (sName.trim().toLowerCase() == vendorName.trim().toLowerCase()) {
                vendorUid = d.id;
                break;
              }
            }
            // Fallback : si un vendeur existe dans la base, on lui assigne la commande
            if (vendorUid.isEmpty && userSnap.docs.isNotEmpty) {
              vendorUid = userSnap.docs.first.id;
            }
          }
        } catch (e) {
          debugPrint('[ClientDashboardController] Erreur recherche vendor: $e');
        }
      }

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

      // ── Position GPS réelle du client ──
      // Priorité 1: Position GPS déjà détectée sur cet appareil (téléphone ou PC)
      double? clientLat = _clientDeviceLocation?.latitude;
      double? clientLng = _clientDeviceLocation?.longitude;

      // Priorité 2: Requête GPS en direct si pas encore en cache
      if (clientLat == null || clientLng == null) {
        try {
          final pos = await _trackingService.getCurrentPosition();
          if (pos != null) {
            clientLat = pos.latitude;
            clientLng = pos.longitude;
            _clientDeviceLocation = LatLng(pos.latitude, pos.longitude);
            debugPrint('[ClientDashboardController] Position GPS client: $clientLat, $clientLng');
          }
        } catch (e) {
          debugPrint('[ClientDashboardController] GPS client indisponible: $e');
        }
      }

      // Priorité 3: Fallback résolution de l'adresse textuelle si GPS non disponible
      if (clientLat == null || clientLng == null) {
        final clientCoordsFallback = RouteCoordinatesHelper.resolveAddress(address);
        clientLat = clientCoordsFallback?.latitude;
        clientLng = clientCoordsFallback?.longitude;
      }

      final vendorCoords = RouteCoordinatesHelper.resolveAddress(
          vendorAddress.isNotEmpty ? vendorAddress : vendorName);

      final order = OrderModel(
        id: '',
        clientId: user.uid,
        clientName: user.name.isNotEmpty ? user.name : 'Client',
        clientPhone: phone,
        deliveryAddress: address,
        vendorId: vendorUid.isNotEmpty ? vendorUid : null,
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
        clientLatitude: clientLat,
        clientLongitude: clientLng,
      );

      final orderId = await _orderService.createOrder(order);

      // ── Envoi des notifications automatiques ──
      try {
        final notifService = NotificationService();
        // 1. Notification Client
        debugPrint('[ClientDashboardController] Envoi notif client (${user.uid})');
        await notifService.sendNotification(
          userId: user.uid,
          title: '✅ Commande envoyée !',
          message: 'Votre commande chez ${vendorName.isNotEmpty ? vendorName : "la boutique"} a été enregistrée avec succès.',
          type: NotificationType.orderStatus,
          orderId: orderId,
        );

        // 2. Notification Vendeur
        if (vendorUid.isNotEmpty) {
          debugPrint('[ClientDashboardController] Envoi notif vendeur ($vendorUid)');
          await notifService.notifyVendorNewOrder(
            vendorId: vendorUid,
            clientName: user.name.isNotEmpty ? user.name : 'Client',
            total: total,
            orderId: orderId,
          );
        } else {
          // Si aucun vendeur spécifique n'est trouvé, notifier tous les vendeurs enregistrés
          try {
            final allVendors = await FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'vendeur')
                .get();
            for (final vDoc in allVendors.docs) {
              await notifService.notifyVendorNewOrder(
                vendorId: vDoc.id,
                clientName: user.name.isNotEmpty ? user.name : 'Client',
                total: total,
                orderId: orderId,
              );
            }
          } catch (_) {}
        }

        // 3. Notification Livreurs (nouvelle course disponible)
        debugPrint('[ClientDashboardController] Envoi notif tous livreurs pour commande $orderId');
        await notifService.notifyAllLivreursNewDelivery(
          vendorName: vendorName.isNotEmpty ? vendorName : 'Boutique',
          deliveryAddress: address,
          deliveryFee: deliveryFee,
          orderId: orderId,
        );
      } catch (err) {
        debugPrint('[ClientDashboardController] Erreur envoi notifications commande: $err');
      }

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
  String _orderStatusFilter = 'Toutes'; // 'Toutes', 'En cours', 'Livrées', 'Annulées'
  String _orderSearchQuery = '';

  String get orderStatusFilter => _orderStatusFilter;
  String get orderSearchQuery => _orderSearchQuery;

  void setOrderStatusFilter(String filter) {
    _orderStatusFilter = filter;
    notifyListeners();
  }

  void setOrderSearchQuery(String query) {
    _orderSearchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  List<OrderModel> filterOrders(List<OrderModel> orders) {
    return orders.where((order) {
      // 1. Filtrage par statut
      bool matchesStatus = true;
      if (_orderStatusFilter == 'En cours') {
        matchesStatus = order.status != OrderStatus.delivered &&
            order.status != OrderStatus.cancelled;
      } else if (_orderStatusFilter == 'Livrées') {
        matchesStatus = order.status == OrderStatus.delivered;
      } else if (_orderStatusFilter == 'Annulées') {
        matchesStatus = order.status == OrderStatus.cancelled;
      }

      // 2. Filtrage par recherche
      bool matchesSearch = true;
      if (_orderSearchQuery.isNotEmpty) {
        final q = _orderSearchQuery;
        final matchesId = order.id.toLowerCase().contains(q);
        final matchesVendor = order.vendorName.toLowerCase().contains(q);
        final matchesItems = order.items.any((item) => item.name.toLowerCase().contains(q));
        matchesSearch = matchesId || matchesVendor || matchesItems;
      }

      return matchesStatus && matchesSearch;
    }).toList();
  }

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
