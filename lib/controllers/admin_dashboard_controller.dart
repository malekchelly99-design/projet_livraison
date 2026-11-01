import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/order_model.dart';
import '../models/product.dart';
import '../models/user_role.dart';
import '../services/catalog_service.dart';
import '../services/order_service.dart';
import '../services/user_service.dart';
import 'base_controller.dart';

class AdminDashboardController extends BaseController {
  final AppUser user;
  final UserService _userService;
  final OrderService _orderService;
  final CatalogService _catalogService;

  StreamSubscription<List<AppUser>>? _usersSub;
  StreamSubscription<List<OrderModel>>? _ordersSub;
  StreamSubscription<List<Product>>? _productsSub;

  int _currentTab = 0;
  int get currentTab => _currentTab;

  List<AppUser> _users = [];
  List<AppUser> get users => _users;

  List<OrderModel> _orders = [];
  List<OrderModel> get orders => _orders;

  List<Product> _products = [];
  List<Product> get products => _products;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Filtres Commandes
  OrderStatus? _selectedOrderStatus;
  OrderStatus? get selectedOrderStatus => _selectedOrderStatus;

  String _orderSearchQuery = '';
  String get orderSearchQuery => _orderSearchQuery;

  // Filtres Utilisateurs
  UserRole? _selectedUserRole;
  UserRole? get selectedUserRole => _selectedUserRole;

  String _userSearchQuery = '';
  String get userSearchQuery => _userSearchQuery;

  // Filtres Catalogue
  String _selectedCategory = 'Tous';
  String get selectedCategory => _selectedCategory;

  String _productSearchQuery = '';
  String get productSearchQuery => _productSearchQuery;

  AdminDashboardController({
    required this.user,
    UserService? userService,
    OrderService? orderService,
    CatalogService? catalogService,
  })  : _userService = userService ?? UserService(),
        _orderService = orderService ?? OrderService(),
        _catalogService = catalogService ?? CatalogService() {
    _initSubscriptions();
  }

  void setTab(int index) {
    if (_currentTab != index) {
      _currentTab = index;
      notifyListeners();
    }
  }

  void _initSubscriptions() {
    _isLoading = true;
    notifyListeners();

    _usersSub = _userService.watchAllUsers().listen(
      (list) {
        _users = list;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = 'Erreur lors du chargement des utilisateurs: $err';
        _isLoading = false;
        notifyListeners();
      },
    );

    _ordersSub = _orderService.watchAllOrders().listen(
      (list) {
        _orders = list;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = 'Erreur lors du chargement des commandes: $err';
        _isLoading = false;
        notifyListeners();
      },
    );

    _productsSub = _catalogService.watchProducts().listen(
      (list) {
        _products = list;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = 'Erreur lors du chargement du catalogue: $err';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Setters de filtres
  void setOrderStatusFilter(OrderStatus? status) {
    _selectedOrderStatus = status;
    notifyListeners();
  }

  void setOrderSearchQuery(String query) {
    _orderSearchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void setUserRoleFilter(UserRole? role) {
    _selectedUserRole = role;
    notifyListeners();
  }

  void setUserSearchQuery(String query) {
    _userSearchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void setProductCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setProductSearchQuery(String query) {
    _productSearchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  // Listes filtrées
  List<OrderModel> get filteredOrders {
    return _orders.where((order) {
      if (_selectedOrderStatus != null && order.status != _selectedOrderStatus) {
        return false;
      }
      if (_orderSearchQuery.isNotEmpty) {
        final idMatch = order.id.toLowerCase().contains(_orderSearchQuery);
        final clientMatch = order.clientName.toLowerCase().contains(_orderSearchQuery);
        final phoneMatch = order.clientPhone.toLowerCase().contains(_orderSearchQuery);
        final vendorMatch = order.vendorName.toLowerCase().contains(_orderSearchQuery);
        final courierMatch = (order.courierName ?? '').toLowerCase().contains(_orderSearchQuery);
        final addressMatch = order.deliveryAddress.toLowerCase().contains(_orderSearchQuery);
        if (!idMatch && !clientMatch && !phoneMatch && !vendorMatch && !courierMatch && !addressMatch) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<AppUser> get filteredUsers {
    return _users.where((u) {
      if (_selectedUserRole != null && u.role != _selectedUserRole) {
        return false;
      }
      if (_userSearchQuery.isNotEmpty) {
        final nameMatch = u.name.toLowerCase().contains(_userSearchQuery);
        final emailMatch = u.email.toLowerCase().contains(_userSearchQuery);
        final phoneMatch = u.phone.toLowerCase().contains(_userSearchQuery);
        final shopMatch = u.shopName.toLowerCase().contains(_userSearchQuery);
        if (!nameMatch && !emailMatch && !phoneMatch && !shopMatch) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<Product> get filteredProducts {
    return _products.where((p) {
      if (_selectedCategory != 'Tous' &&
          p.category.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }
      if (_productSearchQuery.isNotEmpty) {
        final nameMatch = p.name.toLowerCase().contains(_productSearchQuery);
        final descMatch = p.description.toLowerCase().contains(_productSearchQuery);
        final shopMatch = p.shopName.toLowerCase().contains(_productSearchQuery);
        if (!nameMatch && !descMatch && !shopMatch) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // Livreurs disponibles ou enregistrés
  List<AppUser> get couriers => _users.where((u) => u.role == UserRole.livreur).toList();
  List<AppUser> get vendors => _users.where((u) => u.role == UserRole.vendeur).toList();
  List<AppUser> get clients => _users.where((u) => u.role == UserRole.client).toList();
  List<AppUser> get admins => _users.where((u) => u.role == UserRole.admin).toList();

  // Statistiques financières & volumétriques
  double get totalRevenue => _orders.fold(0.0, (sum, o) => sum + o.total);

  double get deliveredRevenue => _orders
      .where((o) => o.status == OrderStatus.delivered)
      .fold(0.0, (sum, o) => sum + o.total);

  int get totalOrdersCount => _orders.length;
  int get deliveredOrdersCount =>
      _orders.where((o) => o.status == OrderStatus.delivered).length;
  int get activeOrdersCount => _orders.where((o) =>
      o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled).length;
  int get pendingOrdersCount =>
      _orders.where((o) => o.status == OrderStatus.pending).length;
  int get preparingOrdersCount =>
      _orders.where((o) => o.status == OrderStatus.preparing || o.status == OrderStatus.ready).length;
  int get inDeliveryOrdersCount =>
      _orders.where((o) => o.status == OrderStatus.assigned || o.status == OrderStatus.delivering || o.status == OrderStatus.pickedUp).length;
  int get cancelledOrdersCount =>
      _orders.where((o) => o.status == OrderStatus.cancelled).length;

  double get averageOrderValue => totalOrdersCount > 0
      ? totalRevenue / totalOrdersCount
      : 0.0;

  double get platformCommission => totalRevenue * 0.10; // 10% commission

  // Actions Admin
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _orderService.updateStatus(orderId, status);
  }

  Future<void> assignCourier({
    required String orderId,
    required String courierId,
    required String courierName,
    required String courierPhone,
  }) async {
    await _orderService.assignCourierByAdmin(
      orderId: orderId,
      courierId: courierId,
      courierName: courierName,
      courierPhone: courierPhone,
    );
  }

  Future<void> deleteOrder(String orderId) async {
    await _orderService.deleteOrder(orderId);
  }

  Future<void> updateUserRole(String uid, UserRole newRole) async {
    await _userService.updateRole(uid, newRole.name);
  }

  Future<void> toggleUserBlocked(String uid, bool isBlocked) async {
    await _userService.toggleUserBlocked(uid, isBlocked);
  }

  Future<void> deleteUser(String uid) async {
    await _userService.deleteUser(uid);
  }

  Future<void> addProduct(Product product) async {
    await _catalogService.addProduct(product);
  }

  Future<void> updateProduct(Product product) async {
    await _catalogService.updateProduct(product);
  }

  Future<void> deleteProduct(String productId) async {
    await _catalogService.deleteProduct(productId);
  }

  /// Génération de données de test complètes si la base est vide
  Future<void> seedPlatformDemoData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = FirebaseFirestore.instance;

      // 1. Démo Produits
      final demoProducts = [
        const Product(
          id: '',
          name: 'Burger Gourmet Signature',
          description: 'Steak pur boeuf 180g, cheddar affiné, sauce maison, frites croustillantes.',
          price: 18.5,
          category: 'Plats',
          shopName: 'Le Gourmet Burger',
          rating: 4.9,
          deliveryTimeMinutes: 20,
          isPopular: true,
          imageUrl: '',
        ),
        const Product(
          id: '',
          name: 'Pizza Truffe & Mozzarella di Bufala',
          description: 'Crème de truffe, mozzarella fraîche, roquette, copeaux de parmesan.',
          price: 24.0,
          category: 'Pizzas',
          shopName: 'Pizzeria Bella Napoli',
          rating: 4.8,
          deliveryTimeMinutes: 25,
          isPopular: true,
          imageUrl: '',
        ),
        const Product(
          id: '',
          name: 'Sandwich Poulet Braisé Croustillant',
          description: 'Poulet mariné, salade croquante, tomates fraîches, sauce piquante.',
          price: 9.5,
          category: 'Sandwiches',
          shopName: 'Snack L\'Express',
          rating: 4.6,
          deliveryTimeMinutes: 15,
          isPopular: false,
          imageUrl: '',
        ),
        const Product(
          id: '',
          name: 'Tacos 3 Viandes XL',
          description: 'Cordon bleu, tenders maison, viande hachée, sauce fromagère.',
          price: 14.0,
          category: 'Plats',
          shopName: 'Tacos Master',
          rating: 4.7,
          deliveryTimeMinutes: 20,
          isPopular: true,
          imageUrl: '',
        ),
        const Product(
          id: '',
          name: 'Plateau Pâtisserie Gourmande',
          description: 'Assortiment de 6 mini-éclairs et 4 tartelettes framboises.',
          price: 16.0,
          category: 'Desserts',
          shopName: 'Boulangerie Gourmet',
          rating: 4.9,
          deliveryTimeMinutes: 30,
          isPopular: true,
          imageUrl: '',
        ),
      ];

      for (final p in demoProducts) {
        await db.collection('products').add(p.toMap());
      }

      // 2. Démo Commandes via OrderService
      await _orderService.createDemoOrders();

      // 3. Démo Utilisateurs supplémentaires si la collection users en a peu
      final demoUsers = [
        {
          'uid': 'demo_courier_ali',
          'name': 'Ali Ben Salah',
          'email': 'ali.livreur@livraison.com',
          'phone': '+216 98 444 333',
          'role': 'livreur',
          'profile': {
            'vehicleType': 'Scooter Yamaha 125',
            'plateNumber': 'TN 204-5891',
            'city': 'Tunis Centre',
            'isBlocked': false,
          },
          'isAvailable': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'uid': 'demo_courier_karim',
          'name': 'Karim Gharbi',
          'email': 'karim.livreur@livraison.com',
          'phone': '+216 22 777 666',
          'role': 'livreur',
          'profile': {
            'vehicleType': 'Moto Honda CBF',
            'plateNumber': 'TN 198-1122',
            'city': 'Ariana',
            'isBlocked': false,
          },
          'isAvailable': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'uid': 'demo_vendor_napoli',
          'name': 'Marco Bellini',
          'email': 'contact@bellanapoli.tn',
          'phone': '+216 71 222 333',
          'role': 'vendeur',
          'profile': {
            'shopName': 'Pizzeria Bella Napoli',
            'category': 'Pizzas & Italien',
            'address': '12 Rue de la Marsa, Tunis',
            'city': 'Tunis',
            'taxId': '14589632/A/P/000',
            'isBlocked': false,
          },
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      for (final u in demoUsers) {
        await db.collection('users').doc(u['uid'] as String).set(u, SetOptions(merge: true));
      }

    } catch (e) {
      _errorMessage = 'Erreur lors de l\'injection des données: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _ordersSub?.cancel();
    _productsSub?.cancel();
    super.dispose();
  }
}
