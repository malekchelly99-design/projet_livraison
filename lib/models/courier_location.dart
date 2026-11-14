import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant la géolocalisation en temps réel d'un livreur pour une commande.
class CourierLocation {
  final String id; // Identifiant (correspond généralement à l'orderId)
  final String courierId; // id_livreur
  final String orderId; // id_commande
  final double latitude;
  final double longitude;
  final DateTime updatedAt; // date_maj
  final double? heading; // Orientation en degrés (optionnel)
  final double? speed; // Vitesse en m/s (optionnel)
  final bool isActive; // Indique si le partage GPS est en cours

  const CourierLocation({
    required this.id,
    required this.courierId,
    required this.orderId,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
    this.heading,
    this.speed,
    this.isActive = true,
  });

  factory CourierLocation.fromMap(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return CourierLocation(
      id: id,
      courierId: (data['courierId'] as String?) ?? (data['id_livreur'] as String?) ?? '',
      orderId: (data['orderId'] as String?) ?? (data['id_commande'] as String?) ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      updatedAt: parseDate(data['updatedAt'] ?? data['date_maj']),
      heading: (data['heading'] as num?)?.toDouble(),
      speed: (data['speed'] as num?)?.toDouble(),
      isActive: (data['isActive'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'courierId': courierId,
        'id_livreur': courierId,
        'orderId': orderId,
        'id_commande': orderId,
        'latitude': latitude,
        'longitude': longitude,
        'updatedAt': FieldValue.serverTimestamp(),
        'date_maj': FieldValue.serverTimestamp(),
        if (heading != null) 'heading': heading,
        if (speed != null) 'speed': speed,
        'isActive': isActive,
      };

  CourierLocation copyWith({
    String? id,
    String? courierId,
    String? orderId,
    double? latitude,
    double? longitude,
    DateTime? updatedAt,
    double? heading,
    double? speed,
    bool? isActive,
  }) {
    return CourierLocation(
      id: id ?? this.id,
      courierId: courierId ?? this.courierId,
      orderId: orderId ?? this.orderId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      updatedAt: updatedAt ?? this.updatedAt,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      isActive: isActive ?? this.isActive,
    );
  }
}

