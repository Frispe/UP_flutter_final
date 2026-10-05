import 'json.dart';

class OrderItem {
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
  });

  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final int price;

  int get totalPrice => price * quantity;

  OrderItem copyWith({
    int? orderId,
    int? productId,
    int? quantity,
    int? price,
  }) {
    return OrderItem(
      id: id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'productId': productId,
    'quantity': quantity,
    'price': price,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: readInt(json['id']),
      orderId: readInt(json['orderId']),
      productId: readInt(json['productId']),
      quantity: readInt(json['quantity']),
      price: readInt(json['price']),
    );
  }
}
