import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending('En attente'),
  preparing('En préparation'),
  ready('Prête'),
  assigned('Assignée'),
  pickedUp('Récupérée'),
  delivering('En livraison'),
  delivered('Livrée'),
  cancelled('Annulée');

  final String label;
  const OrderStatus(this.label);

  static OrderStatus fromString(String? value) {
    return OrderStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == (value ?? '').toLowerCase(),
      orElse: () => OrderStatus.pending,
    );
  }
}

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String shopName;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.shopName = '',
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: (map['productId'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      shopName: (map['shopName'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'shopName': shopName,
      };
}

class OrderModel {
  final String id;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String deliveryAddress;
  final String vendorName;
  final String vendorAddress;
  final String vendorPhone;
  final String? courierId;
  final String? courierName;
  final String? courierPhone;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final String paymentMethod;
  final String? notes;

  const OrderModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.deliveryAddress,
    this.vendorName = '',
    this.vendorAddress = '',
    this.vendorPhone = '',
    this.courierId,
    this.courierName,
    this.courierPhone,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    this.discount = 0.0,
    required this.total,
    required this.status,
    required this.createdAt,
    this.paymentMethod = 'Paiement à la livraison',
    this.notes,
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawItems = data['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((item) => OrderItem.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();

    final rawVendorName = (data['vendorName'] as String?) ?? '';
    final fallbackVendorName = rawVendorName.isNotEmpty
        ? rawVendorName
        : (items.isNotEmpty ? items.first.shopName : '');

    return OrderModel(
      id: id,
      clientId: (data['clientId'] as String?) ?? '',
      clientName: (data['clientName'] as String?) ?? '',
      clientPhone: (data['clientPhone'] as String?) ?? '',
      deliveryAddress: (data['deliveryAddress'] as String?) ?? '',
      vendorName: fallbackVendorName,
      vendorAddress: (data['vendorAddress'] as String?) ?? '',
      vendorPhone: (data['vendorPhone'] as String?) ?? '',
      courierId: data['courierId'] as String?,
      courierName: data['courierName'] as String?,
      courierPhone: data['courierPhone'] as String?,
      items: items,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      status: OrderStatus.fromString(data['status'] as String?),
      createdAt: parseDate(data['createdAt']),
      paymentMethod: (data['paymentMethod'] as String?) ?? 'Paiement à la livraison',
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'clientId': clientId,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'deliveryAddress': deliveryAddress,
        'vendorName': vendorName,
        'vendorAddress': vendorAddress,
        'vendorPhone': vendorPhone,
        if (courierId != null) 'courierId': courierId,
        if (courierName != null) 'courierName': courierName,
        if (courierPhone != null) 'courierPhone': courierPhone,
        'items': items.map((i) => i.toMap()).toList(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'discount': discount,
        'total': total,
        'status': status.name,
        'createdAt': FieldValue.serverTimestamp(),
        'paymentMethod': paymentMethod,
        if (notes != null) 'notes': notes,
      };
}
