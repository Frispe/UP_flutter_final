import 'models/product.dart';

String formatPrice(int price) {
  final rubles = price ~/ 100;
  final kopecks = (price % 100).toString().padLeft(2, '0');
  return '$rubles,$kopecks ₽';
}

String formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day.$month.${value.year} $hour:$minute';
}

String orderStatusName(String value) => switch (value) {
  'new' => 'Новый',
  'paid' => 'Оплачен',
  'completed' => 'Выполнен',
  'cancelled' => 'Отменён',
  _ => value,
};

String productTypeName(ProductType type) {
  return switch (type) {
    ProductType.gameKey => 'Игровой ключ',
    ProductType.aiSubscription => 'Подписка на нейросеть',
  };
}
