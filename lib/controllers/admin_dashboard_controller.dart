import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/order_model.dart';
import '../models/product.dart';
import '../models/reclamation_model.dart';
import '../models/user_role.dart';
import '../services/boutique_service.dart';
import '../services/catalog_service.dart';
import '../services/order_service.dart';
import '../services/reclamation_service.dart';
import '../services/user_service.dart';
import 'base_controller.dart';

class AdminDashboardController extends BaseController {
  final AppUser user;
  final UserService _userService;
  final OrderService _orderService;
  final CatalogService _catalogService;
  final BoutiqueService _boutiqueService;
  final ReclamationService _reclamationService;

  StreamSubscription<List<AppUser>>? _usersSub;
  StreamSubscription<List<OrderModel>>? _ordersSub;
  StreamSubscription<List<Product>>? _productsSub;
  StreamSubscription<List<ReclamationModel>>? _reclamationsSub;

  int _currentTab = 0;
  int get currentTab => _currentTab;

  List<AppUser> _users = [];
  List<AppUser> get users => _users;

  List<OrderModel> _orders = [];
  List<OrderModel> get orders => _orders;

  List<Product> _products = [];
  List<Product> get products => _products;

  List<ReclamationModel> _reclamations = [];
  List<ReclamationModel> get reclamations => _reclamations;
  int get pendingReclamationsCount =>
      _reclamations.where((r) => r.status == ReclamationStatus.enAttente).length;

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

  // Filtres Réclamations
  ReclamationStatus? _selectedReclamationStatus;
  ReclamationStatus? get selectedReclamationStatus => _selectedReclamationStatus;

  String _reclamationSearchQuery = '';
  String get reclamationSearchQuery => _reclamationSearchQuery;

  List<ReclamationModel> get filteredReclamations {
    return _reclamations.where((r) {
      if (_selectedReclamationStatus != null && r.status != _selectedReclamationStatus) {
        return false;
      }
      if (_reclamationSearchQuery.isNotEmpty) {
        final q = _reclamationSearchQuery;
        final matchClient = r.clientName.toLowerCase().contains(q);
        final matchVendor = (r.vendorName ?? '').toLowerCase().contains(q);
        final matchSubject = r.subject.toLowerCase().contains(q);
        final matchDesc = r.description.toLowerCase().contains(q);
        final matchOrder = r.orderId?.toLowerCase().contains(q) ?? false;
        final matchCat = r.category.toLowerCase().contains(q);
        return matchClient || matchVendor || matchSubject || matchDesc || matchOrder || matchCat;
      }
      return true;
    }).toList();
  }

  AdminDashboardController({
    required this.user,
    UserService? userService,
    OrderService? orderService,
    CatalogService? catalogService,
    BoutiqueService? boutiqueService,
    ReclamationService? reclamationService,
  })  : _userService = userService ?? UserService(),
        _orderService = orderService ?? OrderService(),
        _catalogService = catalogService ?? CatalogService(),
        _boutiqueService = boutiqueService ?? BoutiqueService(),
        _reclamationService = reclamationService ?? ReclamationService() {
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
        if (list.isNotEmpty || _users.isEmpty) {
          _users = list;
          _isLoading = false;
          notifyListeners();
        }
      },
      onError: (err) {
        debugPrint('[AdminController] Erreur utilisateurs: $err');
        _isLoading = false;
        notifyListeners();
      },
    );

    _ordersSub = _orderService.watchAllOrders().listen(
      (list) {
        if (list.isNotEmpty || _orders.isEmpty) {
          _orders = list;
          _isLoading = false;
          notifyListeners();
        }
      },
      onError: (err) {
        debugPrint('[AdminController] Erreur commandes: $err');
        _isLoading = false;
        notifyListeners();
      },
    );

    _productsSub = _catalogService.watchProducts().listen(
      (list) {
        if (list.isNotEmpty || _products.isEmpty) {
          _products = list;
          _isLoading = false;
          notifyListeners();
        }
      },
      onError: (err) {
        debugPrint('[AdminController] Erreur catalogue: $err');
        _isLoading = false;
        notifyListeners();
      },
    );

    _reclamationsSub = _reclamationService.watchAllReclamations().listen(
      (list) {
        _reclamations = list;
        notifyListeners();
      },
      onError: (err) {
        debugPrint('[AdminController] Erreur réclamations: $err');
      },
    );
  }

  // Setters de filtres
  void setReclamationStatusFilter(ReclamationStatus? status) {
    _selectedReclamationStatus = status;
    notifyListeners();
  }

  void setReclamationSearchQuery(String query) {
    _reclamationSearchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  Future<void> respondToReclamation({
    required String reclamationId,
    required String response,
    ReclamationStatus newStatus = ReclamationStatus.resolue,
  }) async {
    await _reclamationService.respondToReclamation(
      reclamationId: reclamationId,
      response: response,
      responderName: 'Administration (${user.name})',
      newStatus: newStatus,
    );
  }

  Future<void> updateReclamationStatus({
    required String reclamationId,
    required ReclamationStatus newStatus,
  }) async {
    await _reclamationService.updateStatus(
      reclamationId: reclamationId,
      newStatus: newStatus,
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
  double get totalRevenue => _orders.fold(0.0, (acc, o) => acc + o.total);

  double get deliveredRevenue => _orders
      .where((o) => o.status == OrderStatus.delivered)
      .fold(0.0, (acc, o) => acc + o.total);

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
    if (newRole == UserRole.admin) return;
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
    _reclamationsSub?.cancel();
    super.dispose();
  }
}
