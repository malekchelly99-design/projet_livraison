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

  /// Nettoie toutes les commandes de test / démo de la collection orders.
  Future<int> purgeDemoOrders() async {
    final snapshot = await _orders.get();
    int count = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final clientId = (data['clientId'] as String? ?? '').toLowerCase();
      final clientName = (data['clientName'] as String? ?? '').toLowerCase();
      final vendorName = (data['vendorName'] as String? ?? '').toLowerCase();
      final docId = doc.id.toLowerCase();

      final isDemo = docId.startsWith('demo_') ||
          clientId.startsWith('demo_') ||
          clientName.contains('demo') ||
          clientName.contains('sami mansour') ||
          clientName.contains('amina triki') ||
          clientName.contains('youssef trabelsi') ||
          vendorName.contains('bella napoli') ||
          vendorName.contains('tech store express') ||
          vendorName.contains('boulangerie gourmet');

      if (isDemo) {
        await doc.reference.delete();
        count++;
      }
    }
    return count;
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

  /// Écoute toutes les commandes de la plateforme en temps réel (pour l'admin).
  Stream<List<OrderModel>> watchAllOrders() {
    return _orders.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return OrderModel.fromMap(doc.id, doc.data());
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Assigne manuellement un livreur à une commande (action admin).
  Future<void> assignCourierByAdmin({
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

  /// Supprime une commande (action admin).
  Future<void> deleteOrder(String orderId) {
    return _orders.doc(orderId).delete();
  }
}

