import 'package:flutter_test/flutter_test.dart';
import 'package:livraison_rapide/models/notification_model.dart';

void main() {
  group('NotificationModel Tests', () {
    test('NotificationModel serialization and deserialization', () {
      final notif = NotificationModel(
        id: 'notif_1',
        userId: 'user_123',
        title: 'Nouvelle commande',
        message: 'Vous avez reçu une commande.',
        type: NotificationType.orderNew,
        orderId: 'ord_999',
        isRead: false,
        createdAt: DateTime(2026, 11, 21, 10, 0),
      );

      final map = notif.toMap();
      expect(map['userId'], 'user_123');
      expect(map['title'], 'Nouvelle commande');
      expect(map['type'], 'order_new');
      expect(map['orderId'], 'ord_999');
      expect(map['isRead'], false);

      final fromMap = NotificationModel.fromMap('notif_1', {
        ...map,
        'createdAt': '2026-11-21T10:00:00.000',
      });

      expect(fromMap.id, 'notif_1');
      expect(fromMap.userId, 'user_123');
      expect(fromMap.title, 'Nouvelle commande');
      expect(fromMap.type, NotificationType.orderNew);
      expect(fromMap.orderId, 'ord_999');
      expect(fromMap.isRead, false);
    });

    test('NotificationType parsing from string', () {
      expect(NotificationType.fromString('order_new'), NotificationType.orderNew);
      expect(NotificationType.fromString('order_delivering'), NotificationType.orderDelivering);
      expect(NotificationType.fromString('order_delivered'), NotificationType.orderDelivered);
      expect(NotificationType.fromString('order_cancelled'), NotificationType.orderCancelled);
      expect(NotificationType.fromString('order_status'), NotificationType.orderStatus);
      expect(NotificationType.fromString('unknown_type'), NotificationType.info);
      expect(NotificationType.fromString(null), NotificationType.info);
    });

    test('copyWith updates fields correctly', () {
      final notif = NotificationModel(
        id: 'notif_1',
        userId: 'user_1',
        title: 'Titre',
        message: 'Message',
        createdAt: DateTime.now(),
      );

      final read = notif.copyWith(isRead: true);
      expect(read.isRead, true);
      expect(read.id, 'notif_1');
      expect(read.title, 'Titre');
    });
  });
}
