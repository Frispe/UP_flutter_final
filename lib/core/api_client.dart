import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'config.dart';

typedef TokenProvider = String? Function();
typedef TokenRefresher = Future<String?> Function();

Dio buildDio({TokenProvider? tokenProvider, TokenRefresher? tokenRefresher}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (options.method == 'GET' && apiDelay > 0) {
          options.queryParameters.putIfAbsent('__delay', () => apiDelay);
        }
        if (options.method == 'GET' && apiFail > 0) {
          options.queryParameters.putIfAbsent('__fail', () => apiFail);
        }
        if (kDebugMode) {
          debugPrint('[API] ${options.method} ${options.uri}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint(
            '[API] ${response.requestOptions.method} '
            '${response.requestOptions.uri} -> ${response.statusCode}',
          );
        }
        final status = response.statusCode ?? 0;
        if (status >= 400) {
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
          return;
        }
        handler.next(response);
      },
      onError: (error, handler) async {
        if (kDebugMode) {
          debugPrint(
            '[API] ${error.requestOptions.method} '
            '${error.requestOptions.uri} -> '
            '${error.response?.statusCode ?? error.type.name}',
          );
        }
        final options = error.requestOptions;
        final status = error.response?.statusCode;
        final authRequest = options.path.startsWith('/auth/');
        final authRetried = options.extra['authRetried'] == true;
        if (status == 401 && !authRequest && !authRetried && tokenRefresher != null) {
          options.extra['authRetried'] = true;
          final token = await tokenRefresher();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            try {
              final response = await dio.fetch<dynamic>(options);
              handler.resolve(response);
              return;
            } on DioException catch (retryError) {
              handler.next(retryError);
              return;
            }
          }
        }
        final retryable =
            options.method == 'GET' &&
            error.type != DioExceptionType.cancel &&
            (status == null || status >= 500);
        final retries = options.extra['retries'] as int? ?? 0;
        if (!retryable || retries >= 2) {
          handler.next(error);
          return;
        }
        options.extra['retries'] = retries + 1;
        final delay = Duration(milliseconds: 400 * (retries + 1));
        if (kDebugMode) {
          debugPrint(
            '[API] повтор ${retries + 2}/3 через ${delay.inMilliseconds} мс',
          );
        }
        await Future<void>.delayed(delay);
        try {
          final response = await dio.fetch<dynamic>(options);
          handler.resolve(response);
        } on DioException catch (retryError) {
          handler.next(retryError);
        }
      },
    ),
  );

  return dio;
}
