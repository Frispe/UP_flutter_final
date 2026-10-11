import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models/product.dart';
import '../state/auth_state.dart';
import '../state/cart_state.dart';
import '../state/detail_state.dart';
import '../state/product_state.dart';
import '../state/status.dart';
import '../widgets/product_image.dart';
import '../widgets/shop_page.dart';
import '../widgets/status_view.dart';

class ProductDetail extends StatelessWidget {
  const ProductDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DetailState<Product>>();
    final product = state.item;
    return ShopPage(
      title: 'Карточка товара',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.go(
                Uri(
                  path: '/products',
                  queryParameters: GoRouterState.of(context)
                      .uri
                      .queryParameters,
                ).toString(),
              ),
              child: const Text('К списку товаров'),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: switch (state.status) {
              LoadStatus.idle || LoadStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              LoadStatus.error => StatusView(
                message: state.error ?? 'Не удалось загрузить товар',
                onRetry: state.load,
              ),
              LoadStatus.empty => const StatusView(message: 'Товар не найден'),
              LoadStatus.success => _productCard(context, product!),
            },
          ),
        ],
      ),
    );
  }

  Widget _productCard(BuildContext context, Product product) {
    final customer = context.watch<AuthState>().role == 'customer';
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 800;
              final image = ProductImage(
                imageUrl: product.imageUrl,
                width: double.infinity,
                height: wide ? 420 : 220,
              );
              final details = _details(context, product, customer);
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [image, const SizedBox(height: 20), details],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: image),
                  const SizedBox(width: 28),
                  Expanded(flex: 4, child: details),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _details(BuildContext context, Product product, bool customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          formatPrice(product.price),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        Text(product.description),
        const SizedBox(height: 18),
        Text('Артикул: ${product.sku}'),
        Text('Тип: ${productTypeName(product.type)}'),
        Text(
          'Платформа: ${context.watch<ProductState>().platformName(product.platformId)}',
        ),
        Text('Регион: ${product.region}'),
        if (product.durationMonths != null)
          Text('Срок подписки: ${product.durationMonths} мес.'),
        Text('Статус: ${product.isDeleted ? 'Удалён' : 'Активен'}'),
        const SizedBox(height: 22),
        if (customer)
          FilledButton.icon(
            onPressed: product.isDeleted
                ? null
                : () => _addToCart(context, product.id),
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Добавить в корзину'),
          )
        else
          TextButton(
            onPressed: () => context.go('/brands/${product.brandId}'),
            child: Text('Открыть бренд № ${product.brandId}'),
          ),
      ],
    );
  }

  Future<void> _addToCart(BuildContext context, int productId) async {
    final userId = context.read<AuthState>().customerId;
    if (userId == null) return;
    final cart = context.read<CartState>();
    await cart.load(userId);
    final success = await cart.add(productId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Товар добавлен в корзину'
              : cart.actionError ?? 'Не удалось добавить товар',
        ),
        action: success
            ? SnackBarAction(
                label: 'Корзина',
                onPressed: () => context.go('/cart'),
              )
            : null,
      ),
    );
  }
}
