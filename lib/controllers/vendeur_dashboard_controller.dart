import 'dart:async';
import '../models/app_user.dart';
import '../models/order_model.dart';
import '../models/product.dart';
import '../services/catalog_service.dart';
import '../services/order_service.dart';
import '../services/user_service.dart';
import 'base_controller.dart';

class VendeurDashboardController extends BaseController {
  final AppUser user;
  final CatalogService _catalogService;
  final OrderService _orderService;
  final UserService _userService;

  StreamSubscription<List<Product>>? _productsSub;
  StreamSubscription<List<OrderModel>>? _ordersSub;

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

  // Statut boutique
  bool _isOpen = true;
  bool get isOpen => _isOpen;

  VendeurDashboardController({
    required this.user,
    CatalogService? catalogService,
    OrderService? orderService,
    UserService? userService,
  })  : _catalogService = catalogService ?? CatalogService(),
        _orderService = orderService ?? OrderService(),
        _userService = userService ?? UserService() {
    _initSubscriptions();
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

    _productsSub = _catalogService
        .watchVendorProducts(shopName: shopName, vendorId: user.uid)
        .listen(
      (list) {
        _products = list;
        _isLoading = false;
        notifyListeners();

        // Ré-abonnement commandes avec la liste actualisée des IDs de produits
        _subscribeOrders();
      },
      onError: (err) {
        _errorMessage = 'Erreur lors du chargement des produits';
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
        _orders = list;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = 'Erreur lors du chargement des commandes';
        notifyListeners();
      },
    );
  }

  void setTab(int index) {
    if (_currentTab != index) {
      _currentTab = index;
      notifyListeners();
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

  void toggleShopOpen(bool value) {
    _isOpen = value;
    notifyListeners();
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
    return _orders.where((o) => o.status == OrderStatus.delivering).length;
  }

  int get completedOrdersCount {
    return _orders.where((o) => o.status == OrderStatus.delivered).length;
  }

  List<Product> get filteredProducts {
    return _products.where((p) {
      final matchesCat = _selectedCategory == 'Tous' || p.category == _selectedCategory;
      final matchesSearch = _productSearchQuery.isEmpty ||
          p.name.toLowerCase().contains(_productSearchQuery) ||
          p.description.toLowerCase().contains(_productSearchQuery);
      return matchesCat && matchesSearch;
    }).toList();
  }

  List<OrderModel> get filteredOrders {
    if (_selectedOrderStatus == null) return _orders;
    return _orders.where((o) => o.status == _selectedOrderStatus).toList();
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
    super.dispose();
  }
}
