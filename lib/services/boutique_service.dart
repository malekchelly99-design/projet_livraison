import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/boutique_model.dart';

/// Accès à la collection Firestore `boutiques`.
///
/// Un document par boutique / vendeur : l'id du document est l'uid du vendeur
/// (garantit l'unicité et le lien direct avec son compte utilisateur).
class BoutiqueService {
  final FirebaseFirestore _db;

  BoutiqueService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _boutiques =>
      _db.collection('boutiques');

  Map<String, dynamic> _data({
    required String vendeurId,
    required String nomBoutique,
    required String? categorie,
    required String adresse,
    required String ville,
    required String matriculeFiscale,
    required String nomResponsable,
    required String email,
    required String telephone,
    String description = '',
    String horaires = '08:00 - 22:00',
  }) =>
      {
        'id': vendeurId,
        'vendeurId': vendeurId,
        'nomBoutique': nomBoutique.trim(),
        'shopName': nomBoutique.trim(), // Alias pour compatibilité
        'categorie': categorie?.trim().isNotEmpty == true ? categorie!.trim() : 'Autre',
        'category': categorie?.trim().isNotEmpty == true ? categorie!.trim() : 'Autre',
        'adresse': adresse.trim(),
        'address': adresse.trim(),
        'ville': ville.trim(),
        'city': ville.trim(),
        'matriculeFiscale': matriculeFiscale.trim(),
        'taxId': matriculeFiscale.trim(),
        'nomResponsable': nomResponsable.trim(),
        'email': email.trim(),
        'telephone': telephone.trim(),
        'phone': telephone.trim(),
        'description': description.trim(),
        'horaires': horaires.trim(),
        'disponible': true,
        'isOpen': true,
        'rating': 5.0,
      };

  /// Crée la fiche boutique à l'inscription du vendeur avec tous ses attributs.
  Future<void> create({
    required String vendeurId,
    required String nomBoutique,
    required String? categorie,
    required String adresse,
    required String ville,
    required String matriculeFiscale,
    required String nomResponsable,
    required String email,
    required String telephone,
    String description = '',
    String horaires = '08:00 - 22:00',
  }) {
    return _boutiques.doc(vendeurId).set({
      ..._data(
        vendeurId: vendeurId,
        nomBoutique: nomBoutique,
        categorie: categorie,
        adresse: adresse,
        ville: ville,
        matriculeFiscale: matriculeFiscale,
        nomResponsable: nomResponsable,
        email: email,
        telephone: telephone,
        description: description,
        horaires: horaires,
      ),
      'totalVentes': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Met à jour la fiche (ou la crée si elle n'existe pas encore).
  Future<void> sync({
    required String vendeurId,
    required String nomBoutique,
    required String? categorie,
    required String adresse,
    required String ville,
    required String matriculeFiscale,
    required String nomResponsable,
    required String email,
    required String telephone,
    String description = '',
    String horaires = '08:00 - 22:00',
  }) {
    return _boutiques.doc(vendeurId).set({
      ..._data(
        vendeurId: vendeurId,
        nomBoutique: nomBoutique,
        categorie: categorie,
        adresse: adresse,
        ville: ville,
        matriculeFiscale: matriculeFiscale,
        nomResponsable: nomResponsable,
        email: email,
        telephone: telephone,
        description: description,
        horaires: horaires,
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Écoute en temps réel la liste de toutes les boutiques.
  Stream<List<BoutiqueModel>> watchBoutiques() {
    return _boutiques.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BoutiqueModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Récupère la liste de toutes les boutiques.
  Future<List<BoutiqueModel>> getBoutiques() async {
    final snapshot = await _boutiques.get();
    return snapshot.docs
        .map((doc) => BoutiqueModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Récupère la fiche d'une boutique donnée.
  Future<BoutiqueModel?> getBoutique(String vendeurId) async {
    final doc = await _boutiques.doc(vendeurId).get();
    if (!doc.exists || doc.data() == null) return null;
    return BoutiqueModel.fromMap(doc.id, doc.data()!);
  }

  /// Ouvre / ferme la boutique.
  Future<void> setDisponible(String vendeurId, bool disponible) {
    return _boutiques.doc(vendeurId).set({
      'disponible': disponible,
      'isOpen': disponible,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Supprime une boutique.
  Future<void> delete(String vendeurId) => _boutiques.doc(vendeurId).delete();
}
