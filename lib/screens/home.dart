import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/product_state.dart';
import '../state/status.dart';
import '../widgets/product_grid.dart';
import '../widgets/shop_page.dart';
import '../widgets/status_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> _products = [];
  LoadStatus _status = LoadStatus.loading;
  String? _error;

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
        _products = products.take(8).toList();
        _status = _products.isEmpty ? LoadStatus.empty : LoadStatus.success;
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
  Widget build(BuildContext context) {
    return ShopPage(
      title: 'Главная',
      child: switch (_status) {
        LoadStatus.idle || LoadStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        LoadStatus.error => StatusView(
          message: _error ?? 'Не удалось загрузить главную страницу',
          onRetry: _load,
        ),
        LoadStatus.empty => const StatusView(message: 'Товаров пока нет'),
        LoadStatus.success => ListView(
          children: [
            _Banner(onCatalog: () => context.go('/catalog')),
            const SizedBox(height: 28),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const [
                _Feature(
                  icon: Icons.bolt,
                  title: 'Моментальная выдача',
                  text: 'Цифровой товар доступен сразу после покупки',
                ),
                _Feature(
                  icon: Icons.verified_user_outlined,
                  title: 'Безопасная покупка',
                  text: 'Понятный заказ и сохранение истории покупок',
                ),
                _Feature(
                  icon: Icons.public,
                  title: 'Разные регионы',
                  text: 'Выбирайте подходящий регион активации',
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Популярные товары',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/catalog'),
                  child: const Text('Смотреть все'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ProductGrid(
              products: _products,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onOpen: (product) => context.go('/products/${product.id}'),
            ),
          ],
        ),
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.onCatalog});

  final VoidCallback onCatalog;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF173A73), Color(0xFF4D2A9B), Color(0xFF171925)],
        ),
        image: const DecorationImage(
          image: AssetImage('assets/images/banner.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Color(0x55000000),
            BlendMode.darken,
          ),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Цифровые товары в одном месте',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Игровые ключи и подписки на нейросети для разных платформ и регионов.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFFD8D9E4),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onCatalog,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Перейти в каталог'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: width < 600 ? double.infinity : 300,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(text, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
