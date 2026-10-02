import 'package:flutter/foundation.dart';
import '../repositories/cart_repository.dart';
import 'status.dart';

class CartState extends ChangeNotifier {
  CartState(this._repository);
  final CartRepository _repository;
  CartData? data;
  LoadStatus status = LoadStatus.idle;
  String? error;
  String? actionError;
  bool saving = false;
  bool _disposed = false;
  int _request = 0;
  int? _userId;

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> load(int userId) async {
    if (_disposed) {
      return;
    }
    _userId = userId;
    final request = ++_request;
    data = null;
    error = null;
    status = LoadStatus.loading;
    _notify();
    try {
      final result = await _repository.find(userId);
      if (_disposed || request != _request) {
        return;
      }
      data = result;
      status = result.items.isEmpty ? LoadStatus.empty : LoadStatus.success;
    } catch (e) {
      if (_disposed || request != _request) {
        return;
      }
      error = errorText(e);
      status = LoadStatus.error;
    }
    _notify();
  }

  Future<bool> _change(Future<void> Function(int) action) async {
    final userId = _userId;
    if (_disposed || saving || userId == null) {
      return false;
    }
    saving = true;
    actionError = null;
    _notify();
    try {
      await action(userId);
      if (!_disposed && _userId == userId) {
        await load(userId);
      }
      return true;
    } catch (e) {
      if (!_disposed && _userId == userId) {
        actionError = errorText(e);
      }
      return false;
    } finally {
      saving = false;
      _notify();
    }
  }

  Future<bool> add(int productId, {int quantity = 1}) => _change((id) => _repository.add(id, productId, quantity: quantity));
  Future<bool> setQuantity(int itemId, int quantity) => _change((id) => _repository.setQuantity(id, itemId, quantity));
  Future<bool> remove(int itemId) => _change((id) => _repository.remove(id, itemId));
  Future<bool> clear() => _change(_repository.clear);

  @override
  void dispose() {
    _disposed = true;
    ++_request;
    super.dispose();
  }
}
