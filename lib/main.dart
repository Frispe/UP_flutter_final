import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'package:provider/provider.dart';

import 'repositories/brand_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/store.dart';
import 'state/brand_state.dart';
import 'state/product_state.dart';


void main() {
  usePathUrlStrategy();
  runApp(
    MultiProvider(
      providers: [
        Provider<Store>(create: (_) => Store()),
        Provider<BrandRepository>(
          create: (context) => MemoryBrandRepository(context.read<Store>()),
        ),
        Provider<ProductRepository>(
          create: (context) => MemoryProductRepository(context.read<Store>()),
        ),
        ChangeNotifierProvider<BrandState>(
          lazy: false,
          create: (context) => BrandState(context.read<BrandRepository>())..load(),
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
