import 'repositories/cart_repository.dart';
import 'state/cart_state.dart';
import 'repositories/user_repository.dart';
import 'state/user_state.dart';
import 'repositories/platform_repository.dart';
import 'state/platform_state.dart';
import 'repositories/category_repository.dart';
import 'state/category_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';

import 'package:provider/provider.dart';

import 'repositories/brand_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/store.dart';
import 'state/brand_state.dart';
import 'state/product_state.dart';
import 'state/storage_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final store = await Store.open();
  runApp(
    MultiProvider(
      providers: [
        Provider<Store>.value(value: store),
        Provider<CartRepository>(create: (context) => CartRepository(context.read<Store>())),
        ChangeNotifierProvider(create: (context) => CartState(context.read<CartRepository>())),
        Provider<UserRepository>(create: (context) => UserRepository(context.read<Store>())),
        ChangeNotifierProvider(create: (context) => UserState(context.read<UserRepository>())),
        Provider<PlatformRepository>(create: (context) => PlatformRepository(context.read<Store>())),
        ChangeNotifierProvider(create: (context) => PlatformState(context.read<PlatformRepository>())),
        Provider<CategoryRepository>(create: (context) => CategoryRepository(context.read<Store>())),
        ChangeNotifierProvider(create: (context) => CategoryState(context.read<CategoryRepository>())),
        ChangeNotifierProvider(create: (_) => StorageState(store.message)),
        Provider<BrandRepository>(
          create: (context) => MemoryBrandRepository(context.read<Store>()),
        ),
        Provider<ProductRepository>(
          create: (context) => MemoryProductRepository(context.read<Store>()),
        ),
        ChangeNotifierProvider<BrandState>(
          lazy: false,
          create: (context) =>
              BrandState(context.read<BrandRepository>())..load(),
        ),
        ChangeNotifierProvider<ProductState>(
          lazy: false,
          create: (context) {
            final brands = context.read<BrandState>();
            return ProductState(
              context.read<ProductRepository>(),
              onChanged: brands.load,
            )..load();
          },
        ),
      ],
      child: const ShopApp(),
    ),
  );
}
