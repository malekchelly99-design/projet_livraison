import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus { pending, completed, cancelled, refunded }

class PaymentModel {
  final String id;
  final String orderId;
  final String clientId;
  final String vendorId;
  final double amount;
  final PaymentStatus status;
  final String method; // 'cash', 'card', 'online'
  final DateTime createdAt;
  final DateTime? updatedAt;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.clientId,
    required this.vendorId,
    required this.amount,
    required this.status,
    this.method = 'cash',
    required this.createdAt,
    this.updatedAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String docId) {
    return PaymentModel(
      id: docId,
      orderId: map['orderId'] as String? ?? '',
      clientId: map['clientId'] as String? ?? '',
      vendorId: map['vendorId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      status: _statusFromString(map['status'] as String? ?? 'pending'),
      method: map['method'] as String? ?? 'cash',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'clientId': clientId,
      'vendorId': vendorId,
      'amount': amount,
      'status': status.name,
      'method': method,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? orderId,
    String? clientId,
    String? vendorId,
    double? amount,
    PaymentStatus? status,
    String? method,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      clientId: clientId ?? this.clientId,
      vendorId: vendorId ?? this.vendorId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      method: method ?? this.method,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static PaymentStatus _statusFromString(String s) {
    switch (s) {
      case 'completed':
        return PaymentStatus.completed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }
}

