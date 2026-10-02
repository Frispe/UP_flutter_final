import 'json.dart';

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
    required this.platformId,
    this.categoryIds = const [],
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
  final int platformId;
  final List<int> categoryIds;
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
    int? platformId,
    List<int>? categoryIds,
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
      platformId: platformId ?? this.platformId,
      categoryIds: categoryIds == null
          ? this.categoryIds
          : List.unmodifiable(categoryIds),
      region: region ?? this.region,
      durationMonths: clearDuration
          ? null
          : (durationMonths ?? this.durationMonths),
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sku': sku,
    'description': description,
    'type': type.name,
    'brandId': brandId,
    'price': price,
    'platformId': platformId,
    'categoryIds': List<int>.of(categoryIds),
    'region': region,
    'durationMonths': durationMonths,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  static ProductType _readType(Object? value) {
    for (final type in ProductType.values) {
      if (type.name == value) {
        return type;
      }
    }
    return ProductType.gameKey;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: readInt(json['id']),
      name: readString(json['name']),
      sku: readString(json['sku']),
      description: readString(json['description']),
      type: _readType(json['type']),
      brandId: readInt(json['brandId']),
      price: readInt(json['price']),
      platformId: readInt(json['platformId']),
      categoryIds: readIds(json['categoryIds']),
      region: readString(json['region']),
      durationMonths: readNullableInt(json['durationMonths']),
      deletedAt: readDate(json['deletedAt']),
    );
  }
}
