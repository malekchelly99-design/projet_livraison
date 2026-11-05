import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/product.dart';

class CatalogService {
  final FirebaseFirestore _db;

  CatalogService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  static const List<Product> defaultProducts = [];

  CollectionReference<Map<String, dynamic>> get _products => _db.collection('products');
  CollectionReference<Map<String, dynamic>> get _categories => _db.collection('categories');

  /// Récupère tous les produits depuis Firestore.
  Stream<List<Product>> watchProducts() {
    return _products.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromMap(doc.id, doc.data())).toList();
    }).handleError((err) {
      debugPrint('❌ Erreur watchProducts: $err');
      return <Product>[];
    });
  }

  /// Écoute les catégories depuis Firestore.
  Stream<List<CategoryModel>> watchCategories() {
    return _categories.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.id, doc.data()))
          .toList();
    }).handleError((err) {
      debugPrint('❌ Erreur watchCategories: $err');
      return <CategoryModel>[];
    });
  }

  /// Ajoute une catégorie.
  Future<String> addCategory(CategoryModel category) async {
    final docRef = await _categories.add(category.toMap());
    return docRef.id;
  }

  /// Supprime une catégorie.
  Future<void> deleteCategory(String categoryId) {
    return _categories.doc(categoryId).delete();
  }

  /// Écoute les produits d'un vendeur spécifique.
  Stream<List<Product>> watchVendorProducts({String? shopName, String? vendorId}) {
    return _products.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.id, doc.data()))
          .where((p) {
            if (vendorId != null && vendorId.isNotEmpty) {
              if (p.vendorId == vendorId || p.boutiqueId == vendorId) {
                return true;
              }
            }
            if (shopName != null &&
                shopName.isNotEmpty &&
                p.shopName.trim().toLowerCase() == shopName.trim().toLowerCase()) {
              return true;
            }
            return false;
          })
          .toList();
    }).handleError((err) {
      debugPrint('❌ Erreur watchVendorProducts: $err');
      return <Product>[];
    });
  }

  /// Ajoute un nouveau produit au catalogue.
  Future<String> addProduct(Product product) async {
    final data = {
      ...product.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final docRef = await _products.add(data);
    return docRef.id;
  }

  /// Met à jour un produit existant.
  Future<void> updateProduct(Product product) {
    final data = {
      ...product.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    return _products.doc(product.id).update(data);
  }

  /// Supprime un produit du catalogue.
  Future<void> deleteProduct(String productId) {
    return _products.doc(productId).delete();
  }

  /// Initialise les catégories par défaut dans Firestore si la collection est vide.
  Future<void> ensureDefaultCategories() async {
    final snap = await _categories.limit(1).get();
    if (snap.docs.isEmpty) {
      final defaults = [
        const CategoryModel(id: '', name: 'Restauration', icon: 'restaurant', description: 'Plats cuisinés et menus'),
        const CategoryModel(id: '', name: 'Pizzas & Fast-food', icon: 'local_pizza', description: 'Pizzas, burgers et sandwiches'),
        const CategoryModel(id: '', name: 'Épicerie', icon: 'local_grocery_store', description: 'Produits alimentaires et du quotidien'),
        const CategoryModel(id: '', name: 'Boulangerie & Pâtisserie', icon: 'bakery_dining', description: 'Pains, viennoiseries et gâteaux'),
        const CategoryModel(id: '', name: 'Boissons & Cafés', icon: 'local_cafe', description: 'Sodas, jus et boissons chaudes'),
        const CategoryModel(id: '', name: 'Pharmacie & Santé', icon: 'local_pharmacy', description: 'Parapharmacie et soins'),
      ];
      for (final cat in defaults) {
        await _categories.add(cat.toMap());
      }
    }
  }

  /// Nettoie tous les produits de test / démo de la collection products.
  Future<int> purgeDemoProducts() async {
    final snap = await _products.get();
    int count = 0;
    for (final doc in snap.docs) {
      final data = doc.data();
      final name = (data['name'] as String? ?? '').toLowerCase();
      final shopName = (data['shopName'] as String? ?? '').toLowerCase();
      final docId = doc.id.toLowerCase();

      final isDemo = docId.startsWith('demo_') ||
          name.contains('burger gourmet') ||
          name.contains('pizza truffe') ||
          name.contains('sandwich poulet') ||
          name.contains('tacos 3 viandes') ||
          name.contains('patisserie gourmande') ||
          shopName.contains('bella napoli') ||
          shopName.contains('tech store express') ||
          shopName.contains('boulangerie gourmet') ||
          shopName.contains('demo');

      if (isDemo) {
        await doc.reference.delete();
        count++;
      }
    }
    return count;
  }
}
