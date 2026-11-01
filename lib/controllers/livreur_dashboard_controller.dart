import 'dart:async';

import '../models/app_user.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'base_controller.dart';

class LivreurDashboardController extends BaseController {
  final OrderService _orderService;

  LivreurDashboardController({OrderService? orderService})
      : _orderService = orderService ?? OrderService();

  int _currentTab = 0;
  int get currentTab => _currentTab;

  void setTab(int index) {
    if (_currentTab != index) {
      _currentTab = index;
      notifyListeners();
    }
  }

  // --- ÉTAT DE DISPONIBILITÉ DU LIVREUR (Section 8 du cahier des charges) ---
  bool _isAvailable = true;
  bool get isAvailable => _isAvailable;

  StreamSubscription<bool>? _availSub;

  void initAvailability(String courierId) {
    _availSub?.cancel();
    _availSub = _orderService.watchCourierAvailability(courierId).listen((status) {
      _isAvailable = status;
      notifyListeners();
    });
  }

  Future<void> toggleAvailability(String courierId) async {
    _isAvailable = !_isAvailable;
    notifyListeners();
    try {
      await _orderService.updateCourierAvailability(courierId, _isAvailable);
    } catch (_) {
      // Revert if error
      _isAvailable = !_isAvailable;
      notifyListeners();
    }
  }

  // --- STREAMS DES COMMANDES ---
  Stream<List<OrderModel>> watchAvailableDeliveries() {
    return _orderService.watchAvailableOrders();
  }

  Stream<List<OrderModel>> watchMyDeliveries(String courierId) {
    return _orderService.watchCourierOrders(courierId);
  }

  // --- ACTIONS DE GESTION DES LIVRAISONS (Section 9 du cahier des charges) ---
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  Future<String?> acceptDelivery({
    required OrderModel order,
    required AppUser courier,
  }) async {
    _isProcessing = true;
    notifyListeners();
    try {
      await _orderService.acceptOrder(
        orderId: order.id,
        courierId: courier.uid,
        courierName: courier.name,
        courierPhone: courier.phone,
      );
      _isProcessing = false;
      _currentTab = 2; // Basculer automatiquement vers l'onglet "Course active"
      notifyListeners();
      return null;
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      return 'Erreur lors de l\'acceptation : $e';
    }
  }

  Future<String?> confirmPickup(String orderId) async {
    _isProcessing = true;
    notifyListeners();
    try {
      await _orderService.confirmPickup(orderId);
      _isProcessing = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      return 'Erreur de confirmation de retrait : $e';
    }
  }

  Future<String?> startDelivering(String orderId) async {
    _isProcessing = true;
    notifyListeners();
    try {
      await _orderService.startDelivering(orderId);
      _isProcessing = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      return 'Erreur lors du démarrage de la livraison : $e';
    }
  }

  Future<String?> confirmDelivered(String orderId) async {
    _isProcessing = true;
    notifyListeners();
    try {
      await _orderService.confirmDelivery(orderId);
      _isProcessing = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      return 'Erreur lors de la finalisation : $e';
    }
  }

  Future<String?> releaseDelivery(String orderId) async {
    _isProcessing = true;
    notifyListeners();
    try {
      await _orderService.releaseOrder(orderId);
      _isProcessing = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      return 'Erreur lors de l\'annulation : $e';
    }
  }

  // --- GÉNÉRATION DE DONNÉES DE TEST / DÉMONSTRATION ---
  Future<String?> seedDemoOrders() async {
    _isProcessing = true;
    notifyListeners();
    try {
      await _orderService.createDemoOrders();
      _isProcessing = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      return 'Erreur d\'ajout : $e';
    }
  }

  // --- MISE À JOUR DU PROFIL DU LIVREUR (Section 8) ---
  Future<String?> updateProfile({
    required String courierId,
    required String name,
    required String phone,
    required String vehicleType,
    required String plateNumber,
    required String city,
  }) async {
    _isProcessing = true;
    notifyListeners();
    try {
      await _orderService.updateCourierProfile(
        courierId: courierId,
        name: name,
        phone: phone,
        vehicleType: vehicleType,
        plateNumber: plateNumber,
        city: city,
      );
      _isProcessing = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      return 'Erreur lors de la mise à jour : $e';
    }
  }

  @override
  void dispose() {
    _availSub?.cancel();
    super.dispose();
  }
}
