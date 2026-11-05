import 'package:flutter_test/flutter_test.dart';
import 'package:livraison_rapide/models/order_model.dart';
import 'package:livraison_rapide/models/product.dart';

void main() {
  group('Client Dashboard Business Logic Tests', () {
    test('CartItem calculates total price accurately', () {
      const product = Product(
        id: 'p1',
        name: 'Burger Gourmet',
        description: 'Test burger',
        price: 15.0,
        category: 'Burgers',
        shopName: 'Test Shop',
      );

      final item = CartItem(product: product, quantity: 3);
      expect(item.totalPrice, 45.0);

      item.quantity = 1;
      expect(item.totalPrice, 15.0);
    });

    test('OrderModel serialization and deserialization', () {
      final order = OrderModel(
        id: 'ord_123',
        clientId: 'client_abc',
        clientName: 'Karim Ben Ali',
        clientPhone: '20123456',
        deliveryAddress: 'Centre Ville Tunis',
        items: const [
          OrderItem(
            productId: 'p1',
            name: 'Pizza',
            price: 20.0,
            quantity: 2,
          ),
        ],
        subtotal: 40.0,
        deliveryFee: 4.5,
        discount: 5.0,
        total: 39.5,
        status: OrderStatus.pending,
        createdAt: DateTime(2026, 1, 1, 12, 0),
        paymentMethod: 'Paiement en espèces à la livraison',
      );

      final map = order.toMap();
      expect(map['clientId'], 'client_abc');
      expect(map['subtotal'], 40.0);
      expect(map['total'], 39.5);
      expect(map['status'], 'pending');

      final fromMap = OrderModel.fromMap('ord_123', {
        ...map,
        'createdAt': '2026-01-01T12:00:00.000',
      });

      expect(fromMap.id, 'ord_123');
      expect(fromMap.clientName, 'Karim Ben Ali');
      expect(fromMap.items.length, 1);
      expect(fromMap.items.first.name, 'Pizza');
      expect(fromMap.status, OrderStatus.pending);
    });

    test('OrderStatus mapping handles unknown values safely', () {
      expect(OrderStatus.fromString('delivering'), OrderStatus.delivering);
      expect(OrderStatus.fromString('delivered'), OrderStatus.delivered);
      expect(OrderStatus.fromString('unknown_val'), OrderStatus.pending);
    });
  });
}
