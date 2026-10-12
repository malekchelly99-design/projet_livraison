import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _db;

  OrderService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders => _db.collection('orders');

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

  /// Écoute les commandes destinées à un vendeur (en fonction du nom de la boutique ou des produits).
  Stream<List<OrderModel>> watchVendorOrders(String shopName, {Set<String>? vendorProductIds}) {
    return _orders.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return OrderModel.fromMap(doc.id, doc.data());
      }).where((order) {
        if (shopName.isEmpty) return true;

        // Si le nom de la boutique correspond à un article
        final hasShopItem = order.items.any((item) =>
            item.shopName.trim().toLowerCase() == shopName.trim().toLowerCase());
        if (hasShopItem) return true;

        // Si un des articles appartient aux produits du vendeur
        if (vendorProductIds != null && vendorProductIds.isNotEmpty) {
          final hasProduct = order.items.any((item) => vendorProductIds.contains(item.productId));
          if (hasProduct) return true;
        }

        // Si aucun nom de boutique n'était renseigné sur la commande (rétro-compatibilité)
        final noShopInItems = order.items.every((item) => item.shopName.isEmpty);
        if (noShopInItems) return true;

        return false;
      }).toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Met à jour le statut d'une commande (ex: annulation par le client, acceptation par le vendeur)
  Future<void> updateStatus(String orderId, OrderStatus status) {
    return _orders.doc(orderId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- LIVREUR SERVICES ---

  /// Écoute la disponibilité en temps réel d'un livreur (stockée dans users/{courierId}).
  Stream<bool> watchCourierAvailability(String courierId) {
    return _db.collection('users').doc(courierId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return true;
      return (data['isAvailable'] as bool?) ?? true;
    });
  }

  /// Met à jour l'état de disponibilité d'un livreur dans Firestore.
  Future<void> updateCourierAvailability(String courierId, bool isAvailable) async {
    await _db.collection('users').doc(courierId).set({
      'isAvailable': isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Écoute les commandes disponibles pour livraison (non assignées à un livreur et avec statut éligible).
  Stream<List<OrderModel>> watchAvailableOrders() {
    return _orders.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.id, doc.data()))
          .where((order) {
            final isUnassigned = order.courierId == null || order.courierId!.isEmpty;
            final isAvailableStatus = order.status == OrderStatus.pending ||
                order.status == OrderStatus.preparing ||
                order.status == OrderStatus.ready;
            return isUnassigned && isAvailableStatus;
          })
          .toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Écoute les commandes assignées ou traitées par un livreur spécifique.
  Stream<List<OrderModel>> watchCourierOrders(String courierId) {
    return _orders.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.id, doc.data()))
          .where((order) => order.courierId == courierId)
          .toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Le livreur accepte une commande.
  Future<void> acceptOrder({
    required String orderId,
    required String courierId,
    required String courierName,
    required String courierPhone,
  }) async {
    await _orders.doc(orderId).update({
      'courierId': courierId,
      'courierName': courierName,
      'courierPhone': courierPhone,
      'status': OrderStatus.assigned.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Le livreur confirme la récupération du colis chez le vendeur.
  Future<void> confirmPickup(String orderId) async {
    await _orders.doc(orderId).update({
      'status': OrderStatus.pickedUp.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Le livreur démarrer le trajet vers le client.
  Future<void> startDelivering(String orderId) async {
    await _orders.doc(orderId).update({
      'status': OrderStatus.delivering.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Le livreur confirme la livraison au client.
  Future<void> confirmDelivery(String orderId) async {
    await _orders.doc(orderId).update({
      'status': OrderStatus.delivered.name,
      'deliveredAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Le livreur libère la course, la remettant à disposition.
  Future<void> releaseOrder(String orderId) async {
    await _orders.doc(orderId).update({
      'courierId': FieldValue.delete(),
      'courierName': FieldValue.delete(),
      'courierPhone': FieldValue.delete(),
      'status': OrderStatus.ready.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Génère des commandes de démonstration dans Firestore pour tester le rôle livreur.
  Future<void> createDemoOrders() async {
    final demoList = [
      OrderModel(
        id: '',
        clientId: 'demo_client_1',
        clientName: 'Sami Mansour',
        clientPhone: '+216 98 111 222',
        deliveryAddress: 'Avenue Habib Bourguiba, Appt 3A, Ariana',
        vendorName: 'Pizzeria Bella Napoli',
        vendorAddress: '12 Rue de la Marsa, Tunis',
        vendorPhone: '+216 71 222 333',
        items: const [
          OrderItem(
            productId: 'demo_p1',
            name: 'Pizza Margherita XL',
            price: 18.0,
            quantity: 2,
            shopName: 'Pizzeria Bella Napoli',
          ),
          OrderItem(
            productId: 'demo_p2',
            name: 'Coca-Cola 1.5L',
            price: 4.0,
            quantity: 1,
            shopName: 'Pizzeria Bella Napoli',
          ),
        ],
        subtotal: 40.0,
        deliveryFee: 6.0,
        discount: 0.0,
        total: 46.0,
        status: OrderStatus.ready,
        createdAt: DateTime.now(),
        paymentMethod: 'Paiement à la livraison (Espèces)',
        notes: 'Sonner à l interphone Mansour',
      ),
      OrderModel(
        id: '',
        clientId: 'demo_client_2',
        clientName: 'Amina Triki',
        clientPhone: '+216 22 444 555',
        deliveryAddress: 'Résidence les Jasmin, Bloc B, Ennasr 2',
        vendorName: 'Tech Store Express',
        vendorAddress: 'Centre Commercial Carrefour, Marsa',
        vendorPhone: '+216 70 888 999',
        items: const [
          OrderItem(
            productId: 'demo_p3',
            name: 'Écouteurs Sans Fil Bluetooth',
            price: 85.0,
            quantity: 1,
            shopName: 'Tech Store Express',
          ),
        ],
        subtotal: 85.0,
        deliveryFee: 7.5,
        discount: 5.0,
        total: 87.5,
        status: OrderStatus.preparing,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        paymentMethod: 'Paiement à la livraison (Espèces)',
        notes: 'Appeler avant d arriver',
      ),
      OrderModel(
        id: '',
        clientId: 'demo_client_3',
        clientName: 'Youssef Trabelsi',
        clientPhone: '+216 55 777 888',
        deliveryAddress: '15 Rue des Oliviers, Lac 1, Tunis',
        vendorName: 'Boulangerie Patisserie Gourmet',
        vendorAddress: 'Les Berges du Lac 2, Tunis',
        vendorPhone: '+216 71 999 000',
        items: const [
          OrderItem(
            productId: 'demo_p4',
            name: 'Boîte de 12 Croissants',
            price: 24.0,
            quantity: 1,
            shopName: 'Boulangerie Patisserie Gourmet',
          ),
        ],
        subtotal: 24.0,
        deliveryFee: 5.0,
        discount: 0.0,
        total: 29.0,
        status: OrderStatus.ready,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        paymentMethod: 'Paiement en ligne',
      ),
    ];

    for (final order in demoList) {
      await _orders.add(order.toMap());
    }
  }

  /// Met à jour le profil du livreur.
  Future<void> updateCourierProfile({
    required String courierId,
    required String name,
    required String phone,
    required String vehicleType,
    required String plateNumber,
    required String city,
  }) async {
    await _db.collection('users').doc(courierId).set({
      'name': name,
      'phone': phone,
      'profile': {
        'vehicleType': vehicleType,
        'plateNumber': plateNumber,
        'city': city,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
