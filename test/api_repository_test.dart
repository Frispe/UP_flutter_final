import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digital_shop/core/api_client.dart';
import 'package:digital_shop/core/api_exceptions.dart';
import 'package:digital_shop/models/product.dart';
import 'package:digital_shop/models/query.dart';
import 'package:digital_shop/repositories/api_repositories.dart';

typedef RequestHandler = Future<ResponseBody> Function(RequestOptions options);

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final RequestHandler handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(int status, Object body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

Map<String, dynamic> productJson({int id = 1, String sku = 'TEST-1'}) => {
  'id': id,
  'name': 'Тестовый товар',
  'sku': sku,
  'description': 'Описание',
  'type': 'gameKey',
  'brandId': 1,
  'price': 1000,
  'platformId': 1,
  'categoryIds': [1],
  'region': 'Россия',
  'durationMonths': null,
  'deletedAt': null,
};

Product product({int id = 0, String sku = 'TEST-1'}) => Product(
  id: id,
  name: 'Тестовый товар',
  sku: sku,
  description: 'Описание',
  type: ProductType.gameKey,
  brandId: 1,
  price: 1000,
  platformId: 1,
  categoryIds: const [1],
  region: 'Россия',
);

Dio fakeDio(RequestHandler handler) {
  final dio = buildDio();
  dio.httpClientAdapter = FakeAdapter(handler);
  return dio;
}

void main() {
  test('репозиторий разбирает страницу товаров', () async {
    final dio = fakeDio((options) async {
      if (options.path.endsWith('/platforms')) {
        return jsonResponse(200, {
          'items': [
            {'id': 1, 'name': 'Steam'},
          ],
          'page': 1,
          'size': 100,
          'total': 1,
          'totalPages': 1,
        });
      }
      return jsonResponse(200, {
        'items': [productJson()],
        'page': 2,
        'size': 10,
        'total': 15,
        'totalPages': 2,
      });
    });
    final repository = ApiProductRepository(dio);

    final result = await repository.find(const Query(page: 2));

    expect(result.page, 2);
    expect(result.total, 15);
    expect(result.items.single.sku, 'TEST-1');
    expect(repository.platformName(1), 'Steam');
  });

  test('репозиторий создаёт товар через POST', () async {
    late RequestOptions sent;
    final dio = fakeDio((options) async {
      sent = options;
      return jsonResponse(201, productJson(id: 7));
    });
    final repository = ApiProductRepository(dio);

    final created = await repository.create(product());

    expect(sent.method, 'POST');
    expect(sent.path.endsWith('/products'), isTrue);
    expect(created.id, 7);
  });

  test('ошибка 422 преобразуется в ошибки полей', () async {
    final dio = fakeDio((options) async {
      return jsonResponse(422, {
        'message': 'Ошибка валидации',
        'errors': {'sku': 'Товар с таким артикулом уже существует'},
      });
    });
    final repository = ApiProductRepository(dio);

    expect(
      () => repository.create(product(sku: 'CS2-RU')),
      throwsA(
        isA<ValidationException>().having(
          (error) => error.errors['sku'],
          'sku',
          'Товар с таким артикулом уже существует',
        ),
      ),
    );
  });

  test('недоступный сервер преобразуется в NetworkException', () async {
    var productAttempts = 0;
    final dio = fakeDio((options) async {
      if (options.path.endsWith('/platforms')) {
        return jsonResponse(200, {
          'items': [
            {'id': 1, 'name': 'Steam'},
          ],
          'page': 1,
          'size': 100,
          'total': 1,
          'totalPages': 1,
        });
      }
      productAttempts++;
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'Сервер недоступен',
      );
    });
    final repository = ApiProductRepository(dio);

    await expectLater(
      repository.find(const Query()),
      throwsA(isA<NetworkException>()),
    );
    expect(productAttempts, 3);
  });

  test('ошибка 409 преобразуется в ConflictException', () async {
    final dio = fakeDio((options) async {
      return jsonResponse(409, {'message': 'Нельзя оформить пустую корзину'});
    });
    final repository = ApiOrderRepository(dio);

    expect(
      () => repository.checkout(1),
      throwsA(
        isA<ConflictException>().having(
          (error) => error.message,
          'message',
          'Нельзя оформить пустую корзину',
        ),
      ),
    );
  });

  test('поиск отсутствующего товара возвращает null', () async {
    final dio = fakeDio((options) async {
      return jsonResponse(404, {'message': 'Запись не найдена'});
    });
    final repository = ApiProductRepository(dio);

    final result = await repository.findById(999);

    expect(result, isNull);
  });
}
