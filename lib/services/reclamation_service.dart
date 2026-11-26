import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../models/reclamation_model.dart';
import 'notification_service.dart';

class ReclamationService {
  final FirebaseFirestore _db;
  final NotificationService _notificationService;

  ReclamationService({
    FirebaseFirestore? db,
    NotificationService? notificationService,
  })  : _db = db ?? FirebaseFirestore.instance,
        _notificationService = notificationService ?? NotificationService();

  static bool _tableInitialized = false;

  CollectionReference<Map<String, dynamic>> get _reclamations =>
      _db.collection('reclamations');

  /// S'assure que la collection 'reclamations' existe dans Firestore (une fois par session)
  Future<void> ensureTableExists() async {
    if (_tableInitialized) return;
    _tableInitialized = true;
    try {
      final snap = await _reclamations.limit(1).get();
      if (snap.docs.isEmpty) {
        await _reclamations.doc('_init_schema').set({
          'isSystemInit': true,
          'clientId': 'system',
          'clientName': 'Système',
          'clientPhone': '',
          'clientEmail': '',
          'vendorName': '',
          'subject': 'Initialisation table réclamations',
          'category': 'Autre',
          'description': 'Document technique initialisant la collection reclamations dans Firestore.',
          'status': 'resolue',
          'priority': 'basse',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      _tableInitialized = false;
    }
  }

  bool _isSystemDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return doc.id == '_init_schema' || doc.data()['isSystemInit'] == true;
  }

  /// Créer une nouvelle réclamation dans Firestore et notifier le vendeur et l'admin
  Future<String> createReclamation(ReclamationModel reclamation) async {
    try {
      final docRef = await _reclamations.add(reclamation.toMap());
      final recId = docRef.id;

      // 1. Notifier le client de la bonne prise en compte
      try {
        await _notificationService.sendNotification(
          userId: reclamation.clientId,
          title: '📩 Réclamation enregistrée',
          message: 'Votre réclamation "${reclamation.subject}" a été transmise à l\'équipe.',
          type: NotificationType.info,
          orderId: reclamation.orderId,
        );
      } catch (_) {}

      // 2. Notifier le vendeur concerné (s'il existe)
      if (reclamation.vendorId != null && reclamation.vendorId!.isNotEmpty) {
        try {
          await _notificationService.sendNotification(
            userId: reclamation.vendorId!,
            title: '⚠️ Nouvelle réclamation client',
            message: '${reclamation.clientName} a signalé un problème : "${reclamation.subject}"',
            type: NotificationType.orderStatus,
            orderId: reclamation.orderId,
          );
        } catch (_) {}
      }

      // 3. Notifier les administrateurs
      try {
        final adminSnaps = await _db.collection('users').where('role', isEqualTo: 'admin').get();
        for (final doc in adminSnaps.docs) {
          await _notificationService.sendNotification(
            userId: doc.id,
            title: '🔔 Réclamation signalée',
            message: 'Client: ${reclamation.clientName} • Boutique: ${reclamation.vendorName.isNotEmpty ? reclamation.vendorName : "Général"} • Objet: "${reclamation.subject}"',
            type: NotificationType.info,
            orderId: reclamation.orderId,
          );
        }
      } catch (_) {}

      return recId;
    } catch (e) {
      debugPrint('[ReclamationService] Erreur création réclamation : $e');
      rethrow;
    }
  }

  /// Écoute les réclamations d'un client en temps réel
  Stream<List<ReclamationModel>> watchClientReclamations(String clientId) {
    ensureTableExists();
    return _reclamations
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .where((doc) => !_isSystemDoc(doc))
          .map((doc) => ReclamationModel.fromMap(doc.id, doc.data()))
          .toList();

      // Tri local côté client pour éviter d'exiger un index composite Firestore
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((err) {
      debugPrint('[ReclamationService] Erreur watchClientReclamations: $err');
      return <ReclamationModel>[];
    });
  }

  /// Écoute les réclamations associées à une boutique / un vendeur
  Stream<List<ReclamationModel>> watchVendorReclamations({
    String? vendorId,
    String? vendorName,
  }) {
    ensureTableExists();
    return _reclamations.snapshots().map((snapshot) {
      final list = snapshot.docs
          .where((doc) => !_isSystemDoc(doc))
          .map((doc) => ReclamationModel.fromMap(doc.id, doc.data()))
          .where((rec) {
        if (vendorId != null && vendorId.isNotEmpty && rec.vendorId == vendorId) {
          return true;
        }
        if (vendorName != null &&
            vendorName.isNotEmpty &&
            rec.vendorName.trim().toLowerCase() == vendorName.trim().toLowerCase()) {
          return true;
        }
        return false;
      }).toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((err) {
      debugPrint('[ReclamationService] Erreur watchVendorReclamations: $err');
      return <ReclamationModel>[];
    });
  }

  /// Écoute toutes les réclamations (pour le panneau Administrateur)
  Stream<List<ReclamationModel>> watchAllReclamations() {
    ensureTableExists();
    return _reclamations.snapshots().map((snapshot) {
      final list = snapshot.docs
          .where((doc) => !_isSystemDoc(doc))
          .map((doc) => ReclamationModel.fromMap(doc.id, doc.data()))
          .toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((err) {
      debugPrint('[ReclamationService] Erreur watchAllReclamations: $err');
      return <ReclamationModel>[];
    });
  }

  /// Répondre à une réclamation (par le vendeur ou l'administrateur)
  Future<void> respondToReclamation({
    required String reclamationId,
    String? clientId,
    required String response,
    required String responderName,
    ReclamationStatus? newStatus,
    String? orderId,
  }) async {
    try {
      final status = newStatus ?? ReclamationStatus.enCours;
      final updateData = <String, dynamic>{
        'response': response,
        'respondedBy': responderName,
        'respondedAt': FieldValue.serverTimestamp(),
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == ReclamationStatus.resolue) {
        updateData['resolvedAt'] = FieldValue.serverTimestamp();
      }

      await _reclamations.doc(reclamationId).update(updateData);

      // Notifier le client de la réponse
      try {
        if (clientId == null) {
          final doc = await _reclamations.doc(reclamationId).get();
          final data = doc.data();
          if (data != null) {
            clientId = data['clientId'] as String?;
            orderId ??= data['orderId'] as String?;
          }
        }
        if (clientId != null && clientId.isNotEmpty) {
          await _notificationService.sendNotification(
            userId: clientId,
            title: '💬 Réponse à votre réclamation',
            message: '$responderName a répondu : "$response" (Statut : ${status.label})',
            type: NotificationType.info,
            orderId: orderId,
          );
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('[ReclamationService] Erreur respondToReclamation: $e');
      rethrow;
    }
  }

  /// Mettre à jour le statut d'une réclamation
  Future<void> updateStatus({
    required String reclamationId,
    String? clientId,
    required ReclamationStatus newStatus,
    String? orderId,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == ReclamationStatus.resolue) {
        updateData['resolvedAt'] = FieldValue.serverTimestamp();
      }

      await _reclamations.doc(reclamationId).update(updateData);

      // Notifier le client de la mise à jour
      try {
        if (clientId == null) {
          final doc = await _reclamations.doc(reclamationId).get();
          final data = doc.data();
          if (data != null) {
            clientId = data['clientId'] as String?;
            orderId ??= data['orderId'] as String?;
          }
        }
        if (clientId != null && clientId.isNotEmpty) {
          await _notificationService.sendNotification(
            userId: clientId,
            title: '📋 Statut de réclamation mis à jour',
            message: 'Votre réclamation est désormais : ${newStatus.label}.',
            type: NotificationType.orderStatus,
            orderId: orderId,
          );
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('[ReclamationService] Erreur updateStatus: $e');
      rethrow;
    }
  }
}
