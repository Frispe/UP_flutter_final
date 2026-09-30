import '../models/page_result.dart';
import '../models/product.dart';
import '../models/query.dart';
import 'store.dart';

abstract interface class ProductRepository {
  Future<PageResult<Product>> find(Query query);
  Future<Product?> findById(int id);
  Future<Product> create(Product product);
  Future<Product> update(Product product);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}

class MemoryProductRepository implements ProductRepository {
  MemoryProductRepository(this._store);

  final Store _store;

  @override
  Future<PageResult<Product>> find(Query query) async {
    validateQuery(query, ['name', 'price', 'sku']);
    if ((query.priceFrom != null && query.priceFrom! < 0) ||
        (query.priceTo != null && query.priceTo! < 0) ||
        (query.priceFrom != null &&
            query.priceTo != null &&
            query.priceFrom! > query.priceTo!)) {
      throw ArgumentError('Некорректный диапазон цены');
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final search = query.search.trim().toLowerCase();
    final rows = _store.products.where((item) {
      if (!query.includeDeleted && item.isDeleted) {
        return false;
      }
      if (search.isNotEmpty &&
          !item.name.toLowerCase().contains(search) &&
          !item.sku.toLowerCase().contains(search)) {
        return false;
      }
      if (query.type != null && item.type != query.type) {
        return false;
      }
      if (query.brandId != null && item.brandId != query.brandId) {
        return false;
      }
      if (query.priceFrom != null && item.price < query.priceFrom!) {
        return false;
      }
      if (query.priceTo != null && item.price > query.priceTo!) {
        return false;
      }
      return true;
    }).toList();
    rows.sort((a, b) {
      final result = switch (query.sortField) {
        'price' => a.price.compareTo(b.price),
        'sku' => a.sku.toLowerCase().compareTo(b.sku.toLowerCase()),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      if (result == 0) {
        return a.id.compareTo(b.id);
      }
      return query.sortAscending ? result : -result;
    });
    return buildPage(rows, query);
  }

  @override
  Future<Product?> findById(int id) async {
    for (final product in _store.products) {
      if (product.id == id) {
        return product;
      }
    }
    return null;
  }

  int _indexOf(int id) {
    final index = _store.products.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw StateError('Товар не найден');
    }
    return index;
  }

  void _validate(Product product, {int? currentId}) {
    if (product.name.trim().isEmpty ||
        product.sku.trim().isEmpty ||
        product.description.trim().isEmpty ||
        product.platform.trim().isEmpty ||
        product.region.trim().isEmpty) {
      throw ArgumentError('Заполните обязательные поля товара');
    }
    if (product.price < 0) {
      throw ArgumentError('Цена не может быть отрицательной');
    }
    if (product.type == ProductType.aiSubscription &&
        (product.durationMonths == null || product.durationMonths! <= 0)) {
      throw ArgumentError('Укажите срок подписки в месяцах');
    }
    if (product.type == ProductType.gameKey && product.durationMonths != null) {
      throw ArgumentError('У игрового ключа не должно быть срока подписки');
    }
    final brandIndex = _store.brands.indexWhere((b) => b.id == product.brandId);
    if (brandIndex == -1) {
      throw ArgumentError('Бренд не найден');
    }
    final keepsBrand =
        currentId != null &&
        _store.products.any(
          (item) => item.id == currentId && item.brandId == product.brandId,
        );
    if (_store.brands[brandIndex].isDeleted && !keepsBrand) {
      throw ArgumentError('Нельзя выбрать удалённый бренд');
    }
    final sku = product.sku.trim().toLowerCase();
    if (_store.products.any(
      (item) => item.id != currentId && item.sku.trim().toLowerCase() == sku,
    )) {
      throw ArgumentError('Товар с таким артикулом уже существует');
    }
  }

  @override
  Future<Product> create(Product product) async {
    _validate(product);
    final created = Product(
      id: _store.nextProductId++,
      name: product.name.trim(),
      sku: product.sku.trim(),
      description: product.description.trim(),
      type: product.type,
      brandId: product.brandId,
      price: product.price,
      platform: product.platform.trim(),
      region: product.region.trim(),
      durationMonths: product.durationMonths,
    );
    _store.products.add(created);
    return created;
  }

  @override
  Future<Product> update(Product product) async {
    final index = _indexOf(product.id);
    _validate(product, currentId: product.id);
    final updated = product.copyWith(
      name: product.name.trim(),
      sku: product.sku.trim(),
      description: product.description.trim(),
      platform: product.platform.trim(),
      region: product.region.trim(),
      deletedAt: _store.products[index].deletedAt,
      clearDeletedAt: !_store.products[index].isDeleted,
    );
    _store.products[index] = updated;
    return updated;
  }

  @override
  Future<void> softDelete(int id) async {
    final index = _indexOf(id);
    if (_store.products[index].isDeleted) {
      return;
    }
    _store.products[index] = _store.products[index].copyWith(
      deletedAt: DateTime.now(),
    );
  }

  @override
  Future<void> hardDelete(int id) async {
    _store.products.removeAt(_indexOf(id));
  }

  @override
  Future<void> restore(int id) async {
    final index = _indexOf(id);
    _store.products[index] = _store.products[index].copyWith(
      clearDeletedAt: true,
    );
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    final selected = ids.toSet();
    final now = DateTime.now();
    var count = 0;
    for (var i = 0; i < _store.products.length; i++) {
      final product = _store.products[i];
      if (selected.contains(product.id) && !product.isDeleted) {
        _store.products[i] = product.copyWith(deletedAt: now);
        count++;
      }
    }
    return count;
  }
}
