import 'package:flutter/material.dart';

/// Utilitaire partagé de gestion et filtrage intelligent des catégories
/// pour l'Espace Client et l'Espace Vendeur.
class CategoryMatcher {
  CategoryMatcher._();

  /// Catégories par défaut unifiées
  static const List<String> defaultCategoryNames = [
    'Restauration',
    'Pizzas & Fast-food',
    'Épicerie',
    'Boulangerie & Pâtisserie',
    'Boissons & Cafés',
    'Pharmacie & Santé',
  ];

  /// Groupes sémantiques de catégories / synonymes
  static final List<Set<String>> _synonymGroups = [
    // 1. Pizzas & Fast-food
    {
      'pizza',
      'pizzas',
      'fastfood',
      'fast-food',
      'fast food',
      'burger',
      'burgers',
      'sandwich',
      'sandwiches',
      'tacos',
      'panini',
      'chawarma',
      'snack',
      'snacks',
      'pizzas & fast-food',
    },
    // 2. Restauration / Plats
    {
      'restauration',
      'restaurant',
      'restaurants',
      'plat',
      'plats',
      'menu',
      'menus',
      'cuisine',
      'repas',
      'salade',
      'salades',
      'traiteur',
    },
    // 3. Boissons & Cafés
    {
      'boisson',
      'boissons',
      'café',
      'cafés',
      'cafe',
      'cafes',
      'jus',
      'soda',
      'sodas',
      'drinks',
      'drink',
      'thé',
      'the',
      'eau',
      'boissons & cafés',
    },
    // 4. Boulangerie & Pâtisserie / Desserts
    {
      'boulangerie',
      'pâtisserie',
      'patisserie',
      'dessert',
      'desserts',
      'pain',
      'pains',
      'viennoiserie',
      'viennoiseries',
      'gâteau',
      'gateau',
      'gâteaux',
      'gateaux',
      'glace',
      'glaces',
      'icecream',
      'boulangerie & pâtisserie',
    },
    // 5. Épicerie
    {
      'épicerie',
      'epicerie',
      'supermarché',
      'supermarche',
      'alimentation',
      'courses',
      'magasin',
      'produits frais',
      'fruits & légumes',
    },
    // 6. Pharmacie & Santé
    {
      'pharmacie',
      'santé',
      'sante',
      'parapharmacie',
      'soins',
      'soin',
      'beauté',
      'médicaments',
      'pharmacie & santé',
    },
  ];

  /// Vérifie si la catégorie d'un produit correspond à la catégorie sélectionnée
  /// (insensible à la casse, tolérant aux espaces, aux sous-chaînes et aux synonymes).
  static bool matches(String? productCategory, String? selectedCategory) {
    final sel = (selectedCategory ?? '').trim().toLowerCase();
    final prod = (productCategory ?? '').trim().toLowerCase();

    // Filtre vide ou "Tous" / "Toutes" -> tout est accepté
    if (sel.isEmpty || sel == 'tous' || sel == 'toutes' || sel == 'all') {
      return true;
    }

    if (prod.isEmpty) {
      return false;
    }

    // Égalité exacte après normalisation
    if (prod == sel) {
      return true;
    }

    // Correspondance par sous-chaîne directe
    if (prod.contains(sel) || sel.contains(prod)) {
      return true;
    }

    // Normalisation basique (suppression accents pour comparaison)
    final prodNorm = _normalize(prod);
    final selNorm = _normalize(sel);
    if (prodNorm == selNorm || prodNorm.contains(selNorm) || selNorm.contains(prodNorm)) {
      return true;
    }

    // Correspondance via groupes de synonymes
    for (final group in _synonymGroups) {
      final inGroupProd = group.any((term) {
        final normTerm = _normalize(term);
        return prodNorm == normTerm || prodNorm.contains(normTerm) || normTerm.contains(prodNorm);
      });
      final inGroupSel = group.any((term) {
        final normTerm = _normalize(term);
        return selNorm == normTerm || selNorm.contains(normTerm) || normTerm.contains(selNorm);
      });

      if (inGroupProd && inGroupSel) {
        return true;
      }
    }

    return false;
  }

  /// Retourne une icône Material appropriée pour un nom ou identifiant de catégorie.
  static IconData iconForCategory(String nameOrIcon) {
    final clean = _normalize(nameOrIcon.trim().toLowerCase());

    if (clean.contains('pizza') || clean.contains('burger') || clean.contains('fastfood') || clean.contains('tacos')) {
      return Icons.local_pizza;
    }
    if (clean.contains('restaurant') || clean.contains('plat') || clean.contains('repas') || clean.contains('cuisine')) {
      return Icons.restaurant;
    }
    if (clean.contains('boisson') || clean.contains('cafe') || clean.contains('juice') || clean.contains('drink')) {
      return Icons.local_cafe;
    }
    if (clean.contains('boulangerie') || clean.contains('patisserie') || clean.contains('dessert') || clean.contains('gateau')) {
      return Icons.bakery_dining;
    }
    if (clean.contains('epicerie') || clean.contains('supermarche') || clean.contains('grocery')) {
      return Icons.local_grocery_store;
    }
    if (clean.contains('pharmacie') || clean.contains('sante')) {
      return Icons.local_pharmacy;
    }
    if (clean.contains('glace') || clean.contains('icecream')) {
      return Icons.icecream;
    }
    if (clean.contains('store') || clean.contains('boutique')) {
      return Icons.storefront;
    }

    return Icons.category;
  }

  static String _normalize(String input) {
    return input
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ûüù]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
