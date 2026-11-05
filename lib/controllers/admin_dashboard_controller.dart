import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/order_model.dart';
import '../models/product.dart';
import '../models/user_role.dart';
import '../services/boutique_service.dart';
import '../services/catalog_service.dart';
import '../services/order_service.dart';
import '../services/user_service.dart';
import 'base_controller.dart';

class AdminDashboardController extends BaseController {
  final AppUser user;
  final UserService _userService;
  final OrderService _orderService;
  final CatalogService _catalogService;
  final BoutiqueService _boutiqueService;

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

  AdminDashboardController({
    required this.user,
    UserService? userService,
    OrderService? orderService,
    CatalogService? catalogService,
    BoutiqueService? boutiqueService,
  })  : _userService = userService ?? UserService(),
        _orderService = orderService ?? OrderService(),
        _catalogService = catalogService ?? CatalogService(),
        _boutiqueService = boutiqueService ?? BoutiqueService() {
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

  /// Purge complète de toutes les données démo / test de la base de données.
  Future<String> purgeAllDemoData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final ordersPurged = await _orderService.purgeDemoOrders();
      final usersPurged = await _userService.purgeDemoUsers();
      final productsPurged = await _catalogService.purgeDemoProducts();

      _errorMessage = null;
      return '$ordersPurged commande(s), $usersPurged utilisateur(s) et $productsPurged produit(s) démo purgés de la base.';
    } catch (e) {
      _errorMessage = 'Erreur lors du nettoyage : $e';
      return 'Erreur : $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initialise les tables et catégories par défaut dans Firestore.
  Future<void> ensureDefaultCategories() async {
    await _catalogService.ensureDefaultCategories();
  }

  /// Synchronise tous les vendeurs existants dans la collection 'boutiques'.
  Future<String> syncAllBoutiques() async {
    int count = 0;
    try {
      for (final v in vendors) {
        final profile = v.profile;
        await _boutiqueService.sync(
          vendeurId: v.uid,
          nomBoutique: v.shopName.isNotEmpty
              ? v.shopName
              : (v.name.isNotEmpty ? 'Boutique ${v.name}' : 'Boutique'),
          categorie: (profile['category'] as String?) ?? 'Restaurant',
          adresse: (profile['address'] as String?) ?? (profile['city'] as String?) ?? 'Tunis',
          ville: (profile['city'] as String?) ?? 'Tunis',
          matriculeFiscale: (profile['taxId'] as String?) ?? '',
          nomResponsable: v.name,
          email: v.email,
          telephone: v.phone,
          description: (profile['description'] as String?) ?? '',
          horaires: (profile['horaires'] as String?) ?? '08:00 - 22:00',
        );
        count++;
      }
      return '$count boutique(s) synchronisée(s) avec succès dans la table boutiques.';
    } catch (e) {
      return 'Erreur de synchronisation : $e';
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
