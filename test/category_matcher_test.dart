import 'package:flutter_test/flutter_test.dart';
import 'package:livraison_rapide/utils/category_matcher.dart';

void main() {
  group('CategoryMatcher Tests', () {
    test('Tous and null matches everything', () {
      expect(CategoryMatcher.matches('Pizzas', 'Tous'), true);
      expect(CategoryMatcher.matches('Boissons', 'Toutes'), true);
      expect(CategoryMatcher.matches('Épicerie', ''), true);
      expect(CategoryMatcher.matches('Burger', null), true);
    });

    test('Exact match (case and accents insensitive)', () {
      expect(CategoryMatcher.matches('Pizzas', 'pizzas'), true);
      expect(CategoryMatcher.matches('Épicerie', 'epicerie'), true);
      expect(CategoryMatcher.matches('  Boissons  ', 'boissons'), true);
    });

    test('Synonym and compound category matching', () {
      // Pizzas & Fast-food matches Pizza, Burger, Tacos, Sandwiches
      expect(CategoryMatcher.matches('Pizzas', 'Pizzas & Fast-food'), true);
      expect(CategoryMatcher.matches('Burger', 'Pizzas & Fast-food'), true);
      expect(CategoryMatcher.matches('Sandwiches', 'Pizzas & Fast-food'), true);
      expect(CategoryMatcher.matches('Tacos', 'Pizzas & Fast-food'), true);

      // Boissons & Cafés matches Boissons, Café, Jus, Soda
      expect(CategoryMatcher.matches('Boissons', 'Boissons & Cafés'), true);
      expect(CategoryMatcher.matches('Café', 'Boissons & Cafés'), true);
      expect(CategoryMatcher.matches('Jus de fruits', 'Boissons & Cafés'), true);

      // Restauration matches Plats, Menus, Repas
      expect(CategoryMatcher.matches('Plats', 'Restauration'), true);
      expect(CategoryMatcher.matches('Menus', 'Restauration'), true);

      // Boulangerie & Pâtisserie matches Desserts, Gâteaux, Pains
      expect(CategoryMatcher.matches('Desserts', 'Boulangerie & Pâtisserie'), true);
      expect(CategoryMatcher.matches('Pâtisserie', 'Boulangerie & Pâtisserie'), true);
    });

    test('Custom category matches itself', () {
      expect(CategoryMatcher.matches('Sushi', 'Sushi'), true);
      expect(CategoryMatcher.matches('Fleurs', 'fleurs'), true);
      expect(CategoryMatcher.matches('Sushi', 'Pizzas & Fast-food'), false);
    });
  });
}
