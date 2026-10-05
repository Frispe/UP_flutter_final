import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/brand.dart';
import '../models/cart.dart';
import '../models/cart_item.dart';
import '../models/category.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/page_result.dart';
import '../models/platform.dart';
import '../models/product.dart';
import '../models/query.dart';
import '../models/user.dart';
import 'brand_repository.dart';
import 'cart_repository.dart';
import 'category_repository.dart';
import 'platform_repository.dart';
import 'product_repository.dart';
import 'user_repository.dart';

Map<String, dynamic> _query(Query query) => {
  if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
  if (query.type != null) 'type': query.type!.name,
  if (query.brandId != null) 'brandId': query.brandId,
  if (query.priceFrom != null) 'priceFrom': query.priceFrom,
  if (query.priceTo != null) 'priceTo': query.priceTo,
  if (query.hasProducts != null) 'hasProducts': query.hasProducts,
  if (query.hasCartItems != null) 'hasCartItems': query.hasCartItems,
  'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
  'page': query.page,
  'size': query.size,
  if (query.includeDeleted) 'includeDeleted': true,
};

Map<String, dynamic> _map(dynamic value) {
  return Map<String, dynamic>.from(value as Map);
}

PageResult<T> _page<T>(dynamic value, T Function(Map<String, dynamic>) read) {
  final data = _map(value);
  final rawItems = data['items'];
  final items = rawItems is List
      ? rawItems.map((item) => read(_map(item))).toList()
      : <T>[];
  return PageResult<T>(
    items: items,
    page: data['page'] as int? ?? 1,
    size: data['size'] as int? ?? 10,
    total: data['total'] as int? ?? 0,
  );
}

abstract class _ApiCrud<T> {
  _ApiCrud(this.dio, this.path, this.read);

  final Dio dio;
  final String path;
  final T Function(Map<String, dynamic>) read;

  Future<PageResult<T>> findPage(Query query, {CancelToken? cancelToken}) =>
      guard(() async {
        final response = await dio.get(
          path,
          queryParameters: _query(query),
          cancelToken: cancelToken,
        );
        return _page(response.data, read);
      });

  Future<T?> findOne(int id) => guard(() async {
    try {
      final response = await dio.get('$path/$id');
      return read(_map(response.data));
    } on DioException catch (error) {
      if (mapDioError(error) is NotFoundException) return null;
      rethrow;
    }
  });

  Future<T> createOne(Map<String, dynamic> data) => guard(() async {
    final response = await dio.post(path, data: data);
    return read(_map(response.data));
  });

  Future<T> updateOne(int id, Map<String, dynamic> data) => guard(() async {
    final response = await dio.put('$path/$id', data: data);
    return read(_map(response.data));
  });

  Future<void> softDeleteOne(int id) => guard(() async {
    await dio.delete('$path/$id');
  });

  Future<void> hardDeleteOne(int id) => guard(() async {
    await dio.delete('$path/$id', queryParameters: {'hard': true});
  });

  Future<void> restoreOne(int id) => guard(() async {
    await dio.post('$path/$id/restore');
  });

  Future<int> deleteManyOnes(List<int> ids) => guard(() async {
    final response = await dio.post('$path/bulk-delete', data: {'ids': ids});
    return _map(response.data)['deleted'] as int? ?? 0;
  });
}

mixin _OptionsCache<T> on _ApiCrud<T> {
  final Map<bool, List<T>> _cachedOptions = {};

  Future<List<T>> optionsFromCache({bool includeDeleted = false}) async {
    final cached = _cachedOptions[includeDeleted];
    if (cached != null) return cached;
    final result = await findPage(
      Query(size: 50, includeDeleted: includeDeleted),
    );
    final items = List<T>.unmodifiable(result.items);
    _cachedOptions[includeDeleted] = items;
    return items;
  }

  void clearOptionsCache() => _cachedOptions.clear();
}

Future<Map<int, int>> _productCounts(Dio dio, String field) => guard(() async {
  final path = switch (field) {
    'brandId' => '/brands',
    'categoryIds' => '/categories',
    _ => '/platforms',
  };
  final response = await dio.get(
    path,
    queryParameters: {'page': 1, 'size': 100},
  );
  final data = _map(response.data);
  return {
    for (final value in data['items'] as List? ?? const [])
      if (_map(value)['id'] is int)
        _map(value)['id'] as int: _map(value)['productCount'] as int? ?? 0,
  };
});

class ApiProductRepository extends _ApiCrud<Product>
    implements ProductRepository {
  ApiProductRepository(Dio dio) : super(dio, '/products', Product.fromJson);

  final Map<int, String> _platformNames = {};
  CancelToken? _findToken;

  Future<void> _loadPlatforms() async {
    if (_platformNames.isNotEmpty) return;
    await guard(() async {
      final response = await dio.get(
        '/platforms',
        queryParameters: {'page': 1, 'size': 100},
      );
      final data = _map(response.data);
      for (final value in data['items'] as List? ?? const []) {
        final item = _map(value);
        final id = item['id'];
        final name = item['name'];
        if (id is int && name is String) _platformNames[id] = name;
      }
    });
  }

  @override
  Future<PageResult<Product>> find(Query query) async {
    _findToken?.cancel('Отправлен новый запрос товаров');
    final token = CancelToken();
    _findToken = token;
    await _loadPlatforms();
    try {
      return await findPage(query, cancelToken: token);
    } finally {
      if (identical(_findToken, token)) {
        _findToken = null;
      }
    }
  }

  @override
  Future<Product?> findById(int id) => findOne(id);

  @override
  String platformName(int id) => _platformNames[id] ?? 'Платформа № $id';

  @override
  Future<bool> skuExists(String sku, {int? exceptId}) => guard(() async {
    final response = await dio.get(
      '/products',
      queryParameters: {'search': sku.trim(), 'page': 1, 'size': 100},
    );
    final data = _map(response.data);
    return (data['items'] as List? ?? const []).any((value) {
      final item = _map(value);
      return item['id'] != exceptId &&
          item['sku'].toString().toLowerCase() == sku.trim().toLowerCase();
    });
  });

  @override
  Future<Product> create(Product product) => createOne(product.toJson());

  @override
  Future<Product> update(Product product) =>
      updateOne(product.id, product.toJson());

  @override
  Future<void> softDelete(int id) => softDeleteOne(id);

  @override
  Future<void> hardDelete(int id) => hardDeleteOne(id);

  @override
  Future<void> restore(int id) => restoreOne(id);

  @override
  Future<int> deleteMany(List<int> ids) => deleteManyOnes(ids);
}

class ApiBrandRepository extends _ApiCrud<Brand>
    with _OptionsCache<Brand>
    implements BrandRepository {
  ApiBrandRepository(Dio dio) : super(dio, '/brands', Brand.fromJson);

  @override
  Future<PageResult<Brand>> find(Query query) => findPage(query);

  @override
  Future<Brand?> findById(int id) => findOne(id);

  @override
  Future<List<Brand>> options({bool includeDeleted = false}) =>
      optionsFromCache(includeDeleted: includeDeleted);

  @override
  Future<Map<int, int>> productCounts() => _productCounts(dio, 'brandId');

  @override
  Future<Brand> create(Brand brand) async {
    final result = await createOne(brand.toJson());
    clearOptionsCache();
    return result;
  }

  @override
  Future<Brand> update(Brand brand) async {
    final result = await updateOne(brand.id, brand.toJson());
    clearOptionsCache();
    return result;
  }

  @override
  Future<void> softDelete(int id) async {
    await softDeleteOne(id);
    clearOptionsCache();
  }

  @override
  Future<void> hardDelete(int id) async {
    await hardDeleteOne(id);
    clearOptionsCache();
  }

  @override
  Future<void> restore(int id) async {
    await restoreOne(id);
    clearOptionsCache();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    final result = await deleteManyOnes(ids);
    clearOptionsCache();
    return result;
  }
}

class ApiCategoryRepository extends _ApiCrud<Category>
    with _OptionsCache<Category>
    implements CategoryRepository {
  ApiCategoryRepository(Dio dio) : super(dio, '/categories', Category.fromJson);

  @override
  Future<PageResult<Category>> find(Query query) => findPage(query);

  @override
  Future<Category?> findById(int id) => findOne(id);

  @override
  Future<List<Category>> options({bool includeDeleted = false}) =>
      optionsFromCache(includeDeleted: includeDeleted);

  @override
  Future<Map<int, int>> productCounts() => _productCounts(dio, 'categoryIds');

  @override
  Future<Category> create(Category item) async {
    final result = await createOne(item.toJson());
    clearOptionsCache();
    return result;
  }

  @override
  Future<Category> update(Category item) async {
    final result = await updateOne(item.id, item.toJson());
    clearOptionsCache();
    return result;
  }

  @override
  Future<void> softDelete(int id) async {
    await softDeleteOne(id);
    clearOptionsCache();
  }

  @override
  Future<void> hardDelete(int id) async {
    await hardDeleteOne(id);
    clearOptionsCache();
  }

  @override
  Future<void> restore(int id) async {
    await restoreOne(id);
    clearOptionsCache();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    final result = await deleteManyOnes(ids);
    clearOptionsCache();
    return result;
  }
}

class ApiPlatformRepository extends _ApiCrud<Platform>
    with _OptionsCache<Platform>
    implements PlatformRepository {
  ApiPlatformRepository(Dio dio) : super(dio, '/platforms', Platform.fromJson);

  @override
  Future<PageResult<Platform>> find(Query query) => findPage(query);

  @override
  Future<Platform?> findById(int id) => findOne(id);

  @override
  Future<List<Platform>> options({bool includeDeleted = false}) =>
      optionsFromCache(includeDeleted: includeDeleted);

  @override
  Future<Map<int, int>> productCounts() => _productCounts(dio, 'platformId');

  @override
  Future<Platform> create(Platform item) async {
    final result = await createOne(item.toJson());
    clearOptionsCache();
    return result;
  }

  @override
  Future<Platform> update(Platform item) async {
    final result = await updateOne(item.id, item.toJson());
    clearOptionsCache();
    return result;
  }

  @override
  Future<void> softDelete(int id) async {
    await softDeleteOne(id);
    clearOptionsCache();
  }

  @override
  Future<void> hardDelete(int id) async {
    await hardDeleteOne(id);
    clearOptionsCache();
  }

  @override
  Future<void> restore(int id) async {
    await restoreOne(id);
    clearOptionsCache();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    final result = await deleteManyOnes(ids);
    clearOptionsCache();
    return result;
  }
}

class ApiUserRepository extends _ApiCrud<User> implements UserRepository {
  ApiUserRepository(Dio dio) : super(dio, '/customers', User.fromJson);

  @override
  Future<PageResult<User>> find(Query query) => findPage(query);

  @override
  Future<User?> findById(int id) => findOne(id);

  @override
  Future<bool> emailExists(String email, {int? exceptId}) => guard(() async {
    final response = await dio.get(
      '/customers',
      queryParameters: {'search': email.trim(), 'page': 1, 'size': 100},
    );
    final data = _map(response.data);
    return (data['items'] as List? ?? const []).any((value) {
      final item = _map(value);
      return item['id'] != exceptId &&
          item['email'].toString().toLowerCase() == email.trim().toLowerCase();
    });
  });

  @override
  Future<Map<int, int>> productCounts() async => const {};

  @override
  Future<User> create(User item) => guard(() async {
    final user = await createOne(item.toJson());
    await dio.post('/carts', data: {'customerId': user.id});
    return user;
  });

  @override
  Future<User> update(User item) => updateOne(item.id, item.toJson());

  @override
  Future<void> softDelete(int id) => softDeleteOne(id);

  @override
  Future<void> hardDelete(int id) => hardDeleteOne(id);

  @override
  Future<void> restore(int id) => restoreOne(id);

  @override
  Future<int> deleteMany(List<int> ids) => deleteManyOnes(ids);
}

class ApiCartRepository implements CartRepository {
  ApiCartRepository(this.dio);

  final Dio dio;

  Future<Cart> _cart(int userId) => guard(() async {
    final response = await dio.get(
      '/carts',
      queryParameters: {'customerId': userId, 'page': 1, 'size': 10},
    );
    final page = _page(response.data, Cart.fromJson);
    if (page.items.isEmpty) {
      throw const NotFoundException('Корзина не найдена.');
    }
    return page.items.first;
  });

  Future<List<CartItem>> _items(int cartId) => guard(() async {
    final response = await dio.get(
      '/cart-items',
      queryParameters: {'cartId': cartId, 'page': 1, 'size': 100},
    );
    return _page(response.data, CartItem.fromJson).items;
  });

  @override
  Future<CartData> find(int userId) => guard(() async {
    final cart = await _cart(userId);
    final items = await _items(cart.id);
    final products = <int, Product>{};
    for (final id in items.map((item) => item.productId).toSet()) {
      final response = await dio.get('/products/$id');
      products[id] = Product.fromJson(_map(response.data));
    }
    return CartData(cart: cart, items: items, products: products);
  });

  @override
  Future<void> add(int userId, int productId, {int quantity = 1}) =>
      guard(() async {
        final cart = await _cart(userId);
        final items = await _items(cart.id);
        final matches = items.where((item) => item.productId == productId);
        if (matches.isEmpty) {
          await dio.post(
            '/cart-items',
            data: {
              'cartId': cart.id,
              'productId': productId,
              'quantity': quantity,
            },
          );
        } else {
          final item = matches.first;
          await dio.put(
            '/cart-items/${item.id}',
            data: item.copyWith(quantity: item.quantity + quantity).toJson(),
          );
        }
      });

  @override
  Future<void> setQuantity(int userId, int itemId, int quantity) =>
      guard(() async {
        final cart = await _cart(userId);
        final response = await dio.get('/cart-items/$itemId');
        final item = CartItem.fromJson(_map(response.data));
        if (item.cartId != cart.id) {
          throw const ForbiddenException('Позиция относится к другой корзине.');
        }
        await dio.put(
          '/cart-items/$itemId',
          data: item.copyWith(quantity: quantity).toJson(),
        );
      });

  @override
  Future<void> remove(int userId, int itemId) => guard(() async {
    final cart = await _cart(userId);
    final response = await dio.get('/cart-items/$itemId');
    final item = CartItem.fromJson(_map(response.data));
    if (item.cartId != cart.id) {
      throw const ForbiddenException('Позиция относится к другой корзине.');
    }
    await dio.delete('/cart-items/$itemId');
  });

  @override
  Future<void> clear(int userId) => guard(() async {
    final cart = await _cart(userId);
    final items = await _items(cart.id);
    if (items.isEmpty) return;
    await dio.post(
      '/cart-items/bulk-delete',
      data: {'ids': items.map((item) => item.id).toList()},
    );
  });
}

class ApiOrderRepository extends _ApiCrud<Order> {
  ApiOrderRepository(Dio dio) : super(dio, '/orders', Order.fromJson);

  Future<PageResult<Order>> find({
    int page = 1,
    int size = 10,
    int? userId,
    String? status,
    bool includeDeleted = false,
  }) => guard(() async {
    final response = await dio.get(
      '/orders',
      queryParameters: {
        'page': page,
        'size': size,
        'customerId': ?userId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (includeDeleted) 'includeDeleted': true,
        'sort': 'orderedAt,desc',
      },
    );
    return _page(response.data, Order.fromJson);
  });

  Future<Order?> findById(int id) => findOne(id);

  Future<List<OrderItem>> findItems(int orderId) => guard(() async {
    final response = await dio.get(
      '/order-items',
      queryParameters: {'orderId': orderId, 'page': 1, 'size': 100},
    );
    return _page(response.data, OrderItem.fromJson).items;
  });

  Future<Order> checkout(int cartId) => guard(() async {
    final response = await dio.post('/carts/$cartId/checkout');
    return Order.fromJson(_map(response.data));
  });

  Future<Order> updateStatus(Order order, String status) =>
      updateOne(order.id, order.copyWith(status: status).toJson());

  Future<void> softDelete(int id) => softDeleteOne(id);

  Future<void> hardDelete(int id) => hardDeleteOne(id);

  Future<void> restore(int id) => restoreOne(id);

  Future<int> deleteMany(List<int> ids) => deleteManyOnes(ids);
}
