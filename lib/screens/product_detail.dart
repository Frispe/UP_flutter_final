import '../state/product_state.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models/product.dart';
import '../state/detail_state.dart';
import '../state/status.dart';
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
              LoadStatus.success => SingleChildScrollView(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product!.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          formatPrice(product.price),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(product.description),
                        const SizedBox(height: 16),
                        Text('Артикул: ${product.sku}'),
                        Text('Тип: ${productTypeName(product.type)}'),
                        Text(
                          'Платформа: ${context.watch<ProductState>().platformName(product.platformId)}',
                        ),
                        Text('Регион: ${product.region}'),
                        if (product.durationMonths != null)
                          Text('Срок подписки: ${product.durationMonths} мес.'),
                        Text(
                          'Статус: ${product.isDeleted ? 'Удалён' : 'Активен'}',
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () =>
                              context.go('/brands/${product.brandId}'),
                          child: Text('Открыть бренд № ${product.brandId}'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            },
          ),
        ],
      ),
    );
  }
}
