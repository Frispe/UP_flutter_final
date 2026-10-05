import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Сервер недоступен. Проверьте соединение.',
  ]);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Требуется вход в систему.']);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([
    super.message = 'Недостаточно прав для этого действия.',
  ]);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Запись не найдена.']);
}

class ConflictException extends ApiException {
  const ConflictException(super.message);
}

class ValidationException extends ApiException {
  const ValidationException(super.message, this.errors);

  final Map<String, String> errors;
}

class ServerException extends ApiException {
  const ServerException([
    super.message = 'Ошибка на сервере. Попробуйте позже.',
  ]);
}

String? _readMessage(dynamic body) {
  if (body is Map && body['message'] is String) {
    return body['message'] as String;
  }
  return null;
}

Map<String, String> _readErrors(dynamic body) {
  if (body is! Map || body['errors'] is! Map) {
    return const {};
  }
  return (body['errors'] as Map).map(
    (key, value) => MapEntry('$key', '$value'),
  );
}

ApiException mapHttpError(int status, dynamic body) {
  final message = _readMessage(body);
  return switch (status) {
    401 => UnauthorizedException(message ?? 'Требуется вход в систему.'),
    403 => ForbiddenException(
      message ?? 'Недостаточно прав для этого действия.',
    ),
    404 => NotFoundException(message ?? 'Запись не найдена.'),
    409 => ConflictException(message ?? 'Операция невозможна.'),
    422 => ValidationException(
      message ?? 'Ошибка валидации.',
      _readErrors(body),
    ),
    >= 500 => ServerException(
      message ?? 'Ошибка на сервере. Попробуйте позже.',
    ),
    _ => ServerException(message ?? 'Неизвестная ошибка, код $status.'),
  };
}

ApiException mapDioError(DioException error) {
  final existing = error.error;
  if (existing is ApiException) {
    return existing;
  }

  final response = error.response;
  if (response != null) {
    return mapHttpError(response.statusCode ?? 500, response.data);
  }

  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => const NetworkException(
      'Сервер не ответил вовремя.',
    ),
    DioExceptionType.connectionError => const NetworkException(
      'Не удалось соединиться с сервером. Проверьте, запущен ли сервер, '
      'а также сообщения CORS в консоли браузера.',
    ),
    DioExceptionType.cancel => const NetworkException('Запрос отменён.'),
    DioExceptionType.badCertificate => const NetworkException(
      'Не удалось проверить сертификат сервера.',
    ),
    _ => const ServerException(),
  };
}

Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (error) {
    throw mapDioError(error);
  }
}
