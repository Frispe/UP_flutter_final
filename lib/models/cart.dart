import 'json.dart';

class Cart {
  const Cart({required this.id, required this.userId});

  final int id;
  final int userId;

  Cart copyWith({int? userId}) {
    return Cart(id: id, userId: userId ?? this.userId);
  }

  Map<String, dynamic> toJson() => {'id': id, 'userId': userId};

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(id: readInt(json['id']), userId: readInt(json['userId']));
  }
}
