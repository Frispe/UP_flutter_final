import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../state/storage_state.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageState>();
    final auth = context.watch<AuthState>();
    final path = GoRouterState.of(context).uri.path;
    final links = auth.role == 'customer'
        ? {'/products': 'Товары', '/cart': 'Корзина', '/orders': 'Мои заказы'}
        : {
            '/products': 'Товары',
            '/brands': 'Бренды',
            '/categories': 'Категории',
            '/platforms': 'Платформы',
            '/users': 'Пользователи',
            '/orders': 'Заказы',
            if (auth.role == 'admin') '/accounts': 'Аккаунты',
            if (auth.role == 'admin') '/statistics': 'Статистика',
          };
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Digital Shop'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: Text('${auth.name ?? ''} · ${_roleName(auth.role)}')),
          ),
          TextButton(onPressed: auth.logout, child: const Text('Выйти')),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (storage.message != null)
                    MaterialBanner(
                      content: Text(storage.message!),
                      actions: [TextButton(onPressed: storage.dismiss, child: const Text('Понятно'))],
                    ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      for (final entry in links.entries)
                        TextButton(
                          onPressed: () => context.go(entry.key),
                          style: TextButton.styleFrom(
                            backgroundColor: path.startsWith(entry.key)
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                          ),
                          child: Text(entry.value),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _roleName(String? role) => switch (role) {
    'admin' => 'Администратор',
    'manager' => 'Менеджер',
    _ => 'Покупатель',
  };
}
