import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../models/order_model.dart';

class NotificationService {
  final FirebaseFirestore _db;

  // Cache en mémoire pour garantir l'affichage immédiat sans blocage de chargement
  static final Map<String, List<NotificationModel>> _localCache = {};
  static final StreamController<String> _localUpdatesController = StreamController<String>.broadcast();

  NotificationService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notifications => _db.collection('notifications');

  /// Écoute les notifications d'un utilisateur en temps réel (triées par date décroissante).
  Stream<List<NotificationModel>> watchUserNotifications(String userId) async* {
    if (userId.isEmpty) {
      yield [];
      return;
    }

    // Émettre immédiatement les données actuelles en mémoire (évite tout écran de chargement infini)
    final cached = _localCache[userId] ?? [];
    yield List<NotificationModel>.from(cached);

    final controller = StreamController<List<NotificationModel>>.broadcast();

    void notifyLatest(List<NotificationModel> remote) {
      final map = <String, NotificationModel>{};
      for (final n in (_localCache[userId] ?? [])) {
        final key = n.id.isNotEmpty ? n.id : '${n.title}_${n.createdAt.millisecondsSinceEpoch}';
        map[key] = n;
      }
      for (final n in remote) {
        final key = n.id.isNotEmpty ? n.id : '${n.title}_${n.createdAt.millisecondsSinceEpoch}';
        map[key] = n;
      }
      final merged = map.values.toList();
      merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _localCache[userId] = merged;
      if (!controller.isClosed) {
        controller.add(merged);
      }
    }

    StreamSubscription? firestoreSub;
    StreamSubscription? localSub;

    try {
      firestoreSub = _notifications
          .where('userId', isEqualTo: userId)
          .snapshots()
          .listen(
        (snapshot) {
          final list = <NotificationModel>[];
          for (final doc in snapshot.docs) {
            try {
              list.add(NotificationModel.fromMap(doc.id, doc.data()));
            } catch (e) {
              debugPrint('[NotificationService] fromMap error doc ${doc.id}: $e');
            }
          }
          notifyLatest(list);
        },
        onError: (err) {
          debugPrint('[NotificationService] Firestore stream error (permissions ou réseau): $err');
          if (!controller.isClosed) {
            controller.add(_localCache[userId] ?? []);
          }
        },
      );
    } catch (e) {
      debugPrint('[NotificationService] Listen setup error: $e');
      if (!controller.isClosed) {
        controller.add(_localCache[userId] ?? []);
      }
    }

    localSub = _localUpdatesController.stream.listen((uid) {
      if (uid == userId || uid == 'all') {
        if (!controller.isClosed) {
          controller.add(_localCache[userId] ?? []);
        }
      }
    });

    controller.onCancel = () {
      firestoreSub?.cancel();
      localSub?.cancel();
    };

    yield* controller.stream;
  }

  /// S'assure que l'utilisateur a au moins une notification d'accueil dans sa boîte
  Future<void> ensureWelcomeNotification({
    required String userId,
    required String userName,
    required bool isVendor,
  }) async {
    if (userId.isEmpty) return;

    try {
      final snap = await _notifications
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        if (isVendor) {
          await sendNotification(
            userId: userId,
            title: '🏪 Espace Vendeur actif',
            message: 'Bienvenue $userName. Vous recevrez ici vos alertes de nouvelles commandes en direct.',
            type: NotificationType.info,
          );
        } else {
          await sendNotification(
            userId: userId,
            title: '👋 Bienvenue sur Livraison Rapide !',
            message: 'Bonjour $userName ! Suivez vos commandes et recevez les alertes de vos livraisons ici en temps réel.',
            type: NotificationType.info,
          );
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] ensureWelcomeNotification error: $e');
    }
  }

  /// Écoute le nombre de notifications non lues.
  Stream<int> watchUnreadCount(String userId) {
    if (userId.isEmpty) {
      return Stream.value(0);
    }

    return watchUserNotifications(userId).map((list) {
      return list.where((n) => !n.isRead).length;
    });
  }

  /// Envoie une notification à un utilisateur.
  Future<String?> sendNotification({
    required String userId,
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    String? orderId,
  }) async {
    if (userId.isEmpty) return null;

    final tempId = 'notif_${DateTime.now().microsecondsSinceEpoch}';
    final model = NotificationModel(
      id: tempId,
      userId: userId,
      title: title,
      message: message,
      type: type,
      orderId: orderId,
      createdAt: DateTime.now(),
    );

    // 1. Mise à jour instantanée du cache local et notification des abonnés UI
    _localCache.putIfAbsent(userId, () => []);
    _localCache[userId]!.insert(0, model);
    _localUpdatesController.add(userId);

    // 2. Persistance dans Firestore
    try {
      final ref = await _notifications.add(model.toMap());
      debugPrint('[NotificationService] ✅ Notification persistée Firestore id: ${ref.id} pour userId: $userId');
      return ref.id;
    } catch (e) {
      debugPrint('[NotificationService] ⚠️ Échec écriture Firestore: $e (notification maintenue en mémoire)');
      return tempId;
    }
  }

  /// Marque une notification comme lue.
  Future<void> markAsRead(String notificationId) async {
    if (notificationId.isEmpty) return;
    for (final list in _localCache.values) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].id == notificationId) {
          list[i] = list[i].copyWith(isRead: true);
        }
      }
    }
    _localUpdatesController.add('all');
    try {
      await _notifications.doc(notificationId).update({'isRead': true});
    } catch (e) {
      debugPrint('[NotificationService] Erreur markAsRead: $e');
    }
  }

  /// Marque toutes les notifications d'un utilisateur comme lues.
  Future<void> markAllAsRead(String userId) async {
    if (userId.isEmpty) return;
    final cached = _localCache[userId];
    if (cached != null) {
      for (int i = 0; i < cached.length; i++) {
        cached[i] = cached[i].copyWith(isRead: true);
      }
      _localUpdatesController.add(userId);
    }
    try {
      final snap = await _notifications
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _db.batch();
      for (final doc in snap.docs) {
        if ((doc.data()['isRead'] as bool?) != true) {
          batch.update(doc.reference, {'isRead': true});
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[NotificationService] Erreur markAllAsRead: $e');
    }
  }

  /// Supprime une notification.
  Future<void> deleteNotification(String notificationId) async {
    if (notificationId.isEmpty) return;
    for (final list in _localCache.values) {
      list.removeWhere((n) => n.id == notificationId);
    }
    _localUpdatesController.add('all');
    try {
      await _notifications.doc(notificationId).delete();
    } catch (e) {
      debugPrint('[NotificationService] Erreur deleteNotification: $e');
    }
  }

  /// Notifie le vendeur lors d'une nouvelle commande passée par un client.
  Future<void> notifyVendorNewOrder({
    required String vendorId,
    required String clientName,
    required double total,
    required String orderId,
  }) async {
    await sendNotification(
      userId: vendorId,
      title: '🛎️ Nouvelle commande reçue !',
      message: 'Commande de $clientName pour un total de ${total.toStringAsFixed(2)} DT. Préparez-la rapidement !',
      type: NotificationType.orderNew,
      orderId: orderId,
    );
  }

  /// Notification de bienvenue pour le livreur.
  Future<void> ensureWelcomeNotificationLivreur({
    required String courierId,
    required String courierName,
  }) async {
    if (courierId.isEmpty) return;
    try {
      final snap = await _notifications
          .where('userId', isEqualTo: courierId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        await sendNotification(
          userId: courierId,
          title: '🛵 Espace Livreur actif',
          message:
              'Bienvenue $courierName ! Vous recevrez ici vos alertes de nouvelles courses disponibles en temps réel.',
          type: NotificationType.info,
        );
      }
    } catch (e) {
      debugPrint('[NotificationService] ensureWelcomeNotificationLivreur error: $e');
    }
  }

  /// Notifie un livreur qu'une nouvelle course est disponible.
  Future<void> notifyLivreurNewDelivery({
    required String courierId,
    required String vendorName,
    required String deliveryAddress,
    required double deliveryFee,
    required String orderId,
  }) async {
    await sendNotification(
      userId: courierId,
      title: '🛵 Nouvelle course disponible !',
      message:
          'Récupération chez $vendorName → $deliveryAddress. Commission : ${deliveryFee.toStringAsFixed(2)} DT.',
      type: NotificationType.orderNew,
      orderId: orderId,
    );
  }

  /// Notifie tous les livreurs qu'une nouvelle course est disponible sur la plateforme.
  Future<void> notifyAllLivreursNewDelivery({
    required String vendorName,
    required String deliveryAddress,
    required double deliveryFee,
    required String orderId,
  }) async {
    try {
      final targetIds = <String>{};

      final snapLivreurs = await _db
          .collection('users')
          .where('role', isEqualTo: 'livreur')
          .get();
      for (final doc in snapLivreurs.docs) {
        targetIds.add(doc.id);
      }

      final snapCouriers = await _db
          .collection('users')
          .where('role', isEqualTo: 'courier')
          .get();
      for (final doc in snapCouriers.docs) {
        targetIds.add(doc.id);
      }

      debugPrint('[NotificationService] notifyAllLivreurs: ${targetIds.length} livreur(s) ciblé(s)');

      for (final id in targetIds) {
        await notifyLivreurNewDelivery(
          courierId: id,
          vendorName: vendorName,
          deliveryAddress: deliveryAddress,
          deliveryFee: deliveryFee,
          orderId: orderId,
        );
      }
    } catch (e) {
      debugPrint('[NotificationService] notifyAllLivreursNewDelivery error: $e');
    }
  }

  /// Notifie le vendeur quand un livreur accepte sa commande.
  Future<void> notifyVendorOrderPickedUp({
    required String vendorId,
    required String courierName,
    required String orderId,
  }) async {
    await sendNotification(
      userId: vendorId,
      title: '🛵 Livreur en route vers vous',
      message:
          '$courierName a accepté la commande et arrive pour la récupérer. Préparez le colis !',
      type: NotificationType.orderDelivering,
      orderId: orderId,
    );
  }

  /// Notifie le vendeur quand sa commande est livrée.
  Future<void> notifyVendorOrderDelivered({
    required String vendorId,
    required String orderId,
    required String clientName,
  }) async {
    await sendNotification(
      userId: vendorId,
      title: '✅ Commande livrée avec succès',
      message:
          'La commande de $clientName a été livrée avec succès. Bravo pour votre service !',
      type: NotificationType.orderDelivered,
      orderId: orderId,
    );
  }

  /// Notifie le client lors d'un changement de statut de sa commande.
  Future<void> notifyClientOrderStatus({
    required String clientId,
    required String orderId,
    required OrderStatus status,
    String? shopName,
  }) async {
    final shop = shopName?.isNotEmpty == true ? shopName! : 'Le restaurant';

    String title;
    String message;
    NotificationType type;

    switch (status) {
      case OrderStatus.preparing:
        title = '👨‍🍳 Commande en préparation';
        message = '$shop prépare actuellement votre commande.';
        type = NotificationType.orderStatus;
        break;
      case OrderStatus.ready:
        title = '📦 Commande prête !';
        message = 'Votre commande est prête chez $shop. Un livreur va la récupérer.';
        type = NotificationType.orderStatus;
        break;
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
      case OrderStatus.delivering:
        title = '🛵 Commande en cours de livraison';
        message = 'Votre livreur est en route vers votre adresse. Suivez-le en direct !';
        type = NotificationType.orderDelivering;
        break;
      case OrderStatus.delivered:
        title = '🎉 Commande livrée avec succès !';
        message = 'Votre commande a été livrée. Bon appétit et à bientôt !';
        type = NotificationType.orderDelivered;
        break;
      case OrderStatus.cancelled:
        title = '❌ Commande annulée';
        message = 'Votre commande a été annulée.';
        type = NotificationType.orderCancelled;
        break;
      case OrderStatus.pending:
        title = '📝 Commande reçue';
        message = 'Votre commande est en attente de validation par $shop.';
        type = NotificationType.orderStatus;
        break;
    }

    await sendNotification(
      userId: clientId,
      title: title,
      message: message,
      type: type,
      orderId: orderId,
    );
  }
}
