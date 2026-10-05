import 'form_guard.dart';
import 'screens/user_form.dart';

import 'screens/user_detail.dart';
import 'screens/order_detail.dart';
import 'screens/order_list.dart';
import 'state/cart_state.dart';
import 'repositories/cart_repository.dart';
import 'screens/product_form.dart';
import 'screens/directory_form.dart';
import 'screens/directory_detail.dart';
import 'widgets/catalog_route.dart';

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
    GoRoute(path: '/orders', builder: (context, state) => const OrderList()),
    GoRoute(
      path: '/orders/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null || id <= 0) {
          return NotFound(location: state.uri.toString());
        }
        return OrderDetail(key: ValueKey('order-$id'), id: id);
      },
    ),
    GoRoute(
      path: '/users',
      builder: (context, state) => CatalogRoute(uri: state.uri, kind: 'users'),
    ),
    GoRoute(
      path: '/users/new',
      onExit: (context, state) => FormGuard.allow(state.uri.path),
      builder: (context, state) => const UserForm(key: ValueKey('user-new')),
    ),
    GoRoute(
      path: '/users/:id/edit',
      onExit: (context, state) => FormGuard.allow(state.uri.path),
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null || id <= 0) {
          return NotFound(location: state.uri.toString());
        }
        return UserForm(key: ValueKey('user-edit-$id'), id: id);
      },
    ),
    GoRoute(
      path: '/users/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null || id <= 0) {
          return NotFound(location: state.uri.toString());
        }
        return ChangeNotifierProvider<CartState>(
          key: ValueKey('user-cart-$id'),
          create: (context) =>
              CartState(context.read<CartRepository>())..load(id),
          child: UserDetail(key: ValueKey('user-$id'), id: id),
        );
      },
    ),
    GoRoute(
      path: '/products/new',
      onExit: (context, state) => FormGuard.allow(state.uri.path),
      builder: (context, state) =>
          const ProductForm(key: ValueKey('product-new')),
    ),
    GoRoute(
      path: '/products/:id/edit',
      onExit: (context, state) => FormGuard.allow(state.uri.path),
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null || id <= 0) {
          return NotFound(location: state.uri.toString());
        }
        return ProductForm(key: ValueKey('product-edit-$id'), id: id);
      },
    ),
    for (final kind in Directory.values) ...[
      GoRoute(
        path: '/${kind.name}/new',
        onExit: (context, state) => FormGuard.allow(state.uri.path),
        builder: (context, state) =>
            DirectoryForm(key: ValueKey('${kind.name}-new'), kind: kind),
      ),
      GoRoute(
        path: '/${kind.name}/:id/edit',
        onExit: (context, state) => FormGuard.allow(state.uri.path),
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null || id <= 0) {
            return NotFound(location: state.uri.toString());
          }
          return DirectoryForm(
            key: ValueKey('${kind.name}-$id'),
            kind: kind,
            id: id,
          );
        },
      ),
      if (kind != Directory.brands)
        GoRoute(
          path: '/${kind.name}',
          builder: (context, state) => CatalogRoute(
            key: ValueKey(kind),
            uri: state.uri,
            kind: kind.name,
          ),
        ),
    ],

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
                return DetailState<Product>(() => products.findById(id))
                  ..load();
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
    for (final kind in ['categories', 'platforms'])
      GoRoute(
        path: '/$kind/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null || id <= 0) {
            return NotFound(location: state.uri.toString());
          }
          return DirectoryDetail(
            key: ValueKey('$kind-$id'),
            kind: kind,
            id: id,
          );
        },
      ),
  ],
  errorBuilder: (context, state) => NotFound(location: state.uri.toString()),
);
