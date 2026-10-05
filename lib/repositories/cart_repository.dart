import '../models/cart.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import 'store.dart';

class CartData {
  CartData({
    required this.cart,
    required List<CartItem> items,
    required Map<int, Product> products,
  }) : items = List.unmodifiable(items),
       products = Map.unmodifiable(products);
  final Cart cart;
  final List<CartItem> items;
  final Map<int, Product> products;

  bool available(CartItem item) {
    final product = products[item.productId];
    return product != null && !product.isDeleted;
  }

  int get total => items.fold<int>(
    0,
    (sum, item) =>
        sum +
        (available(item) ? products[item.productId]!.price * item.quantity : 0),
  );
}

abstract interface class CartRepository {
  Future<CartData> find(int userId);
  Future<void> add(int userId, int productId, {int quantity = 1});
  Future<void> setQuantity(int userId, int itemId, int quantity);
  Future<void> remove(int userId, int itemId);
  Future<void> clear(int userId);
}

class MemoryCartRepository implements CartRepository {
  MemoryCartRepository(this.store);
  final Store store;

  Cart _cart(int userId, {bool changing = false}) {
    final users = store.users.where((item) => item.id == userId);
    if (users.isEmpty) {
      throw StateError('Пользователь не найден');
    }
    if (changing && users.first.isDeleted) {
      throw StateError('Сначала восстановите пользователя');
    }
    final carts = store.carts.where((item) => item.userId == userId).toList();
    if (carts.length != 1) {
      throw StateError('Корзина пользователя не найдена или нарушена её связь');
    }
    return carts.single;
  }

  @override
  Future<CartData> find(int userId) async {
    final cart = _cart(userId);
    return CartData(
      cart: cart,
      items: store.cartItems.where((item) => item.cartId == cart.id).toList(),
      products: {for (final item in store.products) item.id: item},
    );
  }

  void _quantity(int value) {
    if (value < 1 || value > 999) {
      throw ArgumentError('Количество должно быть от 1 до 999');
    }
  }

  @override
  Future<void> add(int userId, int productId, {int quantity = 1}) =>
      store.change<void>(() {
        final cart = _cart(userId, changing: true);
        _quantity(quantity);
        if (!store.products.any(
          (item) => item.id == productId && !item.isDeleted,
        )) {
          throw StateError('Товар недоступен');
        }
        final index = store.cartItems.indexWhere(
          (item) => item.cartId == cart.id && item.productId == productId,
        );
        if (index >= 0) {
          final item = store.cartItems[index];
          final next = item.quantity + quantity;
          _quantity(next);
          store.cartItems[index] = item.copyWith(quantity: next);
        } else {
          store.cartItems.add(
            CartItem(
              id: store.nextCartItemId++,
              cartId: cart.id,
              productId: productId,
              quantity: quantity,
            ),
          );
        }
      });

  @override
  Future<void> setQuantity(int userId, int itemId, int quantity) =>
      store.change<void>(() {
        final cart = _cart(userId, changing: true);
        _quantity(quantity);
        final index = store.cartItems.indexWhere(
          (item) => item.id == itemId && item.cartId == cart.id,
        );
        if (index < 0) {
          throw StateError('Позиция корзины не найдена');
        }
        final item = store.cartItems[index];
        if (!store.products.any(
          (product) => product.id == item.productId && !product.isDeleted,
        )) {
          throw StateError('Товар недоступен');
        }
        store.cartItems[index] = item.copyWith(quantity: quantity);
      });

  @override
  Future<void> remove(int userId, int itemId) => store.change<void>(() {
    final cart = _cart(userId, changing: true);
    store.cartItems.removeWhere(
      (item) => item.cartId == cart.id && item.id == itemId,
    );
  });

  @override
  Future<void> clear(int userId) => store.change<void>(() {
    final cart = _cart(userId, changing: true);
    store.cartItems.removeWhere((item) => item.cartId == cart.id);
  });
}
