import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/courier_location.dart';
import '../models/order_model.dart';
import '../services/location_tracking_service.dart';

/// Informations complètes sur un point d'arrêt / étape de la livraison
class RoutePointInfo {
  final LatLng position;
  final String title;
  final String subtitle;
  final String role;
  final IconData icon;
  final Color color;

  const RoutePointInfo({
    required this.position,
    required this.title,
    required this.subtitle,
    required this.role,
    required this.icon,
    required this.color,
  });
}

/// Résultat complet de la résolution de l'itinéraire de livraison
class DeliveryRouteResult {
  final RoutePointInfo vendorPoint;
  final RoutePointInfo courierPoint;
  final RoutePointInfo destinationPoint;
  final List<LatLng> fullRoute;
  final List<LatLng> completedSegment;
  final List<LatLng> remainingSegment;
  final Map<String, dynamic> etaInfo;
  final bool hasLiveGps;

  const DeliveryRouteResult({
    required this.vendorPoint,
    required this.courierPoint,
    required this.destinationPoint,
    required this.fullRoute,
    required this.completedSegment,
    required this.remainingSegment,
    required this.etaInfo,
    required this.hasLiveGps,
  });
}

/// Utilitaire de géolocalisation et de calcul d'itinéraire pour le suivi en direct
class RouteCoordinatesHelper {
  // Coordonnées de référence pour les villes et quartiers
  static final Map<String, LatLng> _knownCoordinates = {
    'tunis': const LatLng(36.8065, 10.1815),
    'centre ville': const LatLng(36.8000, 10.1800),
    'ariana': const LatLng(36.8665, 10.1956),
    'la marsa': const LatLng(36.8782, 10.3247),
    'marsa': const LatLng(36.8782, 10.3247),
    'carthage': const LatLng(36.8528, 10.3233),
    'sidi bou said': const LatLng(36.8700, 10.3417),
    'lac 1': const LatLng(36.8325, 10.2341),
    'les berges du lac': const LatLng(36.8325, 10.2341),
    'lac 2': const LatLng(36.8450, 10.2700),
    'lac': const LatLng(36.8380, 10.2450),
    'ennasr': const LatLng(36.8572, 10.1589),
    'menzah': const LatLng(36.8392, 10.1784),
    'manar': const LatLng(36.8340, 10.1450),
    'bardo': const LatLng(36.8092, 10.1406),
    'sousse': const LatLng(35.8256, 10.6369),
    'sfax': const LatLng(34.7406, 10.7603),
    'nabeul': const LatLng(36.4561, 10.7376),
    'hammamet': const LatLng(36.4000, 10.6167),
    'kelibia': const LatLng(36.8480, 11.0939),
    'kélibia': const LatLng(36.8480, 11.0939),
    'oued el khatf': const LatLng(36.8650, 11.0800),
    'oued khatf': const LatLng(36.8650, 11.0800),
    'haouaria': const LatLng(37.0500, 11.0167),
    'el haouaria': const LatLng(37.0500, 11.0167),
    'menzel temime': const LatLng(36.7825, 10.9903),
    'korba': const LatLng(36.5786, 10.8586),
    'bizerte': const LatLng(37.2744, 9.8739),
    'monastir': const LatLng(35.7779, 10.8261),
    'mahdia': const LatLng(35.5047, 11.0622),
    'kairouan': const LatLng(35.6781, 10.0963),
    'gabes': const LatLng(33.8815, 10.0982),
    'djerba': const LatLng(33.8750, 10.8580),
    'zarzis': const LatLng(33.5042, 11.1122),
    'gafsa': const LatLng(34.4250, 8.7842),
    'tozeur': const LatLng(33.9197, 8.1336),
  };

  /// Résout les coordonnées géographiques à partir d'une chaîne d'adresse
  static LatLng? resolveAddress(String? address) {
    if (address == null || address.trim().isEmpty) return null;
    final lower = address.trim().toLowerCase();
    for (final entry in _knownCoordinates.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Résout les 3 points clés de l'itinéraire :
  /// 1. Boutique (Point de départ / Retrait)
  /// 2. Livreur (Position en direct ou intermédiaire)
  /// 3. Destination (Point d'arrivée / Client)
  static DeliveryRouteResult resolveOrderRoute({
    required OrderModel order,
    CourierLocation? liveLocation,
    LatLng? explicitDestination,
    LatLng? explicitVendor,
  }) {
    // 1. Détermination de la position du Livreur
    bool hasLiveGps = false;
    LatLng courierPos;

    if (liveLocation != null &&
        liveLocation.latitude != 0.0 &&
        liveLocation.longitude != 0.0) {
      courierPos = LatLng(liveLocation.latitude, liveLocation.longitude);
      hasLiveGps = liveLocation.isActive;
    } else if (order.courierLatitude != null &&
        order.courierLatitude != 0.0 &&
        order.courierLongitude != null &&
        order.courierLongitude != 0.0) {
      courierPos = LatLng(order.courierLatitude!, order.courierLongitude!);
      hasLiveGps = order.isTrackingActive ?? false;
    } else {
      // Coordonnées par défaut (Tunis centre)
      courierPos = const LatLng(36.8065, 10.1815);
    }

    // 2. Détermination de la position de la Boutique
    LatLng vendorPos;
    if (explicitVendor != null) {
      vendorPos = explicitVendor;
    } else if (order.vendorLatitude != null &&
        order.vendorLatitude != 0.0 &&
        order.vendorLongitude != null &&
        order.vendorLongitude != 0.0) {
      vendorPos = LatLng(order.vendorLatitude!, order.vendorLongitude!);
    } else {
      final resolved = resolveAddress(order.vendorAddress) ??
          resolveAddress(order.vendorName);
      if (resolved != null) {
        vendorPos = resolved;
      } else {
        // Décalage stable vers le nord-ouest
        vendorPos = LatLng(courierPos.latitude - 0.009, courierPos.longitude - 0.008);
      }
    }

    // 3. Détermination de la position du Client (Destination)
    LatLng destPos;
    if (explicitDestination != null) {
      destPos = explicitDestination;
    } else if (order.clientLatitude != null &&
        order.clientLatitude != 0.0 &&
        order.clientLongitude != null &&
        order.clientLongitude != 0.0) {
      // ✅ Position GPS réelle du client enregistrée lors de la commande
      destPos = LatLng(order.clientLatitude!, order.clientLongitude!);
    } else {
      final resolved = resolveAddress(order.deliveryAddress);
      if (resolved != null) {
        destPos = resolved;
      } else {
        // ✅ Quand aucune coordonnée client n'est enregistrée et que les deux appareils
        // (téléphone et PC) sont au même endroit pour le test, la position du client
        // correspond exactement à celle du livreur / point de départ actuel
        destPos = courierPos;
      }
    }

    // Si la boutique et la destination sont identiques (ex: même ville sans adresse précise),
    // créer un léger décalage visuel de la boutique uniquement pour visualiser le point de départ
    if ((vendorPos.latitude - destPos.latitude).abs() < 0.0001 &&
        (vendorPos.longitude - destPos.longitude).abs() < 0.0001) {
      vendorPos = LatLng(vendorPos.latitude - 0.004, vendorPos.longitude - 0.004);
    }

    // Ajustement du livreur selon l'état de la commande si pas de GPS actif
    if (!hasLiveGps) {
      if (order.status == OrderStatus.assigned) {
        // Livreur proche de la boutique
        courierPos = LatLng(
          vendorPos.latitude + 0.001,
          vendorPos.longitude + 0.001,
        );
      } else if (order.status == OrderStatus.pickedUp ||
          order.status == OrderStatus.delivering) {
        // Livreur à mi-chemin entre la boutique et le client (si points distincts)
        if ((destPos.latitude - vendorPos.latitude).abs() > 0.0005) {
          courierPos = LatLng(
            (vendorPos.latitude + destPos.latitude) / 2,
            (vendorPos.longitude + destPos.longitude) / 2,
          );
        }
      } else if (order.status == OrderStatus.delivered) {
        courierPos = destPos;
      }
    }

    // Noms sous les points
    final vendorName = order.vendorName.trim().isNotEmpty
        ? order.vendorName.trim()
        : 'Boutique Partenaire';
    final vendorSubtitle = order.vendorAddress.trim().isNotEmpty
        ? order.vendorAddress.trim()
        : 'Point de retrait';

    final courierName = order.courierName?.trim().isNotEmpty == true
        ? order.courierName!.trim()
        : 'Livreur en route';
    final courierSubtitle = hasLiveGps
        ? ((liveLocation?.speed != null && liveLocation!.speed! > 0)
            ? '${(liveLocation.speed! * 3.6).toStringAsFixed(0)} km/h • En direct'
            : 'En direct • Signal GPS actif')
        : (order.status == OrderStatus.delivering
            ? 'En cours de livraison'
            : order.status.label);

    final clientName = order.clientName.trim().isNotEmpty
        ? order.clientName.trim()
        : 'Client';
    final clientSubtitle = order.deliveryAddress.trim().isNotEmpty
        ? order.deliveryAddress.trim()
        : 'Adresse de livraison';

    final vendorPoint = RoutePointInfo(
      position: vendorPos,
      title: vendorName,
      subtitle: vendorSubtitle,
      role: 'Point de retrait',
      icon: Icons.storefront_rounded,
      color: const Color(0xFF8B5CF6), // Violet / Ambre élégant
    );

    final courierPoint = RoutePointInfo(
      position: courierPos,
      title: courierName,
      subtitle: courierSubtitle,
      role: 'Livreur',
      icon: Icons.two_wheeler_rounded,
      color: const Color(0xFFEA580C), // Orange vif
    );

    final destinationPoint = RoutePointInfo(
      position: destPos,
      title: clientName,
      subtitle: clientSubtitle,
      role: 'Point de livraison',
      icon: Icons.home_rounded,
      color: const Color(0xFF10B981), // Vert émeraude
    );

    // Construction des segments de trajet
    final completedSegment = <LatLng>[vendorPos, courierPos];
    final remainingSegment = <LatLng>[courierPos, destPos];
    final fullRoute = <LatLng>[vendorPos, courierPos, destPos];

    // Calcul ETA & distance restante jusqu'à la destination
    final etaInfo = LocationTrackingService.calculateDistanceAndEta(
      startLat: courierPos.latitude,
      startLng: courierPos.longitude,
      endLat: destPos.latitude,
      endLng: destPos.longitude,
    );

    return DeliveryRouteResult(
      vendorPoint: vendorPoint,
      courierPoint: courierPoint,
      destinationPoint: destinationPoint,
      fullRoute: fullRoute,
      completedSegment: completedSegment,
      remainingSegment: remainingSegment,
      etaInfo: etaInfo,
      hasLiveGps: hasLiveGps,
    );
  }
}
