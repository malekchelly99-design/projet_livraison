import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';

/// Service pour gérer la collection Firestore `payments`.
class PaymentService {
  final FirebaseFirestore _db;

  PaymentService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _payments => _db.collection('payments');

  /// Crée un paiement associé à une commande dans la collection `payments`.
  Future<String> createPaymentForOrder({
    required String orderId,
    required OrderModel order,
    String? sellerId,
  }) async {
    try {
      final methodStr = order.paymentMethod.toLowerCase().contains('espèces')
          ? 'cash'
          : (order.paymentMethod.toLowerCase().contains('carte') ? 'card' : order.paymentMethod);

      final isImmediatePaid = methodStr == 'card';

      final docRef = await _payments.add({
        'orderId': orderId,
        'clientId': order.clientId,
        'clientName': order.clientName,
        'sellerId': sellerId ?? '',
        'vendorName': order.vendorName,
        'amount': order.total,
        'method': methodStr,
        'paymentMethod': order.paymentMethod,
        'status': isImmediatePaid ? PaymentStatus.completed.name : PaymentStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ [PaymentService] Paiement créé avec ID: ${docRef.id} pour la commande $orderId (${order.total} DT)');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ [PaymentService] Erreur lors de la création du paiement: $e');
      rethrow;
    }
  }

  /// Met à jour le statut du paiement pour une commande (ex: commande livrée -> completed).
  Future<void> updatePaymentStatusByOrderId(String orderId, PaymentStatus status) async {
    try {
      final snap = await _payments.where('orderId', isEqualTo: orderId).get();
      for (final doc in snap.docs) {
        await doc.reference.update({
          'status': status.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      debugPrint('✅ [PaymentService] Statut paiement mis à jour pour commande $orderId -> ${status.name}');
    } catch (e) {
      debugPrint('❌ [PaymentService] Erreur mise à jour statut paiement: $e');
    }
  }

  /// Écoute tous les paiements en temps réel.
  Stream<List<PaymentModel>> watchPayments() {
    return _payments.snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != 'schema_template')
          .map((doc) => PaymentModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Écoute les paiements d'un client.
  Stream<List<PaymentModel>> watchClientPayments(String clientId) {
    return _payments
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != 'schema_template')
          .map((doc) => PaymentModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Rétro-synchronise les paiements pour toutes les commandes existantes dans Firestore
  /// qui n'ont pas encore de document dans `payments`.
  Future<int> syncMissingPayments() async {
    try {
      final ordersSnap = await _db.collection('orders').get();
      final paymentsSnap = await _payments.get();

      final existingOrderIds = paymentsSnap.docs
          .map((doc) => doc.data()['orderId'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .toSet();

      int count = 0;
      for (final orderDoc in ordersSnap.docs) {
        if (orderDoc.id.startsWith('demo_')) continue;
        if (!existingOrderIds.contains(orderDoc.id)) {
          final data = orderDoc.data();
          final order = OrderModel.fromMap(orderDoc.id, data);
          await createPaymentForOrder(orderId: orderDoc.id, order: order);
          count++;
        }
      }

      if (count > 0) {
        debugPrint('✅ [PaymentService] $count paiement(s) manquant(s) synchronisé(s) dans la base !');
      }
      return count;
    } catch (e) {
      debugPrint('⚠️  [PaymentService] Erreur lors de la synchronisation des paiements: $e');
      return 0;
    }
  }
}

