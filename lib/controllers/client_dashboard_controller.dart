import 'dart:async';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/order_model.dart';
import '../models/product.dart';
import '../services/catalog_service.dart';
import '../services/order_service.dart';
import 'base_controller.dart';

class ClientDashboardController extends BaseController {
  final CatalogService _catalogService;
  final OrderService _orderService;

  ClientDashboardController({
    CatalogService? catalogService,
    OrderService? orderService,
  })  : _catalogService = catalogService ?? CatalogService(),
        _orderService = orderService ?? OrderService() {
    _initCatalog();
  }

  // --- NAVIGATION ONGLETS ---
  int _currentTab = 0;
  int get currentTab => _currentTab;

  void setTab(int index) {
    if (_currentTab != index) {
      _currentTab = index;
      notifyListeners();
    }
  }

  // --- CATALOGUE ET FILTRES ---
  List<Product> _allProducts = CatalogService.defaultProducts;
  StreamSubscription<List<Product>>? _catalogSub;
  String _selectedCategory = 'Tous';
  String _searchQuery = '';

  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  void _initCatalog() {
    _catalogSub = _catalogService.watchProducts().listen((list) {
      _allProducts = list;
      notifyListeners();
    });
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  List<Product> get filteredProducts {
    return _allProducts.where((p) {
      final matchesCategory =
          _selectedCategory == 'Tous' || p.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery) ||
          p.description.toLowerCase().contains(_searchQuery) ||
          p.shopName.toLowerCase().contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<Product> get popularProducts =>
      _allProducts.where((p) => p.isPopular).toList();

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
  final TextEditingController addressCtrl =
      TextEditingController(text: '15 Avenue Habib Bourguiba, Tunis');
  final TextEditingController notesCtrl = TextEditingController();
  String selectedPaymentMethod = 'Paiement en espèces à la livraison';

  bool _isSubmittingOrder = false;
  bool get isSubmittingOrder => _isSubmittingOrder;

  Future<String?> placeOrder(AppUser user) async {
    if (_cart.isEmpty) {
      return 'Votre panier est vide.';
    }

    final address = addressCtrl.text.trim();
    if (address.isEmpty) {
      return 'Veuillez renseigner votre adresse de livraison.';
    }

    _isSubmittingOrder = true;
    notifyListeners();

    try {
      final order = OrderModel(
        id: '',
        clientId: user.uid,
        clientName: user.name.isNotEmpty ? user.name : 'Client',
        clientPhone: user.phone,
        deliveryAddress: address,
        items: _cart.values
            .map((item) => OrderItem(
                  productId: item.product.id,
                  name: item.product.name,
                  price: item.product.price,
                  quantity: item.quantity,
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
      );

      await _orderService.createOrder(order);

      clearCart();
      notesCtrl.clear();
      _isSubmittingOrder = false;
      _currentTab = 2; // redirection automatique vers l'onglet "Commandes"
      notifyListeners();
      return null;
    } catch (e) {
      _isSubmittingOrder = false;
      notifyListeners();
      return 'Erreur lors de la commande: $e';
    }
  }

  // --- SUIVI DES COMMANDES ---
  Stream<List<OrderModel>> watchOrders(String clientId) {
    return _orderService.watchClientOrders(clientId);
  }

  Future<void> cancelOrder(String orderId) async {
    await _orderService.updateStatus(orderId, OrderStatus.cancelled);
  }

  @override
  void dispose() {
    _catalogSub?.cancel();
    addressCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }
}
