import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/shop_page.dart';

class NotFound extends StatelessWidget {
  const NotFound({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return ShopPage(
      title: '404 — Страница не найдена',
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Адрес не существует: $location', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/products'),
                child: const Text('В каталог'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
