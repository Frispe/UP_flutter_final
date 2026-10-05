import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../models/product.dart';
import '../state/user_state.dart';
import '../state/product_state.dart';
import '../state/cart_state.dart';
import '../state/order_state.dart';
import '../state/status.dart';
import '../format.dart';
import '../validators.dart';
import '../widgets/shop_page.dart';
import '../widgets/status_view.dart';

class UserDetail extends StatefulWidget {
  const UserDetail({super.key, required this.id});
  final int id;
  @override
  State<UserDetail> createState() => _UserDetailState();
}

class _UserDetailState extends State<UserDetail> {
  final _form = GlobalKey<FormState>();
  final _quantity = TextEditingController(text: '1');
  User? _user;
  List<Product> _products = [];
  int? _productId;
  bool _loading = true;
  String? _error;

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
    final users = context.read<UserState>();
    final products = context.read<ProductState>();
    try {
      final user = await users.findById(widget.id);
      if (user == null) {
        throw StateError('Пользователь не найден');
      }
      final options = await products.findOptions();
      if (!mounted) {
        return;
      }
      setState(() {
        _user = user;
        _products = options;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = errorText(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _action(Future<bool> Function() action) async {
    final cart = context.read<CartState>();
    final success = await action();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Корзина обновлена'
              : cart.actionError ?? 'Не удалось изменить корзину',
        ),
      ),
    );
  }

  Future<void> _clear() async {
    final cart = context.read<CartState>();
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить корзину?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      await _action(cart.clear);
    }
  }

  Future<void> _checkout() async {
    final cart = context.read<CartState>();
    final data = cart.data;
    if (data == null || data.items.isEmpty) return;
    final orders = context.read<OrderState>();
    final order = await orders.checkout(data.cart.id);
    if (!mounted) return;
    if (order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orders.actionError ?? 'Не удалось оформить заказ'),
        ),
      );
      return;
    }
    await cart.load(widget.id);
    if (mounted) context.go('/orders/${order.id}');
  }

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    final orders = context.watch<OrderState>();
    if (_loading || _error != null) {
      return ShopPage(
        title: 'Пользователь',
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : StatusView(message: _error!, onRetry: _load),
      );
    }
    final user = _user!;
    final data = cart.data;
    final enabled = !user.isDeleted && !cart.saving && data != null;
    return ShopPage(
      title: user.name,
      child: ListView(
        children: [
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => context.go(
                  Uri(
                    path: '/users',
                    queryParameters: GoRouterState.of(context)
                        .uri
                        .queryParameters,
                  ).toString(),
                ),
                child: const Text('К пользователям'),
              ),
              if (!user.isDeleted)
                TextButton(
                  onPressed: cart.saving
                      ? null
                      : () => context.go('/users/${user.id}/edit'),
                  child: const Text('Изменить пользователя'),
                ),
            ],
          ),
          Text('Почта: ${user.email}'),
          Text(
            'Никнейм: ${user.nickname.isEmpty ? 'не указан' : user.nickname}',
          ),
          if (user.isDeleted)
            const Text(
              'Пользователь удалён. Корзина доступна только для просмотра.',
            ),
          const SizedBox(height: 20),
          Text('Корзина', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (cart.status == LoadStatus.loading)
            const LinearProgressIndicator(),
          if (cart.status == LoadStatus.error) ...[
            Text(cart.error ?? 'Не удалось загрузить корзину'),
            TextButton(
              onPressed: () => cart.load(widget.id),
              child: const Text('Повторить'),
            ),
          ],
          if (data != null) ...[
            if (!user.isDeleted)
              Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: _productId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Товар',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final product in _products)
                          DropdownMenuItem(
                            value: product.id,
                            child: Text(
                              '${product.name} · ${product.region} · ${formatPrice(product.price)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      validator: Validators.choice,
                      onChanged: enabled
                          ? (value) => setState(() => _productId = value)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _quantity,
                      enabled: enabled,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Количество',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => Validators.integer(value),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton(
                        onPressed: !enabled
                            ? null
                            : () {
                                if (_form.currentState!.validate()) {
                                  _action(
                                    () => cart.add(
                                      _productId!,
                                      quantity: int.parse(
                                        _quantity.text.trim(),
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: const Text('Добавить в корзину'),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (data.items.isEmpty) const Text('Корзина пуста'),
            for (final item in data.items)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.products[item.productId]?.name ??
                            'Удалённый товар № ${item.productId}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (data.products[item.productId] != null)
                        Text(
                          'Регион: ${data.products[item.productId]!.region}',
                        ),
                      if (!data.available(item))
                        const Text('Товар недоступен — не включён в сумму')
                      else
                        Text(
                          'Цена: ${formatPrice(data.products[item.productId]!.price)} · Сумма: ${formatPrice(data.products[item.productId]!.price * item.quantity)}',
                        ),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton(
                            onPressed:
                                enabled &&
                                    data.available(item) &&
                                    item.quantity > 1
                                ? () => _action(
                                    () => cart.setQuantity(
                                      item.id,
                                      item.quantity - 1,
                                    ),
                                  )
                                : null,
                            child: const Text('−'),
                          ),
                          Text('Количество: ${item.quantity}'),
                          TextButton(
                            onPressed:
                                enabled &&
                                    data.available(item) &&
                                    item.quantity < 999
                                ? () => _action(
                                    () => cart.setQuantity(
                                      item.id,
                                      item.quantity + 1,
                                    ),
                                  )
                                : null,
                            child: const Text('+'),
                          ),
                          TextButton(
                            onPressed: enabled
                                ? () => _action(() => cart.remove(item.id))
                                : null,
                            child: const Text('Убрать'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'Итого: ${formatPrice(data.total)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed:
                        enabled && data.items.isNotEmpty && !orders.saving
                        ? _checkout
                        : null,
                    child: Text(
                      orders.saving ? 'Оформление…' : 'Оформить заказ',
                    ),
                  ),
                  TextButton(
                    onPressed: enabled && data.items.isNotEmpty ? _clear : null,
                    child: const Text('Очистить корзину'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
