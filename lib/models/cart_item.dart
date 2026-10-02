import 'json.dart';

class CartItem {
  const CartItem({
    required this.id,
    required this.cartId,
    required this.productId,
    required this.quantity,
  });

  final int id;
  final int cartId;
  final int productId;
  final int quantity;

  CartItem copyWith({int? cartId, int? productId, int? quantity}) {
    return CartItem(
      id: id,
      cartId: cartId ?? this.cartId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'cartId': cartId,
    'productId': productId,
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: readInt(json['id']),
      cartId: readInt(json['cartId']),
      productId: readInt(json['productId']),
      quantity: readInt(json['quantity']),
    );
  }
}
