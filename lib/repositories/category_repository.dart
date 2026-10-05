import '../models/category.dart';
import '../models/page_result.dart';
import '../models/query.dart';

import 'store.dart';

abstract interface class CategoryRepository {
  Future<Map<int, int>> productCounts();
  Future<PageResult<Category>> find(Query query);
  Future<Category?> findById(int id);
  Future<List<Category>> options({bool includeDeleted = false});
  Future<Category> create(Category item);
  Future<Category> update(Category item);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}

class MemoryCategoryRepository implements CategoryRepository {
  MemoryCategoryRepository(this.store);
  final Store store;
  List<Category> get rows => store.categories;

  int productCount(int id) {
    return store.products.where((p) => p.categoryIds.contains(id)).length;
  }

  @override
  Future<Map<int, int>> productCounts() async => {
    for (final item in rows) item.id: productCount(item.id),
  };

  @override
  Future<PageResult<Category>> find(Query query) async {
    validateQuery(query, ['name', 'id', 'productCount']);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final search = query.search.trim().toLowerCase();
    final result = rows
        .where(
          (item) =>
              (query.includeDeleted || !item.isDeleted) &&
              (query.hasProducts == null ||
                  (productCount(item.id) > 0) == query.hasProducts) &&
              item.name.toLowerCase().contains(search),
        )
        .toList();
    result.sort((a, b) {
      final comparison = switch (query.sortField) {
        'id' => a.id.compareTo(b.id),
        'productCount' => productCount(a.id).compareTo(productCount(b.id)),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      if (comparison == 0) {
        return a.id.compareTo(b.id);
      }
      return query.sortAscending ? comparison : -comparison;
    });
    return buildPage(result, query);
  }

  @override
  Future<Category?> findById(int id) async {
    for (final item in rows) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<List<Category>> options({bool includeDeleted = false}) async =>
      List.unmodifiable(
        rows.where((item) => includeDeleted || !item.isDeleted),
      );

  int _index(int id) {
    final index = rows.indexWhere((item) => item.id == id);
    if (index < 0) {
      throw StateError('Запись не найдена');
    }
    return index;
  }

  void _validate(Category item, {int? currentId}) {
    if (item.name.trim().isEmpty || item.name.trim().length > 100) {
      throw ArgumentError(
        'Название или имя должно содержать от 1 до 100 символов',
      );
    }
    if (rows.any(
      (other) =>
          other.id != currentId &&
          other.name.toLowerCase() == item.name.trim().toLowerCase(),
    )) {
      throw ArgumentError('Запись с таким названием уже существует');
    }
  }

  @override
  Future<Category> create(Category item) => store.change(() {
    _validate(item);
    final created = Category(
      id: store.nextCategoryId++,
      name: item.name.trim(),
    );
    rows.add(created);

    return created;
  });

  @override
  Future<Category> update(Category item) => store.change(() {
    final index = _index(item.id);
    _validate(item, currentId: item.id);
    final updated = rows[index].copyWith(name: item.name.trim());
    rows[index] = updated;
    return updated;
  });

  void _checkDelete(int id) {
    _index(id);
    final count = productCount(id);
    if (count > 0) {
      throw StateError('Удаление невозможно. Связанных товаров: $count');
    }
  }

  @override
  Future<void> softDelete(int id) => store.change<void>(() {
    _checkDelete(id);
    final index = _index(id);
    if (!rows[index].isDeleted) {
      rows[index] = rows[index].copyWith(deletedAt: DateTime.now());
    }
  });

  @override
  Future<void> hardDelete(int id) => store.change<void>(() {
    _checkDelete(id);

    rows.removeAt(_index(id));
  });

  @override
  Future<void> restore(int id) => store.change<void>(() {
    final index = _index(id);
    rows[index] = rows[index].copyWith(clearDeletedAt: true);
  });

  @override
  Future<int> deleteMany(List<int> ids) => store.change(() {
    final selected = rows
        .where((item) => ids.contains(item.id) && !item.isDeleted)
        .toList();
    for (final item in selected) {
      _checkDelete(item.id);
    }
    final now = DateTime.now();
    for (final item in selected) {
      rows[_index(item.id)] = item.copyWith(deletedAt: now);
    }
    return selected.length;
  });
}
