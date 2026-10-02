import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../models/page_result.dart';
import '../models/query.dart';
import '../repositories/user_repository.dart';
import 'status.dart';

class UserState extends ChangeNotifier {
  UserState(this._repository);

  final UserRepository _repository;

  Map<int, int> _counts = {};
  Query _query = const Query();
  PageResult<User> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  String? _actionError;
  final Set<int> _selected = {};
  bool _saving = false;
  bool _disposed = false;
  int _request = 0;

  Query get query => _query;
  PageResult<User> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  String? get actionError => _actionError;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;
  bool get saving => _saving;
  Map<int, int> get counts => Map.unmodifiable(_counts);
  int productCount(int id) => _counts[id] ?? 0;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    if (_disposed) {
      return;
    }
    final request = ++_request;
    final query = _query;
    _status = LoadStatus.loading;
    _error = null;
    _notify();
    try {
      final result = await _repository.find(query);
      final counts = await _repository.productCounts();
      if (_disposed || request != _request) {
        return;
      }
      _result = result;
      _counts = counts;
      _query = query.copyWith(page: result.page);
      final activeIds = result.items
          .where((item) => !item.isDeleted)
          .map((item) => item.id)
          .toSet();
      _selected.removeWhere((id) => !activeIds.contains(id));
      _status = result.items.isEmpty ? LoadStatus.empty : LoadStatus.success;
    } catch (error) {
      if (_disposed || request != _request) {
        return;
      }
      _status = LoadStatus.error;
      _error = errorText(error);
      _selected.clear();
    }
    _notify();
  }

  Future<void> applyQuery(Query query) async {
    if (_disposed) {
      return;
    }
    _query = query;
    _selected.clear();
    _actionError = null;
    await load();
  }

  void toggleSelection(int id) {
    if (_disposed || _saving || _status != LoadStatus.success) {
      return;
    }
    if (!_result.items.any((item) => item.id == id && !item.isDeleted)) {
      return;
    }
    if (!_selected.add(id)) _selected.remove(id);
    _notify();
  }

  void selectAll(bool selected) {
    if (_disposed || _saving || _status != LoadStatus.success) {
      return;
    }
    _selected.clear();
    if (selected) {
      _selected.addAll(
        _result.items.where((item) => !item.isDeleted).map((item) => item.id),
      );
    }
    _notify();
  }

  void clearSelection() {
    if (_disposed || _saving) {
      return;
    }
    _selected.clear();
    _notify();
  }

  void clearActionError() {
    if (_disposed) {
      return;
    }
    _actionError = null;
    _notify();
  }

  Future<User?> findById(int id) => _repository.findById(id);

  Future<bool> emailExists(String email, {int? exceptId}) => _repository.emailExists(email, exceptId: exceptId);

  Future<List<User>> findOptions({bool includeDeleted = false}) async {
    final users = <User>[];
    var page = 1;
    while (true) {
      final result = await _repository.find(Query(page: page, size: 50, includeDeleted: includeDeleted));
      users.addAll(result.items);
      if (!result.hasNext) {
        break;
      }
      page = result.page + 1;
    }
    return List.unmodifiable(users);
  }

  Future<bool> _change(Future<void> Function() action) async {
    if (_disposed || _saving) {
      return false;
    }
    _saving = true;
    _actionError = null;
    ++_request;
    _notify();
    try {
      await action();
      if (_disposed) {
        return false;
      }
      _selected.clear();
      await load();

      return true;
    } catch (error) {
      if (!_disposed) _actionError = errorText(error);
      if (!_disposed && _status == LoadStatus.loading) await load();
      return false;
    } finally {
      _saving = false;
      _notify();
    }
  }

  Future<bool> create(User item) => _change(() async {
    await _repository.create(item);
  });

  Future<bool> update(User item) => _change(() async {
    await _repository.update(item);
  });

  Future<bool> softDelete(int id) => _change(() => _repository.softDelete(id));

  Future<bool> hardDelete(int id) => _change(() => _repository.hardDelete(id));

  Future<bool> restore(int id) => _change(() => _repository.restore(id));

  Future<bool> deleteSelected() async {
    if (_selected.isEmpty) {
      return false;
    }
    final ids = _selected.toList();
    return _change(() async {
      await _repository.deleteMany(ids);
    });
  }

  @override
  void dispose() {
    _disposed = true;
    ++_request;
    super.dispose();
  }
}
