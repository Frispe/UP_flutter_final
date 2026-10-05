import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/category.dart';
import '../models/platform.dart';
import '../models/user.dart';
import '../models/cart.dart';
import '../models/cart_item.dart';
import '../data.dart' as data;
import '../models/brand.dart';
import '../models/page_result.dart';
import '../models/product.dart';
import '../models/query.dart';

class Store {
  static const _key = 'digital_shop_data';
  static const _version = 1;
  SharedPreferences? _prefs;
  String? message;
  Future<void> _pending = Future<void>.value();

  final List<Product> products = [...data.products];
  final List<Brand> brands = [...data.brands];
  final List<Category> categories = [...data.categories];
  final List<Platform> platforms = [...data.platforms];
  final List<User> users = [];
  final List<Cart> carts = [];
  final List<CartItem> cartItems = [];

  int nextProductId = 1;
  int nextBrandId = 1;

  int nextCategoryId = 1;

  int nextPlatformId = 1;

  int nextUserId = 1;

  int nextCartId = 1;

  int nextCartItemId = 1;

  Store() {
    _updateIds();
  }

  static Future<Store> open() async {
    final store = Store();
    try {
      store._prefs = await SharedPreferences.getInstance();
      final raw = store._prefs!.get(_key);
      if (raw == null) {
        await store._save();
        return store;
      }
      try {
        if (raw is! String) {
          throw const FormatException('Неверный формат хранилища');
        }
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Неверный формат хранилища');
        }
        if (decoded['version'] != _version) {
          store.message = 'Формат сохранённых данных изменился. Загружен начальный набор; предыдущие данные сохранены в резервной копии.';
          throw const FormatException('Другая версия данных');
        }
        store._restore(decoded);
      } catch (_) {
        final copied = await store._prefs!.setString(
          '${_key}_backup',
          raw.toString(),
        );
        if (!copied) {
          throw StateError('Не удалось сохранить резервную копию');
        }
        final initial = Store();
        store._restore(initial._snapshot());
        store.message ??= 'Сохранённые данные повреждены. Загружен начальный набор; предыдущие данные сохранены в резервной копии.';
        await store._save();
      }
    } catch (_) {
      store._prefs = null;
      store.message = 'Хранилище браузера недоступно. Просмотр доступен, но изменения не будут применены. Проверьте настройки браузера и перезагрузите страницу.';
    }
    return store;
  }

  void _updateIds() {
    final cartItemsMax = cartItems.fold<int>(
      0,
      (max, item) => item.id > max ? item.id : max,
    );
    if (nextCartItemId <= cartItemsMax) {
      nextCartItemId = cartItemsMax + 1;
    }
    final cartsMax = carts.fold<int>(
      0,
      (max, item) => item.id > max ? item.id : max,
    );
    if (nextCartId <= cartsMax) {
      nextCartId = cartsMax + 1;
    }
    final usersMax = users.fold<int>(
      0,
      (max, item) => item.id > max ? item.id : max,
    );
    if (nextUserId <= usersMax) {
      nextUserId = usersMax + 1;
    }
    final platformsMax = platforms.fold<int>(
      0,
      (max, item) => item.id > max ? item.id : max,
    );
    if (nextPlatformId <= platformsMax) {
      nextPlatformId = platformsMax + 1;
    }
    final categoriesMax = categories.fold<int>(
      0,
      (max, item) => item.id > max ? item.id : max,
    );
    if (nextCategoryId <= categoriesMax) {
      nextCategoryId = categoriesMax + 1;
    }
    final productMax = products.fold<int>(
      0,
      (max, item) => item.id > max ? item.id : max,
    );
    final brandMax = brands.fold<int>(
      0,
      (max, item) => item.id > max ? item.id : max,
    );
    if (nextProductId <= productMax) {
      nextProductId = productMax + 1;
    }
    if (nextBrandId <= brandMax) {
      nextBrandId = brandMax + 1;
    }
  }

  Map<String, dynamic> _snapshot() => {
    'version': _version,
    'nextCartItemId': nextCartItemId,
    'nextCartId': nextCartId,
    'nextUserId': nextUserId,
    'nextPlatformId': nextPlatformId,
    'nextCategoryId': nextCategoryId,
    'nextProductId': nextProductId,
    'nextBrandId': nextBrandId,
    'products': products.map((item) => item.toJson()).toList(),
    'brands': brands.map((item) => item.toJson()).toList(),
    'categories': categories.map((item) => item.toJson()).toList(),
    'platforms': platforms.map((item) => item.toJson()).toList(),
    'users': users.map((item) => item.toJson()).toList(),
    'carts': carts.map((item) => item.toJson()).toList(),
    'cartItems': cartItems.map((item) => item.toJson()).toList(),
  };

  List<T> _readList<T>(
    Map<String, dynamic> json,
    String key,
    T Function(Map<String, dynamic>) fromJson,
    int Function(T) idOf,
  ) {
    final values = json[key];
    if (values is! List) {
      throw FormatException('Отсутствует список $key');
    }
    final result = <T>[];
    final ids = <int>{};
    for (final value in values) {
      if (value is! Map<String, dynamic>) {
        throw FormatException('Неверная запись в $key');
      }
      final item = fromJson(value);
      final id = idOf(item);
      if (id <= 0 || !ids.add(id)) {
        throw FormatException('Неверный идентификатор в $key');
      }
      result.add(item);
    }
    return result;
  }

  void _restore(Map<String, dynamic> json) {
    final savedProducts = _readList<Product>(
      json,
      'products',
      Product.fromJson,
      (item) => item.id,
    );
    final savedBrands = _readList<Brand>(
      json,
      'brands',
      Brand.fromJson,
      (item) => item.id,
    );
    final savedCategories = _readList<Category>(
      json,
      'categories',
      Category.fromJson,
      (item) => item.id,
    );
    final savedPlatforms = _readList<Platform>(
      json,
      'platforms',
      Platform.fromJson,
      (item) => item.id,
    );
    final savedUsers = _readList<User>(
      json,
      'users',
      User.fromJson,
      (item) => item.id,
    );
    final savedCarts = _readList<Cart>(
      json,
      'carts',
      Cart.fromJson,
      (item) => item.id,
    );
    final savedItems = _readList<CartItem>(
      json,
      'cartItems',
      CartItem.fromJson,
      (item) => item.id,
    );
    products
      ..clear()
      ..addAll(savedProducts);
    brands
      ..clear()
      ..addAll(savedBrands);
    categories
      ..clear()
      ..addAll(savedCategories);
    platforms
      ..clear()
      ..addAll(savedPlatforms);
    users
      ..clear()
      ..addAll(savedUsers);
    carts
      ..clear()
      ..addAll(savedCarts);
    cartItems
      ..clear()
      ..addAll(savedItems);
    nextProductId = json['nextProductId'] is int
        ? json['nextProductId'] as int
        : 1;
    nextBrandId = json['nextBrandId'] is int ? json['nextBrandId'] as int : 1;
    nextCategoryId = json['nextCategoryId'] is int
        ? json['nextCategoryId'] as int
        : 1;
    nextPlatformId = json['nextPlatformId'] is int
        ? json['nextPlatformId'] as int
        : 1;
    nextUserId = json['nextUserId'] is int ? json['nextUserId'] as int : 1;
    nextCartId = json['nextCartId'] is int ? json['nextCartId'] as int : 1;
    nextCartItemId = json['nextCartItemId'] is int
        ? json['nextCartItemId'] as int
        : 1;
    _updateIds();
  }

  Future<void> _save() async {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('Хранилище браузера недоступно. Изменения отменены.');
    }
    final saved = await prefs.setString(_key, jsonEncode(_snapshot()));
    if (!saved) {
      throw StateError('Не удалось сохранить данные. Изменения отменены.');
    }
  }

  Future<T> change<T>(T Function() action) {
    final result = _pending.then<T>((_) async {
      final before = _snapshot();
      try {
        final value = action();
        await _save();
        return value;
      } catch (_) {
        _restore(before);
        rethrow;
      }
    });
    _pending = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return result;
  }
}

void validateQuery(Query query, List<String> sortFields) {
  if (query.page < 1 || ![10, 25, 50].contains(query.size)) {
    throw ArgumentError('Некорректные параметры страницы');
  }
  if (!sortFields.contains(query.sortField)) {
    throw ArgumentError('Неизвестное поле сортировки');
  }
}

PageResult<T> buildPage<T>(List<T> rows, Query query) {
  final total = rows.length;
  final totalPages = total == 0 ? 1 : (total / query.size).ceil();
  final page = query.page > totalPages ? totalPages : query.page;
  final start = (page - 1) * query.size;
  final end = start + query.size > total ? total : start + query.size;
  return PageResult(
    items: rows.sublist(start, end),
    page: page,
    size: query.size,
    total: total,
  );
}
