import 'package:flutter_test/flutter_test.dart';
import 'package:livraison_rapide/models/courier_location.dart';
import 'package:livraison_rapide/models/order_model.dart';
import 'package:livraison_rapide/models/product.dart';
import 'package:livraison_rapide/services/location_tracking_service.dart';

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
        vendorId: 'vendor_456',
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
      expect(map['vendorId'], 'vendor_456');
      expect(map['subtotal'], 40.0);
      expect(map['total'], 39.5);
      expect(map['status'], 'pending');

      final fromMap = OrderModel.fromMap('ord_123', {
        ...map,
        'createdAt': '2026-01-01T12:00:00.000',
      });

      expect(fromMap.id, 'ord_123');
      expect(fromMap.clientName, 'Karim Ben Ali');
      expect(fromMap.vendorId, 'vendor_456');
      expect(fromMap.items.length, 1);
      expect(fromMap.items.first.name, 'Pizza');
      expect(fromMap.status, OrderStatus.pending);
    });

    test('OrderStatus mapping handles unknown values safely', () {
      expect(OrderStatus.fromString('delivering'), OrderStatus.delivering);
      expect(OrderStatus.fromString('delivered'), OrderStatus.delivered);
      expect(OrderStatus.fromString('unknown_val'), OrderStatus.pending);
    });

    test('CourierLocation model serialization & deserialization', () {
      final loc = CourierLocation(
        id: 'ord_123',
        courierId: 'courier_99',
        orderId: 'ord_123',
        latitude: 36.8065,
        longitude: 10.1815,
        updatedAt: DateTime(2026, 11, 7, 12, 0),
        heading: 90.0,
        speed: 8.5,
        isActive: true,
      );

      final map = loc.toMap();
      expect(map['courierId'], 'courier_99');
      expect(map['orderId'], 'ord_123');
      expect(map['latitude'], 36.8065);
      expect(map['longitude'], 10.1815);
      expect(map['speed'], 8.5);
      expect(map['isActive'], true);

      final fromMap = CourierLocation.fromMap('ord_123', {
        'id_livreur': 'courier_99',
        'id_commande': 'ord_123',
        'latitude': 36.8065,
        'longitude': 10.1815,
        'date_maj': '2026-11-07T12:00:00.000',
        'speed': 8.5,
        'isActive': true,
      });

      expect(fromMap.courierId, 'courier_99');
      expect(fromMap.orderId, 'ord_123');
      expect(fromMap.latitude, 36.8065);
      expect(fromMap.longitude, 10.1815);
      expect(fromMap.speed, 8.5);
      expect(fromMap.isActive, true);
    });

    test('LocationTrackingService calculates distance and ETA correctly', () {
      // Coordonnées approximatives : Tunis Centre vers La Marsa (~15 km)
      final result = LocationTrackingService.calculateDistanceAndEta(
        startLat: 36.8065,
        startLng: 10.1815,
        endLat: 36.8782,
        endLng: 10.3247,
        averageSpeedKmH: 30.0,
      );

      expect(result['distanceKm'], greaterThan(10.0));
      expect(result['distanceKm'], lessThan(20.0));
      expect(result['etaMinutes'], greaterThan(15));
      expect(result['formattedEta'], contains('min'));
      expect(result['formattedDistance'], contains('km'));
    });
  });
}
