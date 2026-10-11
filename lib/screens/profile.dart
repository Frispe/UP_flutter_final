import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../repositories/api_repositories.dart';
import '../repositories/user_repository.dart';
import '../state/auth_state.dart';
import '../state/status.dart';
import '../widgets/shop_page.dart';
import '../widgets/status_view.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  List<Order> _orders = [];
  LoadStatus _status = LoadStatus.loading;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = context.read<AuthState>().customerId;
    if (id == null) {
      setState(() {
        _error = 'Профиль покупателя недоступен';
        _status = LoadStatus.error;
      });
      return;
    }
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
    });
    try {
      final user = await context.read<UserRepository>().findById(id);
      final orders = await context.read<ApiOrderRepository>().find(
        size: 50,
        userId: id,
      );
      if (!mounted) return;
      setState(() {
        _user = user;
        _orders = orders.items;
        _status = LoadStatus.success;
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
      title: 'Профиль',
      child: switch (_status) {
        LoadStatus.idle ||
        LoadStatus.loading => const Center(child: CircularProgressIndicator()),
        LoadStatus.error => StatusView(
          message: _error ?? 'Не удалось загрузить профиль',
          onRetry: _load,
        ),
        LoadStatus.empty => const StatusView(message: 'Профиль не найден'),
        LoadStatus.success => _content(context),
      },
    );
  }

  Widget _content(BuildContext context) {
    final user = _user;
    if (user == null) {
      return const StatusView(message: 'Профиль не найден');
    }
    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Wrap(
              spacing: 20,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CircleAvatar(
                  radius: 34,
                  child: Text(
                    user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(user.email),
                    Text('@${user.nickname}'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Мои заказы', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (_orders.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Заказов пока нет'),
            ),
          ),
        for (final order in _orders)
          Card(
            child: InkWell(
              onTap: () => context.go('/orders/${order.id}'),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Заказ № ${order.id}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(formatDate(order.orderedAt)),
                        Text(orderStatusName(order.status)),
                      ],
                    ),
                    Text(
                      formatPrice(order.totalPrice),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
