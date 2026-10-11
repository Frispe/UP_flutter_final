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
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final compact = width < 600;
    final expanded = width >= 1200;
    final shortHeight = size.height < 500;
    final customer = auth.role == 'customer';
    final wideCustomerNavigation = width >= 1000;
    final path = GoRouterState.of(context).uri.path;
    final links = _links(auth.role);
    var selected = links.indexWhere(
      (link) => path == link.path || path.startsWith('${link.path}/'),
    );
    if (customer && path.startsWith('/products/')) {
      selected = links.indexWhere((link) => link.path == '/catalog');
    }

    Widget content() {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 20,
              vertical: shortHeight ? 8 : (compact ? 12 : 20),
            ),
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
                Expanded(
                  child: Semantics(container: true, label: title, child: child),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('Digital Shop'),
        actions: compact
            ? [
                IconButton(
                  onPressed: auth.logout,
                  tooltip:
                      '${auth.name ?? ''} · ${_roleName(auth.role)}. Выйти',
                  icon: const Icon(Icons.logout),
                ),
                const SizedBox(width: 4),
              ]
            : customer
            ? [
                for (var index = 0; index < links.length; index++)
                  if (wideCustomerNavigation)
                    TextButton.icon(
                      onPressed: () => context.go(links[index].path),
                      icon: Icon(
                        index == selected
                            ? links[index].selectedIcon
                            : links[index].icon,
                        size: 18,
                      ),
                      label: Text(links[index].label),
                    )
                  else
                    IconButton(
                      onPressed: () => context.go(links[index].path),
                      tooltip: links[index].label,
                      icon: Icon(
                        index == selected
                            ? links[index].selectedIcon
                            : links[index].icon,
                      ),
                    ),
                IconButton(
                  onPressed: auth.logout,
                  tooltip: 'Выйти',
                  icon: const Icon(Icons.logout),
                ),
                const SizedBox(width: 8),
              ]
            : [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: Text('${auth.name ?? ''} · ${_roleName(auth.role)}'),
                  ),
                ),
                TextButton(onPressed: auth.logout, child: const Text('Выйти')),
                const SizedBox(width: 8),
              ],
      ),
      bottomNavigationBar: compact
          ? _BottomNavigation(
              links: links,
              selected: selected,
              onSelected: (index) => context.go(links[index].path),
            )
          : null,
      body: SafeArea(
        child: compact || customer
            ? content()
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SideNavigation(
                    links: links,
                    selected: selected,
                    extended: expanded,
                    onSelected: (index) => context.go(links[index].path),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: content()),
                ],
              ),
      ),
    );
  }

  List<_NavigationLink> _links(String? role) {
    if (role == 'customer') {
      return const [
        _NavigationLink('/home', 'Главная', Icons.home_outlined, Icons.home),
        _NavigationLink(
          '/catalog',
          'Каталог',
          Icons.store_outlined,
          Icons.store,
        ),
        _NavigationLink(
          '/cart',
          'Корзина',
          Icons.shopping_cart_outlined,
          Icons.shopping_cart,
        ),
        _NavigationLink(
          '/profile',
          'Профиль',
          Icons.person_outline,
          Icons.person,
        ),
      ];
    }
    return [
      const _NavigationLink(
        '/home',
        'Главная',
        Icons.home_outlined,
        Icons.home,
      ),
      const _NavigationLink(
        '/products',
        'Товары',
        Icons.store_outlined,
        Icons.store,
      ),
      const _NavigationLink(
        '/brands',
        'Бренды',
        Icons.sell_outlined,
        Icons.sell,
      ),
      const _NavigationLink(
        '/categories',
        'Категории',
        Icons.category_outlined,
        Icons.category,
      ),
      const _NavigationLink(
        '/platforms',
        'Платформы',
        Icons.devices_outlined,
        Icons.devices,
      ),
      const _NavigationLink(
        '/users',
        'Пользователи',
        Icons.people_outline,
        Icons.people,
      ),
      const _NavigationLink(
        '/orders',
        'Заказы',
        Icons.receipt_long_outlined,
        Icons.receipt_long,
      ),
      if (role == 'admin')
        const _NavigationLink(
          '/accounts',
          'Аккаунты',
          Icons.manage_accounts_outlined,
          Icons.manage_accounts,
        ),
      if (role == 'admin')
        const _NavigationLink(
          '/statistics',
          'Статистика',
          Icons.bar_chart_outlined,
          Icons.bar_chart,
        ),
    ];
  }

  String _roleName(String? role) => switch (role) {
    'admin' => 'Администратор',
    'manager' => 'Менеджер',
    _ => 'Покупатель',
  };
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.links,
    required this.selected,
    required this.onSelected,
  });

  final List<_NavigationLink> links;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: links.length,
            itemBuilder: (context, index) {
              final link = links[index];
              final active = index == selected;
              return Semantics(
                selected: active,
                button: true,
                label: link.label,
                child: InkWell(
                  onTap: () => onSelected(index),
                  child: SizedBox(
                    width: 92,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          active ? link.selectedIcon : link.icon,
                          color: active
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          link.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SideNavigation extends StatelessWidget {
  const _SideNavigation({
    required this.links,
    required this.selected,
    required this.extended,
    required this.onSelected,
  });

  final List<_NavigationLink> links;
  final int selected;
  final bool extended;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: extended ? 220 : 80,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        itemCount: links.length,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final link = links[index];
          final active = selected == index;
          final tile = InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onSelected(index),
            child: Container(
              height: 56,
              padding: EdgeInsets.symmetric(horizontal: extended ? 16 : 0),
              decoration: BoxDecoration(
                color: active
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: extended
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(active ? link.selectedIcon : link.icon),
                  if (extended) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        link.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
          return Semantics(
            selected: active,
            button: true,
            label: link.label,
            child: extended ? tile : Tooltip(message: link.label, child: tile),
          );
        },
      ),
    );
  }
}

class _NavigationLink {
  const _NavigationLink(this.path, this.label, this.icon, this.selectedIcon);

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
