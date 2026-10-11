import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/product.dart';
import '../state/order_state.dart';
import '../state/auth_state.dart';
import '../state/product_state.dart';
import '../state/status.dart';
import '../widgets/shop_page.dart';
import '../widgets/status_view.dart';

class OrderDetail extends StatefulWidget {
  const OrderDetail({super.key, required this.id});

  final int id;

  @override
  State<OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetail> {
  Order? _order;
  List<OrderItem> _items = [];
  Map<int, Product> _products = {};
  String? _selectedStatus;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final orders = context.read<OrderState>();
    final products = context.read<ProductState>();
    try {
      final order = await orders.findById(widget.id);
      if (order == null) throw StateError('Заказ не найден');
      final items = await orders.findItems(widget.id);
      final productRows = await products.findOptions();
      if (!mounted) return;
      setState(() {
        _order = order;
        _items = items;
        _products = {for (final product in productRows) product.id: product};
        _selectedStatus = order.status;
        _loading = false;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        _error = errorText(exception);
        _loading = false;
      });
    }
  }

  Future<void> _saveStatus() async {
    final value = _selectedStatus;
    if (_order == null || value == null) return;
    final success = await context.read<OrderState>().updateStatus(
      _order!,
      value,
    );
    if (!mounted) return;
    if (success) {
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<OrderState>().actionError ??
                'Не удалось изменить статус',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _error != null) {
      return ShopPage(
        title: 'Заказ',
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : StatusView(message: _error!, onRetry: _load),
      );
    }
    final order = _order!;
    final state = context.watch<OrderState>();
    final canManage = context.watch<AuthState>().role != 'customer';
    return ShopPage(
      title: 'Заказ № ${order.id}',
      child: ListView(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.go('/orders'),
              child: const Text('К заказам'),
            ),
          ),
          Text(
            'Пользователь: ${state.userNames[order.userId] ?? '№ ${order.userId}'}',
          ),
          Text('Дата: ${formatDate(order.orderedAt)}'),
          Text('Итого: ${formatPrice(order.totalPrice)}'),
          const SizedBox(height: 16),
          if (canManage)
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 520;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: compact ? constraints.maxWidth : 220,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Статус',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final value in [
                            'new',
                            'paid',
                            'completed',
                            'cancelled',
                          ])
                            DropdownMenuItem(
                              value: value,
                              child: Text(orderStatusName(value)),
                            ),
                        ],
                        onChanged: state.saving
                            ? null
                            : (value) =>
                                  setState(() => _selectedStatus = value),
                      ),
                    ),
                    FilledButton(
                      onPressed: state.saving || _selectedStatus == order.status
                          ? null
                          : _saveStatus,
                      child: const Text('Сохранить статус'),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 24),
          Text('Состав заказа', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final item in _items)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _products[item.productId]?.name ??
                                'Товар № ${item.productId}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${item.quantity} шт. × ${formatPrice(item.price)}',
                          ),
                        ],
                      ),
                    ),
                    Text(formatPrice(item.totalPrice)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
