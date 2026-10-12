import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class CatalogService {
  final FirebaseFirestore _db;

  CatalogService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  static const List<Product> defaultProducts = [];

  /// Récupère tous les produits depuis Firestore.
  Stream<List<Product>> watchProducts() {
    return _db.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromMap(doc.id, doc.data())).toList();
    }).handleError((_) => <Product>[]);
  }

  /// Écoute les produits d'un vendeur spécifique.
  Stream<List<Product>> watchVendorProducts({String? shopName, String? vendorId}) {
    return _db.collection('products').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.id, doc.data()))
          .where((p) {
            if (vendorId != null && vendorId.isNotEmpty && p.vendorId == vendorId) {
              return true;
            }
            if (shopName != null &&
                shopName.isNotEmpty &&
                p.shopName.trim().toLowerCase() == shopName.trim().toLowerCase()) {
              return true;
            }
            return false;
          })
          .toList();
    }).handleError((_) => <Product>[]);
  }

  /// Ajoute un nouveau produit au catalogue.
  Future<String> addProduct(Product product) async {
    final docRef = await _db.collection('products').add(product.toMap());
    return docRef.id;
  }

  /// Met à jour un produit existant.
  Future<void> updateProduct(Product product) {
    return _db.collection('products').doc(product.id).update(product.toMap());
  }

  /// Supprime un produit du catalogue.
  Future<void> deleteProduct(String productId) {
    return _db.collection('products').doc(productId).delete();
  }
}
