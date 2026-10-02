import '../models/platform.dart';
import '../models/page_result.dart';
import '../models/query.dart';

import 'store.dart';

class PlatformRepository {
  PlatformRepository(this.store);
  final Store store;
  List<Platform> get rows => store.platforms;

  int productCount(int id) { return store.products.where((p) => p.platformId == id).length; }
  Future<Map<int, int>> productCounts() async => {for (final item in rows) item.id: productCount(item.id)};

  Future<PageResult<Platform>> find(Query query) async {
    validateQuery(query, ['name', 'id', 'productCount']);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final search = query.search.trim().toLowerCase();
    final result = rows.where((item) => (query.includeDeleted || !item.isDeleted) && (query.hasProducts == null || (productCount(item.id) > 0) == query.hasProducts) && item.name.toLowerCase().contains(search)).toList();
    result.sort((a, b) {
      final comparison = switch (query.sortField) {
        'id' => a.id.compareTo(b.id),
        'productCount' => productCount(a.id).compareTo(productCount(b.id)),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      if (comparison == 0) { return a.id.compareTo(b.id); }
      return query.sortAscending ? comparison : -comparison;
    });
    return buildPage(result, query);
  }

  Future<Platform?> findById(int id) async {
    for (final item in rows) { if (item.id == id) { return item; } }
    return null;
  }

  int _index(int id) {
    final index = rows.indexWhere((item) => item.id == id);
    if (index < 0) { throw StateError('Запись не найдена'); }
    return index;
  }

  void _validate(Platform item, {int? currentId}) {
    if (item.name.trim().isEmpty || item.name.trim().length > 100) {
      throw ArgumentError('Название или имя должно содержать от 1 до 100 символов');
    }
    if (rows.any((other) => other.id != currentId && other.name.toLowerCase() == item.name.trim().toLowerCase())) {
      throw ArgumentError('Запись с таким названием уже существует');
    }
  }

  Future<Platform> create(Platform item) => store.change(() {
    _validate(item);
    final created = Platform(id: store.nextPlatformId++, name: item.name.trim(), );
    rows.add(created);
    
    return created;
  });

  Future<Platform> update(Platform item) => store.change(() {
    final index = _index(item.id);
    _validate(item, currentId: item.id);
    final updated = rows[index].copyWith(name: item.name.trim(), );
    rows[index] = updated;
    return updated;
  });

  void _checkDelete(int id) {
    _index(id);
    final count = productCount(id);
    if (count > 0) {
      throw StateError('Удаление невозможно. Связанных товаров: $count');
    }
    final brands = store.brands.where((brand) => brand.platformIds.contains(id)).length;
    if (brands > 0) {
      throw StateError('Удаление невозможно. Связанных брендов: $brands');
    }
  }

  Future<void> softDelete(int id) => store.change<void>(() {
    _checkDelete(id);
    final index = _index(id);
    if (!rows[index].isDeleted) { rows[index] = rows[index].copyWith(deletedAt: DateTime.now()); }
  });

  Future<void> hardDelete(int id) => store.change<void>(() {
    _checkDelete(id);
    
    rows.removeAt(_index(id));
  });

  Future<void> restore(int id) => store.change<void>(() {
    final index = _index(id);
    rows[index] = rows[index].copyWith(clearDeletedAt: true);
  });

  Future<int> deleteMany(List<int> ids) => store.change(() {
    final selected = rows.where((item) => ids.contains(item.id) && !item.isDeleted).toList();
    for (final item in selected) { _checkDelete(item.id); }
    final now = DateTime.now();
    for (final item in selected) { rows[_index(item.id)] = item.copyWith(deletedAt: now); }
    return selected.length;
  });
}
