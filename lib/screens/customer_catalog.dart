import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models/product.dart';
import '../state/product_state.dart';
import '../state/status.dart';
import '../widgets/product_grid.dart';
import '../widgets/shop_page.dart';
import '../widgets/status_view.dart';

class CustomerCatalog extends StatefulWidget {
  const CustomerCatalog({super.key});

  @override
  State<CustomerCatalog> createState() => _CustomerCatalogState();
}

class _CustomerCatalogState extends State<CustomerCatalog> {
  final _search = TextEditingController();
  List<Product> _products = [];
  LoadStatus _status = LoadStatus.loading;
  ProductType? _type;
  String? _error;

  List<Product> get _visible {
    final search = _search.text.trim().toLowerCase();
    return _products.where((product) {
      if (_type != null && product.type != _type) return false;
      return search.isEmpty ||
          product.name.toLowerCase().contains(search) ||
          product.sku.toLowerCase().contains(search);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
    });
    try {
      final products = await context.read<ProductState>().findOptions();
      if (!mounted) return;
      setState(() {
        _products = products;
        _status = products.isEmpty ? LoadStatus.empty : LoadStatus.success;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        _error = errorText(exception);
        _status = LoadStatus.error;
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = _visible;
    return ShopPage(
      title: 'Каталог',
      child: Column(
        children: [
          TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: 'Поиск игр, подписок и артикулов',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Очистить поиск',
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Все товары'),
                  selected: _type == null,
                  onSelected: (_) => setState(() => _type = null),
                ),
                for (final type in ProductType.values)
                  ChoiceChip(
                    label: Text(productTypeName(type)),
                    selected: _type == type,
                    onSelected: (_) => setState(() => _type = type),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: switch (_status) {
              LoadStatus.idle || LoadStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              LoadStatus.error => StatusView(
                message: _error ?? 'Не удалось загрузить каталог',
                onRetry: _load,
              ),
              LoadStatus.empty => const StatusView(
                message: 'В каталоге пока нет товаров',
              ),
              LoadStatus.success when products.isEmpty => const StatusView(
                message: 'По заданным условиям товары не найдены',
              ),
              LoadStatus.success => ProductGrid(
                products: products,
                onOpen: (product) => context.go('/products/${product.id}'),
              ),
            },
          ),
        ],
      ),
    );
  }
}
