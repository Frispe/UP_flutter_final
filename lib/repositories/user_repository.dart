import '../models/user.dart';
import '../models/page_result.dart';
import '../models/query.dart';
import '../models/cart.dart';
import 'store.dart';

class UserRepository {
  UserRepository(this.store);
  final Store store;
  List<User> get rows => store.users;

  Future<bool> emailExists(String email, {int? exceptId}) async {
    final value = email.trim().toLowerCase();
    return rows.any((item) => item.id != exceptId && item.email.trim().toLowerCase() == value);
  }


  int productCount(int id) { return 0; }
  Future<Map<int, int>> productCounts() async => {for (final item in rows) item.id: productCount(item.id)};

  bool hasCartItems(int userId) {
    final ids = store.carts.where((cart) => cart.userId == userId).map((cart) => cart.id).toSet();
    return store.cartItems.any((item) => ids.contains(item.cartId));
  }

  Future<PageResult<User>> find(Query query) async {
    validateQuery(query, ['name', 'email', 'nickname', 'id']);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final search = query.search.trim().toLowerCase();
    final result = rows.where((item) => (query.includeDeleted || !item.isDeleted) && (query.hasCartItems == null || hasCartItems(item.id) == query.hasCartItems) && '${item.name} ${item.email} ${item.nickname}'.toLowerCase().contains(search)).toList();
    result.sort((a, b) {
      final comparison = switch (query.sortField) {
        'id' => a.id.compareTo(b.id),
        'email' => a.email.compareTo(b.email), 'nickname' => a.nickname.compareTo(b.nickname),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      if (comparison == 0) { return a.id.compareTo(b.id); }
      return query.sortAscending ? comparison : -comparison;
    });
    return buildPage(result, query);
  }

  Future<User?> findById(int id) async {
    for (final item in rows) { if (item.id == id) { return item; } }
    return null;
  }

  int _index(int id) {
    final index = rows.indexWhere((item) => item.id == id);
    if (index < 0) { throw StateError('Запись не найдена'); }
    return index;
  }

  void _validate(User item, {int? currentId}) {
    if (item.name.trim().isEmpty || item.name.trim().length > 100) {
      throw ArgumentError('Название или имя должно содержать от 1 до 100 символов');
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(item.email.trim())) {
      throw ArgumentError('Укажите корректную почту');
    }
    if (item.nickname.trim().length > 50 || item.email.trim().length > 254) {
      throw ArgumentError('Превышена допустимая длина поля');
    }
    if (rows.any((other) => other.id != currentId && other.email.toLowerCase() == item.email.trim().toLowerCase())) {
      throw ArgumentError('Пользователь с такой почтой уже существует');
    }
  }

  Future<User> create(User item) => store.change(() {
    _validate(item);
    final created = User(id: store.nextUserId++, name: item.name.trim(), email: item.email.trim().toLowerCase(), nickname: item.nickname.trim(),);
    rows.add(created);
    store.carts.add(Cart(id: store.nextCartId++, userId: created.id));
    return created;
  });

  Future<User> update(User item) => store.change(() {
    final index = _index(item.id);
    _validate(item, currentId: item.id);
    final updated = rows[index].copyWith(name: item.name.trim(), email: item.email.trim().toLowerCase(), nickname: item.nickname.trim(),);
    rows[index] = updated;
    return updated;
  });

  void _checkDelete(int id) {
    _index(id);
  }

  Future<void> softDelete(int id) => store.change<void>(() {
    _checkDelete(id);
    final index = _index(id);
    if (!rows[index].isDeleted) { rows[index] = rows[index].copyWith(deletedAt: DateTime.now()); }
  });

  Future<void> hardDelete(int id) => store.change<void>(() {
    _checkDelete(id);
    final cartIds = store.carts.where((cart) => cart.userId == id).map((cart) => cart.id).toSet();
    store.cartItems.removeWhere((item) => cartIds.contains(item.cartId));
    store.carts.removeWhere((cart) => cart.userId == id);
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
