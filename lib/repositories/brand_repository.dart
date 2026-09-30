import '../models/brand.dart';
import '../models/page_result.dart';
import '../models/query.dart';
import 'store.dart';

abstract interface class BrandRepository {
  Future<PageResult<Brand>> find(Query query);
  Future<Brand?> findById(int id);
  Future<Map<int, int>> productCounts();
  Future<Brand> create(Brand brand);
  Future<Brand> update(Brand brand);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}

class MemoryBrandRepository implements BrandRepository {
  MemoryBrandRepository(this._store);

  final Store _store;

  Map<int, int> _counts() {
    final counts = <int, int>{};
    for (final product in _store.products) {
      if (!product.isDeleted) {
        counts[product.brandId] = (counts[product.brandId] ?? 0) + 1;
      }
    }
    return counts;
  }

  @override
  Future<Map<int, int>> productCounts() async => Map.unmodifiable(_counts());

  @override
  Future<PageResult<Brand>> find(Query query) async {
    validateQuery(query, ['name', 'id', 'productCount']);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final search = query.search.trim().toLowerCase();
    final rows = _store.brands.where((brand) {
      return (query.includeDeleted || !brand.isDeleted) &&
          brand.name.toLowerCase().contains(search);
    }).toList();
    final counts = _counts();
    rows.sort((a, b) {
      final result = switch (query.sortField) {
        'id' => a.id.compareTo(b.id),
        'productCount' => (counts[a.id] ?? 0).compareTo(counts[b.id] ?? 0),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      if (result == 0) return a.id.compareTo(b.id);
      return query.sortAscending ? result : -result;
    });
    return buildPage(rows, query);
  }

  @override
  Future<Brand?> findById(int id) async {
    for (final brand in _store.brands) {
      if (brand.id == id) return brand;
    }
    return null;
  }

  int _indexOf(int id) {
    final index = _store.brands.indexWhere((item) => item.id == id);
    if (index == -1) throw StateError('Бренд не найден');
    return index;
  }

  void _validate(Brand brand, {int? currentId}) {
    final name = brand.name.trim().toLowerCase();
    if (name.isEmpty) throw ArgumentError('Укажите название бренда');
    if (_store.brands.any((item) =>
        item.id != currentId && item.name.trim().toLowerCase() == name)) {
      throw ArgumentError('Бренд с таким названием уже существует');
    }
  }

  @override
  Future<Brand> create(Brand brand) async {
    _validate(brand);
    final created = Brand(id: _store.nextBrandId++, name: brand.name.trim());
    _store.brands.add(created);
    return created;
  }

  @override
  Future<Brand> update(Brand brand) async {
    final index = _indexOf(brand.id);
    _validate(brand, currentId: brand.id);
    final updated = _store.brands[index].copyWith(name: brand.name.trim());
    _store.brands[index] = updated;
    return updated;
  }

  @override
  Future<void> softDelete(int id) async {
    final index = _indexOf(id);
    if (_store.brands[index].isDeleted) return;
    _store.brands[index] = _store.brands[index].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    final index = _indexOf(id);
    if (_store.products.any((product) => product.brandId == id)) {
      throw StateError('Сначала удалите или перенесите все товары этого бренда');
    }
    _store.brands.removeAt(index);
  }

  @override
  Future<void> restore(int id) async {
    final index = _indexOf(id);
    _store.brands[index] = _store.brands[index].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    final selected = ids.toSet();
    final now = DateTime.now();
    var count = 0;
    for (var i = 0; i < _store.brands.length; i++) {
      final brand = _store.brands[i];
      if (selected.contains(brand.id) && !brand.isDeleted) {
        _store.brands[i] = brand.copyWith(deletedAt: now);
        count++;
      }
    }
    return count;
  }
}
