import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'models/brand.dart';
import 'models/product.dart';
import 'screens/brand_detail.dart';
import 'screens/not_found.dart';
import 'screens/product_detail.dart';
import 'state/brand_state.dart';
import 'state/detail_state.dart';
import 'state/product_state.dart';
import 'widgets/list_route.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/products'),
    GoRoute(
      path: '/products',
      builder: (context, state) => ListRoute(uri: state.uri, brands: false),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null || id <= 0) {
              return NotFound(location: state.uri.toString());
            }
            return ChangeNotifierProvider<DetailState<Product>>(
              key: ValueKey('product-$id'),
              create: (context) {
                final products = context.read<ProductState>();
                return DetailState<Product>(() => products.findById(id))..load();
              },
              child: const ProductDetail(),
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/brands',
      builder: (context, state) => ListRoute(uri: state.uri, brands: true),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null || id <= 0) {
              return NotFound(location: state.uri.toString());
            }
            return ChangeNotifierProvider<DetailState<Brand>>(
              key: ValueKey('brand-$id'),
              create: (context) {
                final brands = context.read<BrandState>();
                return DetailState<Brand>(() => brands.findById(id))..load();
              },
              child: const BrandDetail(),
            );
          },
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => NotFound(location: state.uri.toString()),
);
