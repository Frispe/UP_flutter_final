import 'json.dart';

class Order {
  const Order({
    required this.id,
    required this.userId,
    required this.status,
    required this.totalPrice,
    required this.orderedAt,
    this.deletedAt,
  });

  final int id;
  final int userId;
  final String status;
  final int totalPrice;
  final DateTime orderedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Order copyWith({
    int? userId,
    String? status,
    int? totalPrice,
    DateTime? orderedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Order(
      id: id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      orderedAt: orderedAt ?? this.orderedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': userId,
    'status': status,
    'totalPrice': totalPrice,
    'orderedAt': orderedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: readInt(json['id']),
      userId: readInt(json['customerId'] ?? json['userId']),
      status: readString(json['status']),
      totalPrice: readInt(json['totalPrice']),
      orderedAt:
          readDate(json['orderedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      deletedAt: readDate(json['deletedAt']),
    );
  }
}
