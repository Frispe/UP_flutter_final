import 'package:provider/provider.dart';

import '../state/storage_state.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageState>();
    final path = GoRouterState.of(context).uri.path;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Digital Shop'),
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
                      actions: [
                        TextButton(
                          onPressed: storage.dismiss,
                          child: const Text('Понятно'),
                        ),
                      ],
                    ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => context.go('/products'),
                        style: TextButton.styleFrom(
                          backgroundColor: path.startsWith('/products')
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                        ),
                        child: const Text('Товары'),
                      ),
                      TextButton(
                        onPressed: () => context.go('/brands'),
                        style: TextButton.styleFrom(
                          backgroundColor: path.startsWith('/brands')
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                        ),
                        child: const Text('Бренды'),
                      ),
                      for (final entry in {
                        '/categories': 'Категории',
                        '/platforms': 'Платформы',
                        '/users': 'Пользователи',
                      }.entries)
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
}
