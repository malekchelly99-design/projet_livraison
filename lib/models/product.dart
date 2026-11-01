class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String shopName;
  final double rating;
  final int deliveryTimeMinutes;
  final bool isPopular;
  final String imageUrl;
  final String? vendorId;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.shopName,
    this.rating = 4.8,
    this.deliveryTimeMinutes = 25,
    this.isPopular = false,
    this.imageUrl = '',
    this.vendorId,
  });

  factory Product.fromMap(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      name: (data['name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      category: (data['category'] as String?) ?? 'Général',
      shopName: (data['shopName'] as String?) ?? 'Boutique Partenaire',
      rating: (data['rating'] as num?)?.toDouble() ?? 4.8,
      deliveryTimeMinutes: (data['deliveryTimeMinutes'] as num?)?.toInt() ?? 25,
      isPopular: (data['isPopular'] as bool?) ?? false,
      imageUrl: (data['imageUrl'] as String?) ?? '',
      vendorId: data['vendorId'] as String?,
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    String? shopName,
    double? rating,
    int? deliveryTimeMinutes,
    bool? isPopular,
    String? imageUrl,
    String? vendorId,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      shopName: shopName ?? this.shopName,
      rating: rating ?? this.rating,
      deliveryTimeMinutes: deliveryTimeMinutes ?? this.deliveryTimeMinutes,
      isPopular: isPopular ?? this.isPopular,
      imageUrl: imageUrl ?? this.imageUrl,
      vendorId: vendorId ?? this.vendorId,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'shopName': shopName,
        'rating': rating,
        'deliveryTimeMinutes': deliveryTimeMinutes,
        'isPopular': isPopular,
        'imageUrl': imageUrl,
        if (vendorId != null) 'vendorId': vendorId,
      };
}

class CartItem {
  final Product product;
  int quantity;
  String? instructions;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.instructions,
  });

  double get totalPrice => product.price * quantity;
}
