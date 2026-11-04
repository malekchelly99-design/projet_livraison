import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant une boutique partenaire dans la table / collection `boutiques`.
class BoutiqueModel {
  final String id;
  final String vendeurId;
  final String nomBoutique;
  final String categorie;
  final String adresse;
  final String ville;
  final String matriculeFiscale;
  final String nomResponsable;
  final String email;
  final String telephone;
  final String description;
  final String horaires;
  final bool disponible;
  final double rating;
  final int totalVentes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BoutiqueModel({
    required this.id,
    required this.vendeurId,
    required this.nomBoutique,
    required this.categorie,
    required this.adresse,
    required this.ville,
    this.matriculeFiscale = '',
    required this.nomResponsable,
    required this.email,
    required this.telephone,
    this.description = '',
    this.horaires = '08:00 - 22:00',
    this.disponible = true,
    this.rating = 5.0,
    this.totalVentes = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Nom alternatif pour rétro-compatibilité
  String get shopName => nomBoutique;
  String get category => categorie;
  String get address => adresse;
  String get city => ville;
  String get phone => telephone;
  String get taxId => matriculeFiscale;

  factory BoutiqueModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      try {
        return (val as dynamic).toDate() as DateTime?;
      } catch (_) {
        return DateTime.tryParse(val.toString());
      }
    }

    return BoutiqueModel(
      id: id,
      vendeurId: (data['vendeurId'] as String?) ?? id,
      nomBoutique: (data['nomBoutique'] as String?) ?? (data['shopName'] as String?) ?? '',
      categorie: (data['categorie'] as String?) ?? (data['category'] as String?) ?? 'Autre',
      adresse: (data['adresse'] as String?) ?? (data['address'] as String?) ?? '',
      ville: (data['ville'] as String?) ?? (data['city'] as String?) ?? '',
      matriculeFiscale: (data['matriculeFiscale'] as String?) ?? (data['taxId'] as String?) ?? '',
      nomResponsable: (data['nomResponsable'] as String?) ?? (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      telephone: (data['telephone'] as String?) ?? (data['phone'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      horaires: (data['horaires'] as String?) ?? (data['openingHours'] as String?) ?? '08:00 - 22:00',
      disponible: (data['disponible'] as bool?) ?? (data['isOpen'] as bool?) ?? true,
      rating: ((data['rating'] as num?) ?? 5.0).toDouble(),
      totalVentes: (data['totalVentes'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'vendeurId': vendeurId,
        'nomBoutique': nomBoutique,
        'shopName': nomBoutique,
        'categorie': categorie,
        'category': categorie,
        'adresse': adresse,
        'address': adresse,
        'ville': ville,
        'city': ville,
        'matriculeFiscale': matriculeFiscale,
        'taxId': matriculeFiscale,
        'nomResponsable': nomResponsable,
        'email': email,
        'telephone': telephone,
        'phone': telephone,
        'description': description,
        'horaires': horaires,
        'disponible': disponible,
        'isOpen': disponible,
        'rating': rating,
        'totalVentes': totalVentes,
      };
}
