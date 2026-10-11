import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class CatalogService {
  final FirebaseFirestore _db;

  CatalogService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  static const List<Product> defaultProducts = [];

  /// Récupère les produits depuis Firestore.
  Stream<List<Product>> watchProducts() {
    return _db.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromMap(doc.id, doc.data())).toList();
    }).handleError((_) => <Product>[]);
  }
}
