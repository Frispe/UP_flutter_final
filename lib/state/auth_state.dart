import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_exceptions.dart';
import '../models/auth.dart';

class AuthState extends ChangeNotifier {
  AuthState(this._dio, this._prefs) {
    _restore();
  }

  static const _sessionKey = 'auth_session';

  final Dio _dio;
  final SharedPreferences _prefs;
  AuthSession? _session;
  Future<String?>? _refreshing;
  String? error;
  Map<String, String> fieldErrors = const {};
  bool loading = false;

  AuthUser? get user => _session?.user;
  String? get accessToken => _session?.accessToken;
  String? get refreshToken => _session?.refreshToken;
  String? get username => user?.username;
  String? get name => user?.name;
  String? get role => user?.role;
  int? get customerId => user?.customerId;
  DateTime? get sessionStartedAt => _session?.startedAt;
  bool get signedIn => _session != null;
  bool get accessExpired => _session?.accessExpired ?? true;

  void _restore() {
    final saved = _prefs.getString(_sessionKey);
    if (saved == null) return;
    try {
      final json = Map<String, dynamic>.from(jsonDecode(saved) as Map);
      _session = AuthSession.fromJson(json);
    } catch (_) {
      _prefs.remove(_sessionKey);
    }
  }

  Future<void> _save() async {
    final session = _session;
    if (session == null) {
      await _prefs.remove(_sessionKey);
      return;
    }
    await _prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<bool> login(String login, String password) async {
    if (loading) return false;
    loading = true;
    error = null;
    fieldErrors = const {};
    notifyListeners();
    try {
      final response = await guard(
        () => _dio.post(
          '/auth/login',
          data: {'username': login.trim(), 'password': password},
        ),
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      _session = AuthSession.fromResponse(data);
      await _save();
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } on FormatException {
      error = 'Сервер вернул неверные данные авторизации';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String username,
    required String password,
    required String name,
    required String email,
    required String nickname,
  }) async {
    if (loading) return false;
    loading = true;
    error = null;
    fieldErrors = const {};
    notifyListeners();
    try {
      final response = await guard(
        () => _dio.post(
          '/auth/register',
          data: {
            'username': username.trim(),
            'password': password,
            'name': name.trim(),
            'email': email.trim(),
            'nickname': nickname.trim(),
          },
        ),
      );
      _session = AuthSession.fromResponse(
        Map<String, dynamic>.from(response.data as Map),
      );
      await _save();
      return true;
    } on ValidationException catch (exception) {
      error = exception.message;
      fieldErrors = exception.errors;
      return false;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> refreshAccessToken() {
    final current = _refreshing;
    if (current != null) return current;
    final operation = _refresh();
    _refreshing = operation;
    operation.whenComplete(() => _refreshing = null);
    return operation;
  }

  Future<String?> _refresh() async {
    final token = refreshToken;
    if (token == null) return null;
    try {
      final response = await guard(
        () => _dio.post('/auth/refresh', data: {'refreshToken': token}),
      );
      _session = AuthSession.fromResponse(
        Map<String, dynamic>.from(response.data as Map),
        startedAt: _session?.startedAt,
      );
      await _save();
      notifyListeners();
      return accessToken;
    } on ApiException {
      _session = null;
      await _save();
      notifyListeners();
      return null;
    }
  }

  Future<void> expireSession(String message) async {
    await logout();
    error = message;
    notifyListeners();
  }

  Future<void> logout() async {
    final token = refreshToken;
    _session = null;
    error = null;
    fieldErrors = const {};
    await _save();
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
