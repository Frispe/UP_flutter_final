import 'package:flutter/foundation.dart';

import 'status.dart';

class DetailState<T> extends ChangeNotifier {
  DetailState(this._find);

  final Future<T?> Function() _find;
  T? _item;
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  bool _disposed = false;
  int _request = 0;

  T? get item => _item;
  LoadStatus get status => _status;
  String? get error => _error;

  Future<void> load() async {
    if (_disposed) return;
    final request = ++_request;
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final item = await _find();
      if (_disposed || request != _request) return;
      _item = item;
      _status = item == null ? LoadStatus.empty : LoadStatus.success;
    } catch (error) {
      if (_disposed || request != _request) return;
      _error = errorText(error);
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_request;
    super.dispose();
  }
}
