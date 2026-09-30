import 'models/product.dart';

String formatPrice(int price) {
  final rubles = price ~/ 100;
  final kopecks = (price % 100).toString().padLeft(2, '0');
  return '$rubles,$kopecks ₽';
}

String productTypeName(ProductType type) {
  return switch (type) {
    ProductType.gameKey => 'Игровой ключ',
    ProductType.aiSubscription => 'Подписка на нейросеть',
  };
}
