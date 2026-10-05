import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../models/order_item.dart';
import '../models/page_result.dart';
import '../models/query.dart';
import '../repositories/api_repositories.dart';
import '../repositories/user_repository.dart';
import 'status.dart';

class OrderState extends ChangeNotifier {
  OrderState(this._orders, this._users);

  final ApiOrderRepository _orders;
  final UserRepository _users;

  PageResult<Order> result = PageResult.empty();
  Map<int, String> userNames = {};
  LoadStatus status = LoadStatus.idle;
  String? error;
  String? actionError;
  bool saving = false;
  bool _disposed = false;
  int _request = 0;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load({int page = 1, int size = 10}) async {
    final request = ++_request;
    status = LoadStatus.loading;
    error = null;
    _notify();
    try {
      final orders = await _orders.find(page: page, size: size);
      final names = <int, String>{};
      var usersPage = 1;
      while (true) {
        final users = await _users.find(
          Query(page: usersPage, size: 50, includeDeleted: true),
        );
        for (final user in users.items) {
          names[user.id] = user.name;
        }
        if (!users.hasNext) break;
        usersPage++;
      }
      if (_disposed || request != _request) return;
      result = orders;
      userNames = names;
      status = orders.items.isEmpty ? LoadStatus.empty : LoadStatus.success;
    } catch (exception) {
      if (_disposed || request != _request) return;
      error = errorText(exception);
      status = LoadStatus.error;
    }
    _notify();
  }

  Future<Order?> findById(int id) => _orders.findById(id);

  Future<List<OrderItem>> findItems(int orderId) => _orders.findItems(orderId);

  Future<Order?> checkout(int cartId) async {
    if (saving) return null;
    saving = true;
    actionError = null;
    _notify();
    try {
      final order = await _orders.checkout(cartId);
      await load();
      return order;
    } catch (exception) {
      actionError = errorText(exception);
      return null;
    } finally {
      saving = false;
      _notify();
    }
  }

  Future<bool> updateStatus(Order order, String value) async {
    if (saving) return false;
    saving = true;
    actionError = null;
    _notify();
    try {
      await _orders.updateStatus(order, value);
      await load(page: result.page, size: result.size);
      return true;
    } catch (exception) {
      actionError = errorText(exception);
      return false;
    } finally {
      saving = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_request;
    super.dispose();
  }
}
