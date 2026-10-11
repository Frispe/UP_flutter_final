import 'dart:async';

import 'package:digital_shop/core/api_exceptions.dart';
import 'package:digital_shop/models/page_result.dart';
import 'package:digital_shop/models/product.dart';
import 'package:digital_shop/models/query.dart';
import 'package:digital_shop/repositories/product_repository.dart';
import 'package:digital_shop/screens/customer_catalog.dart';
import 'package:digital_shop/screens/login.dart';
import 'package:digital_shop/state/auth_state.dart';
import 'package:digital_shop/state/product_state.dart';
import 'package:digital_shop/state/storage_state.dart';
import 'package:digital_shop/widgets/shop_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  testWidgets('каталог показывает состояние загрузки', (tester) async {
    final waiting = Completer<PageResult<Product>>();
    final repository = _ProductRepository((_) => waiting.future);

    await tester.pumpWidget(
      _catalogApp(repository, _TestAuthState('customer', preferences)),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('каталог показывает сообщение при пустом результате', (
    tester,
  ) async {
    final repository = _ProductRepository(
      (_) async => PageResult<Product>.empty(),
    );

    await tester.pumpWidget(
      _catalogApp(repository, _TestAuthState('customer', preferences)),
    );
    await tester.pumpAndSettle();

    expect(find.text('В каталоге пока нет товаров'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('ошибка каталога показывает кнопку повторной загрузки', (
    tester,
  ) async {
    var requests = 0;
    final repository = _ProductRepository((_) async {
      requests++;
      if (requests == 1) {
        throw const NetworkException();
      }
      return PageResult<Product>.empty();
    });

    await tester.pumpWidget(
      _catalogApp(repository, _TestAuthState('customer', preferences)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Сервер недоступен. Проверьте соединение.'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);

    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(requests, 2);
    expect(find.text('В каталоге пока нет товаров'), findsOneWidget);
  });

  testWidgets('форма входа не отправляется с пустыми полями', (tester) async {
    final auth = _TestAuthState('customer', preferences);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthState>.value(
        value: auth,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.text('Войти'));
    await tester.pump();

    expect(find.text('Введите логин'), findsOneWidget);
    expect(find.text('Введите пароль'), findsOneWidget);
    expect(auth.loginCalls, 0);
  });

  testWidgets('покупателю скрыты административные разделы', (tester) async {
    final auth = _TestAuthState('customer', preferences);
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const ShopPage(
            title: 'Главная',
            child: Center(child: Text('Содержимое страницы')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthState>.value(value: auth),
          ChangeNotifierProvider(create: (_) => StorageState(null)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Содержимое страницы'), findsOneWidget);
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.text('Аккаунты'), findsNothing);
    expect(find.text('Статистика'), findsNothing);
    expect(find.text('Пользователи'), findsNothing);
  });
}

Widget _catalogApp(ProductRepository repository, AuthState auth) {
  final router = GoRouter(
    initialLocation: '/catalog',
    routes: [
      GoRoute(
        path: '/catalog',
        builder: (context, state) => const CustomerCatalog(),
      ),
    ],
  );
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthState>.value(value: auth),
      ChangeNotifierProvider(create: (_) => StorageState(null)),
      ChangeNotifierProvider(create: (_) => ProductState(repository)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

class _TestAuthState extends AuthState {
  _TestAuthState(this.testRole, SharedPreferences preferences)
    : super(Dio(), preferences);

  final String testRole;
  int loginCalls = 0;

  @override
  String? get role => testRole;

  @override
  String? get name => 'Тестовый пользователь';

  @override
  bool get signedIn => true;

  @override
  Future<bool> login(String login, String password) async {
    loginCalls++;
    return true;
  }

  @override
  Future<void> logout() async {}
}

class _ProductRepository implements ProductRepository {
  _ProductRepository(this.findHandler);

  final Future<PageResult<Product>> Function(Query query) findHandler;

  @override
  Future<PageResult<Product>> find(Query query) => findHandler(query);

  @override
  String platformName(int id) => 'Платформа $id';

  @override
  Future<bool> skuExists(String sku, {int? exceptId}) async => false;

  @override
  Future<Product?> findById(int id) async => null;

  @override
  Future<Product> create(Product product) => throw UnimplementedError();

  @override
  Future<Product> update(Product product) => throw UnimplementedError();

  @override
  Future<void> softDelete(int id) => throw UnimplementedError();

  @override
  Future<void> hardDelete(int id) => throw UnimplementedError();

  @override
  Future<void> restore(int id) => throw UnimplementedError();

  @override
  Future<int> deleteMany(List<int> ids) => throw UnimplementedError();
}
