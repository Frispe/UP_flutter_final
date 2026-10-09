import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/api_client.dart';
import 'repositories/api_repositories.dart';
import 'repositories/brand_repository.dart';
import 'repositories/cart_repository.dart';
import 'repositories/category_repository.dart';
import 'repositories/platform_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/user_repository.dart';
import 'state/auth_state.dart';
import 'state/brand_state.dart';
import 'state/cart_state.dart';
import 'state/category_state.dart';
import 'state/platform_state.dart';
import 'state/product_state.dart';
import 'state/order_state.dart';
import 'state/storage_state.dart';
import 'state/user_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();

  late AuthState auth;
  final dio = buildDio(
    tokenProvider: () => auth.accessToken,
    tokenRefresher: () => auth.refreshAccessToken(),
  );
  auth = AuthState(dio, prefs);

  runApp(
    MultiProvider(
      providers: [
        Provider<Dio>.value(value: dio),
        ChangeNotifierProvider<AuthState>.value(value: auth),
        ChangeNotifierProvider(create: (_) => StorageState(null)),
        Provider<CartRepository>(create: (_) => ApiCartRepository(dio)),
        ChangeNotifierProvider(
          create: (context) => CartState(context.read<CartRepository>()),
        ),
        Provider<UserRepository>(create: (_) => ApiUserRepository(dio)),
        ChangeNotifierProvider(
          create: (context) => UserState(context.read<UserRepository>()),
        ),
        Provider<PlatformRepository>(create: (_) => ApiPlatformRepository(dio)),
        ChangeNotifierProvider(
          create: (context) =>
              PlatformState(context.read<PlatformRepository>()),
        ),
        Provider<CategoryRepository>(create: (_) => ApiCategoryRepository(dio)),
        ChangeNotifierProvider(
          create: (context) =>
              CategoryState(context.read<CategoryRepository>()),
        ),
        Provider<BrandRepository>(create: (_) => ApiBrandRepository(dio)),
        Provider<ProductRepository>(create: (_) => ApiProductRepository(dio)),
        Provider<ApiOrderRepository>(create: (_) => ApiOrderRepository(dio)),
        ChangeNotifierProvider(
          create: (context) => OrderState(
            context.read<ApiOrderRepository>(),
            context.read<UserRepository>(),
          ),
        ),
        ChangeNotifierProvider<BrandState>(
          create: (context) => BrandState(context.read<BrandRepository>()),
        ),
        ChangeNotifierProvider<ProductState>(
          create: (context) {
            final brands = context.read<BrandState>();
            return ProductState(
              context.read<ProductRepository>(),
              onChanged: brands.load,
            );
          },
        ),
      ],
      child: const ShopApp(),
    ),
  );
}
