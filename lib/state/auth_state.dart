import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';

class AuthState extends ChangeNotifier {
  AuthState(this._dio);
  final Dio _dio;
  String? accessToken;
  String? refreshToken;
  String? username;
  String? name;
  String? role;
  String? error;
  bool loading = false;
  bool get signedIn => accessToken != null;

  Future<bool> login(String login, String password) async {
    if (loading) return false;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final response = await guard(
        () => _dio.post(
          '/auth/login',
          data: {'username': login.trim(), 'password': password},
        ),
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final user = Map<String, dynamic>.from(data['user'] as Map);
      accessToken = data['accessToken'] as String?;
      refreshToken = data['refreshToken'] as String?;
      username = user['username'] as String?;
      name = user['name'] as String?;
      role = user['role'] as String?;
      return accessToken != null;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final token = refreshToken;
    accessToken = null;
    refreshToken = null;
    username = null;
    name = null;
    role = null;
    error = null;
    notifyListeners();
    if (token == null) return;
    try {
      await guard(
        () => _dio.post('/auth/logout', data: {'refreshToken': token}),
      );
    } on ApiException {
      return;
    }
  }
}
