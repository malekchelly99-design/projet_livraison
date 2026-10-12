import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _db;

  OrderService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders => _db.collection('orders');
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  /// Enregistre une nouvelle commande dans Firestore.
  Future<String> createOrder(OrderModel order) async {
    final docRef = await _orders.add(order.toMap());
    return docRef.id;
  }

  /// Écoute les commandes d'un client en temps réel.
  /// Le tri est fait côté client pour éviter d'exiger un index composite Firestore.
  Stream<List<OrderModel>> watchClientOrders(String clientId) {
    return _orders
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return OrderModel.fromMap(doc.id, doc.data());
      }).toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Écoute les commandes prêtes / disponibles pour les livreurs.
  /// (Sans livreur assigné et avec statut prêt ou en attente/en préparation)
  Stream<List<OrderModel>> watchAvailableOrders() {
    return _orders.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.id, doc.data()))
          .where((order) {
            final hasNoCourier = order.courierId == null || order.courierId!.isEmpty;
            final isAvailableStatus = order.status == OrderStatus.ready ||
                order.status == OrderStatus.pending ||
                order.status == OrderStatus.preparing;
            return hasNoCourier && isAvailableStatus;
          })
          .toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Écoute les commandes affectées à un livreur spécifique.
  Stream<List<OrderModel>> watchCourierOrders(String courierId) {
    return _orders
        .where('courierId', isEqualTo: courierId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return OrderModel.fromMap(doc.id, doc.data());
      }).toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Accepte une commande par le livreur (Livreur affecté)
  Future<void> acceptOrder({
    required String orderId,
    required String courierId,
    required String courierName,
    required String courierPhone,
  }) {
    return _orders.doc(orderId).update({
      'courierId': courierId,
      'courierName': courierName,
      'courierPhone': courierPhone,
      'status': OrderStatus.assigned.name,
      'assignedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Confirme la récupération de la commande chez le commerçant
  Future<void> confirmPickup(String orderId) {
    return _orders.doc(orderId).update({
      'status': OrderStatus.pickedUp.name,
      'pickedUpAt': FieldValue.serverTimestamp(),
    });
  }

  /// Démarre la livraison vers l'adresse du client
  Future<void> startDelivering(String orderId) {
    return _orders.doc(orderId).update({
      'status': OrderStatus.delivering.name,
      'startedDeliveringAt': FieldValue.serverTimestamp(),
    });
  }

  /// Confirme la livraison au client
  Future<void> confirmDelivery(String orderId) {
    return _orders.doc(orderId).update({
      'status': OrderStatus.delivered.name,
      'deliveredAt': FieldValue.serverTimestamp(),
    });
  }

  /// Refuse ou annule l'affectation d'une livraison (la remet disponible pour d'autres livreurs)
  Future<void> releaseOrder(String orderId) {
    return _orders.doc(orderId).update({
      'courierId': FieldValue.delete(),
      'courierName': FieldValue.delete(),
      'courierPhone': FieldValue.delete(),
      'status': OrderStatus.ready.name,
      'releasedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Met à jour la disponibilité du livreur (disponible / indisponible)
  Future<void> updateCourierAvailability(String courierId, bool isAvailable) {
    return _users.doc(courierId).update({
      'isAvailable': isAvailable,
      'lastAvailabilityUpdate': FieldValue.serverTimestamp(),
    });
  }

  /// Écoute la disponibilité du livreur
  Stream<bool> watchCourierAvailability(String courierId) {
    return _users.doc(courierId).snapshots().map((doc) {
      if (!doc.exists) return true;
      final data = doc.data();
      return (data?['isAvailable'] as bool?) ?? true;
    });
  }

  /// Met à jour le profil du livreur
  Future<void> updateCourierProfile({
    required String courierId,
    required String name,
    required String phone,
    required String vehicleType,
    required String plateNumber,
    required String city,
  }) {
    return _users.doc(courierId).update({
      'name': name,
      'phone': phone,
      'profile.vehicleType': vehicleType,
      'profile.plateNumber': plateNumber,
      'profile.city': city,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Crée des commandes de démonstration pour tester l'application facilement
  Future<void> createDemoOrders() async {
    final demoOrders = [
      OrderModel(
        id: '',
        clientId: 'demo_client_1',
        clientName: 'Sarra Ben Ahmed',
        clientPhone: '+216 98 112 233',
        deliveryAddress: 'Résidence Les Palmiers, Ennasr 2, Tunis',
        items: const [
          OrderItem(productId: 'p1', name: 'Pizza Margherita XL', price: 18.5, quantity: 2),
          OrderItem(productId: 'p2', name: 'Coca-Cola 1.5L', price: 3.5, quantity: 1),
        ],
        subtotal: 40.5,
        deliveryFee: 4.5,
        total: 45.0,
        status: OrderStatus.ready,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        paymentMethod: 'Espèces à la livraison',
        notes: 'Sonner à l\'interphone B4 s\'il vous plaît',
        vendorName: 'Pizzeria Bella Napoli',
        vendorAddress: '14 Rue Hédi Nouira, Ennasr 2',
        vendorPhone: '+216 71 889 900',
      ),
      OrderModel(
        id: '',
        clientId: 'demo_client_2',
        clientName: 'Karim Mansour',
        clientPhone: '+216 55 443 322',
        deliveryAddress: 'Appt 12, Bloc A, Les Berges du Lac 2',
        items: const [
          OrderItem(productId: 'p3', name: 'Pack Sushi Mix 24 pcs', price: 58.0, quantity: 1),
          OrderItem(productId: 'p4', name: 'Salade Wakame', price: 9.5, quantity: 1),
        ],
        subtotal: 67.5,
        deliveryFee: 5.0,
        total: 72.5,
        status: OrderStatus.ready,
        createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
        paymentMethod: 'Paiement en ligne (Validé)',
        notes: 'Laisser à la réception si indisponible',
        vendorName: 'Sakura Sushi Bar',
        vendorAddress: 'Rue de la Bourse, Les Berges du Lac 2',
        vendorPhone: '+216 71 654 321',
      ),
      OrderModel(
        id: '',
        clientId: 'demo_client_3',
        clientName: 'Amine Trabelsi',
        clientPhone: '+216 22 998 877',
        deliveryAddress: '18 Rue de Marseille, Tunis Centre',
        items: const [
          OrderItem(productId: 'p5', name: 'Burger Gourmet Double Bacon', price: 16.5, quantity: 1),
          OrderItem(productId: 'p6', name: 'Frites Maison & Sauce Cheddar', price: 5.5, quantity: 1),
        ],
        subtotal: 22.0,
        deliveryFee: 4.0,
        total: 26.0,
        status: OrderStatus.ready,
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
        paymentMethod: 'Espèces à la livraison',
        vendorName: 'The Burger Club',
        vendorAddress: 'Avenue Habib Bourguiba, Tunis Centre',
        vendorPhone: '+216 71 112 233',
      ),
    ];

    for (final order in demoOrders) {
      await createOrder(order);
    }
  }

  /// Met à jour le statut d'une commande générique
  Future<void> updateStatus(String orderId, OrderStatus status) {
    return _orders.doc(orderId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
