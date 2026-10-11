import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ServerState extends ChangeNotifier {
  ServerState(this._dio);

  final Dio _dio;
  Timer? _timer;
  bool _checking = false;
  bool _online = true;
  int _recovery = 0;

  bool get online => _online;
  bool get checking => _checking;
  int get recovery => _recovery;

  void markUnavailable() {
    if (_online) {
      _online = false;
      notifyListeners();
    }
    _scheduleCheck();
  }

  void markAvailable() {
    _timer?.cancel();
    _timer = null;
    if (!_online) {
      _online = true;
      _recovery++;
      notifyListeners();
    }
  }

  void _scheduleCheck() {
    if (_timer?.isActive ?? false) return;
    _timer = Timer(const Duration(seconds: 3), checkNow);
  }

  Future<void> checkNow() async {
    if (_checking) return;
    _timer?.cancel();
    _timer = null;
    _checking = true;
    notifyListeners();
    try {
      await _dio.get<void>(
        '/__health',
        options: Options(extra: {'skipRetry': true}),
      );
      markAvailable();
    } on DioException {
      _scheduleCheck();
    } finally {
      _checking = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
