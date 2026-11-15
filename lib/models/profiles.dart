/// Infos professionnelles d'un vendeur.
class ShopProfile {
  final String shopName;
  final String? category;
  final String address;
  final String city;

  /// Matricule fiscal (optionnel).
  final String taxId;

  /// Description de la boutique / spécialité.
  final String description;

  /// Horaires d'ouverture.
  final String horaires;

  const ShopProfile({
    required this.shopName,
    required this.category,
    required this.address,
    required this.city,
    required this.taxId,
    this.description = '',
    this.horaires = '08:00 - 22:00',
  });

  Map<String, dynamic> toMap() => {
        'shopName': shopName,
        'category': category,
        'address': address,
        'city': city,
        'taxId': taxId,
        'description': description,
        'horaires': horaires,
      };
}

/// Infos professionnelles d'un livreur.
class CourierProfile {
  final String cin;
  final String? vehicleType;
  final String plateNumber;
  final String city;

  const CourierProfile({
    required this.cin,
    required this.vehicleType,
    required this.plateNumber,
    required this.city,
  });

  Map<String, dynamic> toMap() => {
        'cin': cin,
        'vehicleType': vehicleType,
        'plateNumber': plateNumber,
        'city': city,
      };
}
