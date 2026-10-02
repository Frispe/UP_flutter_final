import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/brand.dart';
import '../state/brand_state.dart';
import '../state/detail_state.dart';
import '../state/status.dart';
import '../widgets/shop_page.dart';
import '../widgets/status_view.dart';

class BrandDetail extends StatelessWidget {
  const BrandDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DetailState<Brand>>();
    final brands = context.watch<BrandState>();
    final brand = state.item;
    return ShopPage(
      title: 'Карточка бренда',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.go(
                Uri(
                  path: '/brands',
                  queryParameters: GoRouterState.of(context)
                      .uri
                      .queryParameters,
                ).toString(),
              ),
              child: const Text('К списку брендов'),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: switch (state.status) {
              LoadStatus.idle || LoadStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              LoadStatus.error => StatusView(
                message: state.error ?? 'Не удалось загрузить бренд',
                onRetry: state.load,
              ),
              LoadStatus.empty => const StatusView(message: 'Бренд не найден'),
              LoadStatus.success => SingleChildScrollView(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          brand!.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        Text('ID: ${brand.id}'),
                        Text(
                          'Статус: ${brand.isDeleted ? 'Удалён' : 'Активен'}',
                        ),
                        const SizedBox(height: 12),
                        if (brands.status == LoadStatus.success ||
                            brands.status == LoadStatus.empty)
                          Text(
                            'Активных товаров: ${brands.productCount(brand.id)}',
                          )
                        else if (brands.status == LoadStatus.error)
                          TextButton(
                            onPressed: brands.load,
                            child: const Text(
                              'Повторить загрузку количества товаров',
                            ),
                          )
                        else
                          const Text('Загрузка количества товаров…'),
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
