enum ProductType { gameKey, aiSubscription }

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.description,
    required this.type,
    required this.brandId,
    required this.price,
    required this.platform,
    required this.region,
    this.durationMonths,
    this.deletedAt,
  });

  final int id;
  final String name;
  final String sku;
  final String description;
  final ProductType type;
  final int brandId;
  final int price;
  final String platform;
  final String region;
  final int? durationMonths;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Product copyWith({
    String? name,
    String? sku,
    String? description,
    ProductType? type,
    int? brandId,
    int? price,
    String? platform,
    String? region,
    int? durationMonths,
    bool clearDuration = false,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      description: description ?? this.description,
      type: type ?? this.type,
      brandId: brandId ?? this.brandId,
      price: price ?? this.price,
      platform: platform ?? this.platform,
      region: region ?? this.region,
      durationMonths: clearDuration
          ? null
          : (durationMonths ?? this.durationMonths),
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
