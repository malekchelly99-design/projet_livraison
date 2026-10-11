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
}
