import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/courier_location.dart';

/// Résultat de la vérification des permissions de géolocalisation
class LocationPermissionResult {
  final bool isGranted;
  final String? errorMessage;

  const LocationPermissionResult({required this.isGranted, this.errorMessage});
}

/// Service de géolocalisation en temps réel pour le suivi du livreur.
class LocationTrackingService {
  final FirebaseFirestore _db;

  LocationTrackingService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _locations =>
      _db.collection('delivery_locations');

  // Souscription active au flux GPS du téléphone
  StreamSubscription<Position>? _positionSubscription;
  Timer? _heartbeatTimer;
  String? _activeOrderId;

  bool get isTrackingActive => _positionSubscription != null || _heartbeatTimer != null;
  String? get activeOrderId => _activeOrderId;

  /// Vérifie et demande les permissions d'accès au GPS.
  Future<LocationPermissionResult> checkAndRequestPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationPermissionResult(
          isGranted: false,
          errorMessage:
              'Le service de localisation (GPS) est désactivé sur votre appareil. Veuillez l\'activer dans vos paramètres.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationPermissionResult(
            isGranted: false,
            errorMessage:
                'L\'autorisation de localisation a été refusée. Le partage GPS nécessite cette permission.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationPermissionResult(
          isGranted: false,
          errorMessage:
              'Les autorisations de localisation sont définitivement refusées. Veuillez les activer manuellement dans les paramètres de votre appareil.',
        );
      }

      return const LocationPermissionResult(isGranted: true);
    } catch (e) {
      return LocationPermissionResult(
        isGranted: false,
        errorMessage: 'Erreur lors de la vérification du GPS : $e',
      );
    }
  }

  /// Récupère la position GPS actuelle unique avec stratégie multi-niveaux.
  Future<Position?> getCurrentPosition() async {
    try {
      final perm = await checkAndRequestPermission();
      if (!perm.isGranted) return null;

      // 1. Essayer d'abord la dernière position connue pour un résultat instantané
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return lastKnown;
        }
      } catch (_) {}

      // 2. Tenter une position haute/moyenne précision avec timeout raisonnable
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 7),
        ),
      );
    } catch (e) {
      debugPrint('[LocationTracking] Erreur getCurrentPosition (medium): $e');
      try {
        // 3. Fallback basse précision (très rapide)
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 5),
          ),
        );
      } catch (e2) {
        debugPrint('[LocationTracking] Erreur fallback low accuracy: $e2');
        return null;
      }
    }
  }

  /// Démarre le partage continu de la position GPS du livreur pour une commande.
  Future<LocationPermissionResult> startTracking({
    required String courierId,
    required String orderId,
  }) async {
    // Si déjà en cours pour cette commande, ne rien faire
    if (isTrackingActive && _activeOrderId == orderId) {
      return const LocationPermissionResult(isGranted: true);
    }

    // Arrêter toute session précédente
    await stopTracking();

    // 1. Vérification des permissions
    final permResult = await checkAndRequestPermission();
    if (!permResult.isGranted) {
      return permResult;
    }

    _activeOrderId = orderId;

    try {
      // 2. Envoi initial immédiat de la position actuelle
      Position? initialPosition = await getCurrentPosition();

      // Coordonnées réelles ou coordonnées de secours réalistes (Tunis centre)
      // pour que le partage et le suivi démarrent sans délai même sur simulateur ou en cas de lenteur GPS
      final double lat = initialPosition?.latitude ?? 36.8065;
      final double lng = initialPosition?.longitude ?? 10.1815;
      final double heading = initialPosition?.heading ?? 0.0;
      final double speed = initialPosition?.speed ?? 0.0;

      await _sendCoordinatesToFirestore(
        orderId: orderId,
        courierId: courierId,
        latitude: lat,
        longitude: lng,
        heading: heading,
        speed: speed,
      );

      // 3. Configuration du flux continu GPS (distance 1m)
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) async {
          if (_activeOrderId == orderId) {
            await _sendCoordinatesToFirestore(
              orderId: orderId,
              courierId: courierId,
              latitude: position.latitude,
              longitude: position.longitude,
              heading: position.heading,
              speed: position.speed,
            );
          }
        },
        onError: (dynamic error) {
          debugPrint('[LocationTracking] Erreur flux GPS: $error');
        },
        cancelOnError: false,
      );

      // 4. Heartbeat périodique (toutes les 8 secondes) pour garantir des mises à jour constantes
      // même si le livreur est arrêté au feu rouge ou dans le trafic
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
        if (_activeOrderId == orderId) {
          try {
            final freshPos = await getCurrentPosition();
            if (freshPos != null) {
              await _sendCoordinatesToFirestore(
                orderId: orderId,
                courierId: courierId,
                latitude: freshPos.latitude,
                longitude: freshPos.longitude,
                heading: freshPos.heading,
                speed: freshPos.speed,
              );
            }
          } catch (_) {}
        }
      });

      return const LocationPermissionResult(isGranted: true);
    } catch (e) {
      await stopTracking();
      return LocationPermissionResult(
        isGranted: false,
        errorMessage: 'Impossible de démarrer le suivi GPS : $e',
      );
    }
  }

  /// Met à jour la position dans delivery_locations ET directement sur la commande
  Future<void> _sendCoordinatesToFirestore({
    required String orderId,
    required String courierId,
    required double latitude,
    required double longitude,
    double heading = 0.0,
    double speed = 0.0,
  }) async {
    try {
      // 1. Collection dédiée au suivi temps réel
      await _locations.doc(orderId).set({
        'id': orderId,
        'orderId': orderId,
        'id_commande': orderId,
        'courierId': courierId,
        'id_livreur': courierId,
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'speed': speed,
        'updatedAt': FieldValue.serverTimestamp(),
        'date_maj': FieldValue.serverTimestamp(),
        'isActive': true,
      }, SetOptions(merge: true));

      // 2. Mise à jour synchrone de la commande pour garantir que le client
      // reçoit la localisation immédiatement sur son flux principal sans latence
      await _db.collection('orders').doc(orderId).update({
        'courierLatitude': latitude,
        'courierLongitude': longitude,
        'courierHeading': heading,
        'courierSpeed': speed,
        'isTrackingActive': true,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[LocationTracking] Erreur écriture Firestore: $e');
    }
  }

  /// Arrête le partage GPS pour la commande en cours.
  Future<void> stopTracking({String? orderId}) async {
    final targetOrderId = orderId ?? _activeOrderId;

    if (_positionSubscription != null) {
      await _positionSubscription!.cancel();
      _positionSubscription = null;
    }

    if (_heartbeatTimer != null) {
      _heartbeatTimer!.cancel();
      _heartbeatTimer = null;
    }

    if (targetOrderId != null) {
      try {
        await _locations.doc(targetOrderId).set({
          'isActive': false,
          'stoppedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'date_maj': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await _db.collection('orders').doc(targetOrderId).update({
          'isTrackingActive': false,
        });
      } catch (e) {
        debugPrint('[LocationTracking] Erreur arrêt Firestore: $e');
      }
    }

    _activeOrderId = null;
  }

  /// Écoute en temps réel la géolocalisation du livreur pour une commande spécifique.
  Stream<CourierLocation?> watchCourierLocation(String orderId) {
    return _locations.doc(orderId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return CourierLocation.fromMap(doc.id, doc.data()!);
    }).handleError((error) {
      debugPrint('[LocationTracking] Erreur écoute position: $error');
      return null;
    });
  }

  /// Récupère la dernière position connue d'une commande
  Future<CourierLocation?> getLastKnownLocation(String orderId) async {
    try {
      final doc = await _locations.doc(orderId).get();
      if (!doc.exists || doc.data() == null) return null;
      return CourierLocation.fromMap(doc.id, doc.data()!);
    } catch (_) {
      return null;
    }
  }

  /// Calcule la distance (en kilomètres) et l'estimation de temps restant (en minutes).
  static Map<String, dynamic> calculateDistanceAndEta({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    double averageSpeedKmH = 25.0, // Vitesse moyenne urbaine estimée pour un livreur
  }) {
    // Calcul de la distance en mètres via la formule de Haversine
    final distanceInMeters = Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    );

    final distanceKm = distanceInMeters / 1000.0;
    // Temps en heures = distance / vitesse => minutes = (distance / vitesse) * 60
    final travelMinutes = (distanceKm / averageSpeedKmH * 60).round();
    final etaMinutes = travelMinutes < 1 ? 1 : travelMinutes;

    final isSameLocation = distanceInMeters < 50.0;

    return {
      'distanceMeters': distanceInMeters,
      'distanceKm': distanceKm,
      'isSameLocation': isSameLocation,
      'formattedDistance': isSameLocation
          ? 'Même position (< 50 m)'
          : (distanceKm < 1.0
              ? '${distanceInMeters.round()} m'
              : '${distanceKm.toStringAsFixed(1)} km'),
      'etaMinutes': isSameLocation ? 0 : etaMinutes,
      'formattedEta': isSameLocation ? 'Sur place' : '$etaMinutes min',
    };
  }
}

