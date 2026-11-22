import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  orderNew('order_new'),
  orderStatus('order_status'),
  orderDelivering('order_delivering'),
  orderDelivered('order_delivered'),
  orderCancelled('order_cancelled'),
  info('info');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String? val) {
    switch (val) {
      case 'order_new':
        return NotificationType.orderNew;
      case 'order_status':
        return NotificationType.orderStatus;
      case 'order_delivering':
        return NotificationType.orderDelivering;
      case 'order_delivered':
        return NotificationType.orderDelivered;
      case 'order_cancelled':
        return NotificationType.orderCancelled;
      default:
        return NotificationType.info;
    }
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final String? orderId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.type = NotificationType.info,
    this.orderId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    bool parseBool(dynamic val) {
      if (val is bool) return val;
      if (val is String) return val.toLowerCase() == 'true';
      if (val is num) return val != 0;
      return false;
    }

    return NotificationModel(
      id: id,
      userId: (data['userId']?.toString()) ?? '',
      title: (data['title']?.toString()) ?? 'Notification',
      message: (data['message']?.toString()) ?? '',
      type: NotificationType.fromString(data['type']?.toString()),
      orderId: data['orderId']?.toString(),
      isRead: parseBool(data['isRead']),
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'message': message,
        'type': type.value,
        if (orderId != null && orderId!.isNotEmpty) 'orderId': orderId,
        'isRead': isRead,
        'createdAt': FieldValue.serverTimestamp(),
      };

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    String? orderId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      orderId: orderId ?? this.orderId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
