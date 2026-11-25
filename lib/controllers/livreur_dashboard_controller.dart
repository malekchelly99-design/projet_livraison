import 'dart:async';

import '../models/app_user.dart';
import '../models/courier_location.dart';
import '../models/order_model.dart';
import '../services/location_tracking_service.dart';
import '../services/notification_service.dart';
import '../services/order_service.dart';
import 'base_controller.dart';

class LivreurDashboardController extends BaseController {
  final OrderService _orderService;
  final LocationTrackingService _trackingService;
  final NotificationService _notificationService;

  LivreurDashboardController({
    OrderService? orderService,
    LocationTrackingService? trackingService,
    NotificationService? notificationService,
  })  : _orderService = orderService ?? OrderService(),
        _trackingService = trackingService ?? LocationTrackingService(),
        _notificationService = notificationService ?? NotificationService();

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

  /// Crée la notification de bienvenue si c'est la première connexion du livreur.
  Future<void> ensureWelcomeNotification({
    required String courierId,
    required String courierName,
  }) async {
    await _notificationService.ensureWelcomeNotificationLivreur(
      courierId: courierId,
      courierName: courierName,
    );
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

      // ✅ Démarrage automatique du suivi GPS dès l'acceptation
      // pour que le client puisse suivre le livreur pendant son trajet vers la boutique
      try {
        await _trackingService.startTracking(
          courierId: courier.uid,
          orderId: order.id,
        );
      } catch (e) {
        // Ignorer si permission non accordée immédiatement
      }

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

  Future<String?> confirmPickup(String orderId, {String? courierId}) async {
    _isProcessing = true;
    notifyListeners();
    try {
      await _orderService.confirmPickup(orderId);

      // ✅ S'assurer que le GPS continue à être partagé vers le client
      if (courierId != null && !_trackingService.isTrackingActive) {
        try {
          await _trackingService.startTracking(
            courierId: courierId,
            orderId: orderId,
          );
        } catch (_) {}
      }

      _isProcessing = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      return 'Erreur de confirmation de retrait : $e';
    }
  }

  // --- GÉOLOCALISATION GPS EN TEMPS RÉEL DU LIVREUR ---
  bool isTrackingActiveFor(String orderId) =>
      _trackingService.isTrackingActive && _trackingService.activeOrderId == orderId;

  Stream<CourierLocation?> watchOrderLocation(String orderId) {
    return _trackingService.watchCourierLocation(orderId);
  }

  Future<LocationPermissionResult> startLocationTracking({
    required String courierId,
    required String orderId,
  }) async {
    final result = await _trackingService.startTracking(
      courierId: courierId,
      orderId: orderId,
    );
    notifyListeners();
    return result;
  }

  Future<void> stopLocationTracking({String? orderId}) async {
    await _trackingService.stopTracking(orderId: orderId);
    notifyListeners();
  }

  Future<String?> startDelivering(String orderId, {String? courierId}) async {
    _isProcessing = true;
    notifyListeners();
    try {
      await _orderService.startDelivering(orderId);

      // Démarrage automatique du suivi GPS si le courierId est fourni
      if (courierId != null) {
        await _trackingService.startTracking(
          courierId: courierId,
          orderId: orderId,
        );
      }

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
      // 1. Arrêter le partage GPS dès que la commande est livrée
      await _trackingService.stopTracking(orderId: orderId);

      // 2. Confirmer la livraison dans Firestore
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
      // Arrêter le partage GPS si la course est annulée/libérée
      await _trackingService.stopTracking(orderId: orderId);

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
    _trackingService.stopTracking();
    super.dispose();
  }
}
