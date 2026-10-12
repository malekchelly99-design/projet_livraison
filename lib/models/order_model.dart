import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending('En attente'),
  preparing('En préparation'),
  ready('Prête'),
  assigned('Livreur affecté'),
  pickedUp('Commande récupérée'),
  delivering('En livraison'),
  delivered('Livrée'),
  cancelled('Annulée');

  final String label;
  const OrderStatus(this.label);

  static OrderStatus fromString(String? value) {
    if (value == null) return OrderStatus.pending;
    final v = value.trim().toLowerCase();
    for (final s in OrderStatus.values) {
      if (s.name.toLowerCase() == v || s.label.toLowerCase() == v) {
        return s;
      }
    }
    if (v == 'picked_up' || v == 'recuperee' || v == 'récupérée') return OrderStatus.pickedUp;
    if (v == 'en cours de livraison') return OrderStatus.delivering;
    if (v == 'livree' || v == 'livrée') return OrderStatus.delivered;
    if (v == 'annulee' || v == 'annulée') return OrderStatus.cancelled;
    if (v == 'prete' || v == 'prête') return OrderStatus.ready;
    if (v == 'affecte' || v == 'affectée' || v == 'affecté') return OrderStatus.assigned;
    return OrderStatus.pending;
  }
}

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: (map['productId'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
      };
}

class OrderModel {
  final String id;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String deliveryAddress;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final String paymentMethod;
  final String? notes;

  // Champs de la boutique / vendeur
  final String vendorName;
  final String vendorAddress;
  final String vendorPhone;

  // Champs du livreur
  final String? courierId;
  final String? courierName;
  final String? courierPhone;
  final DateTime? deliveredAt;

  const OrderModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.deliveryAddress,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    this.discount = 0.0,
    required this.total,
    required this.status,
    required this.createdAt,
    this.paymentMethod = 'Paiement à la livraison',
    this.notes,
    this.vendorName = 'Boutique Partenaire',
    this.vendorAddress = 'Avenue Habib Bourguiba, Tunis',
    this.vendorPhone = '+216 71 234 567',
    this.courierId,
    this.courierName,
    this.courierPhone,
    this.deliveredAt,
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawItems = data['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((item) => OrderItem.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();

    return OrderModel(
      id: id,
      clientId: (data['clientId'] as String?) ?? '',
      clientName: (data['clientName'] as String?) ?? '',
      clientPhone: (data['clientPhone'] as String?) ?? '',
      deliveryAddress: (data['deliveryAddress'] as String?) ?? '',
      items: items,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      status: OrderStatus.fromString(data['status'] as String?),
      createdAt: parseDate(data['createdAt']),
      paymentMethod: (data['paymentMethod'] as String?) ?? 'Paiement à la livraison',
      notes: data['notes'] as String?,
      vendorName: (data['vendorName'] as String?) ?? (data['shopName'] as String?) ?? 'Boutique Partenaire',
      vendorAddress: (data['vendorAddress'] as String?) ?? (data['shopAddress'] as String?) ?? 'Avenue Habib Bourguiba, Tunis',
      vendorPhone: (data['vendorPhone'] as String?) ?? (data['shopPhone'] as String?) ?? '+216 71 234 567',
      courierId: data['courierId'] as String?,
      courierName: data['courierName'] as String?,
      courierPhone: data['courierPhone'] as String?,
      deliveredAt: parseNullableDate(data['deliveredAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'clientId': clientId,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'deliveryAddress': deliveryAddress,
        'items': items.map((i) => i.toMap()).toList(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'discount': discount,
        'total': total,
        'status': status.name,
        'createdAt': FieldValue.serverTimestamp(),
        'paymentMethod': paymentMethod,
        if (notes != null) 'notes': notes,
        'vendorName': vendorName,
        'vendorAddress': vendorAddress,
        'vendorPhone': vendorPhone,
        if (courierId != null) 'courierId': courierId,
        if (courierName != null) 'courierName': courierName,
        if (courierPhone != null) 'courierPhone': courierPhone,
        if (deliveredAt != null) 'deliveredAt': deliveredAt,
      };

  OrderModel copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientPhone,
    String? deliveryAddress,
    List<OrderItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? discount,
    double? total,
    OrderStatus? status,
    DateTime? createdAt,
    String? paymentMethod,
    String? notes,
    String? vendorName,
    String? vendorAddress,
    String? vendorPhone,
    String? courierId,
    String? courierName,
    String? courierPhone,
    DateTime? deliveredAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      vendorName: vendorName ?? this.vendorName,
      vendorAddress: vendorAddress ?? this.vendorAddress,
      vendorPhone: vendorPhone ?? this.vendorPhone,
      courierId: courierId ?? this.courierId,
      courierName: courierName ?? this.courierName,
      courierPhone: courierPhone ?? this.courierPhone,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}
