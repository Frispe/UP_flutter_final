import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../state/order_state.dart';
import '../state/status.dart';
import '../widgets/pagination.dart';
import '../widgets/shop_page.dart';
import '../widgets/status_view.dart';

class OrderList extends StatefulWidget {
  const OrderList({super.key});

  @override
  State<OrderList> createState() => _OrderListState();
}

class _OrderListState extends State<OrderList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrderState>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OrderState>();
    final child = switch (state.status) {
      LoadStatus.idle ||
      LoadStatus.loading => const Center(child: CircularProgressIndicator()),
      LoadStatus.error => StatusView(
        message: state.error ?? 'Не удалось загрузить заказы',
        onRetry: state.load,
      ),
      LoadStatus.empty => const StatusView(message: 'Заказов пока нет'),
      LoadStatus.success => Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: state.result.items.length,
              itemBuilder: (context, index) {
                final order = state.result.items[index];
                return Card(
                  child: ListTile(
                    onTap: () => context.go('/orders/${order.id}'),
                    title: Text('Заказ № ${order.id}'),
                    subtitle: Text(
                      '${state.userNames[order.userId] ?? 'Пользователь № ${order.userId}'} · '
                      '${formatDate(order.orderedAt)} · ${orderStatusName(order.status)}',
                    ),
                    trailing: Text(formatPrice(order.totalPrice)),
                  ),
                );
              },
            ),
          ),
          Pagination(
            page: state.result.page,
            size: state.result.size,
            total: state.result.total,
            enabled: !state.saving,
            onPageChanged: (page) =>
                state.load(page: page, size: state.result.size),
            onSizeChanged: (size) => state.load(size: size),
          ),
        ],
      ),
    };
    return ShopPage(title: 'Заказы', child: child);
  }
}
