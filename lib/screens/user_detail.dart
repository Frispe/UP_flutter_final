import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../models/product.dart';
import '../state/user_state.dart';
import '../state/auth_state.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _CheckoutDialog(email: _user?.email ?? ''),
    );
    if (confirmed != true || !mounted) return;
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
    final isCustomer = context.watch<AuthState>().role == 'customer';
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
              if (!isCustomer)
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
              if (!isCustomer && !user.isDeleted)
                TextButton(
                  onPressed: cart.saving
                      ? null
                      : () => context.go('/users/${user.id}/edit'),
                  child: const Text('Изменить пользователя'),
                ),
            ],
          ),
          if (!isCustomer) ...[
            Text('ФИО: ${user.name}'),
            Text('Почта: ${user.email}'),
            Text(
              'Никнейм: ${user.nickname.isEmpty ? 'не указан' : user.nickname}',
            ),
          ],
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
            if (!user.isDeleted && !isCustomer)
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
                      orders.saving ? 'Оформление…' : 'Заказать',
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

class _CheckoutDialog extends StatefulWidget {
  const _CheckoutDialog({required this.email});

  final String email;

  @override
  State<_CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<_CheckoutDialog> {
  final _form = GlobalKey<FormState>();
  final _card = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _card.dispose();
    _expiry.dispose();
    _cvv.dispose();
    _email.dispose();
    super.dispose();
  }

  String? _cardValidator(String? value) {
    if (!RegExp(r'^\d{16}$').hasMatch(value?.trim() ?? '')) {
      return 'Введите 16 цифр номера карты';
    }
    return null;
  }

  String? _expiryValidator(String? value) {
    final match = RegExp(r'^(0[1-9]|1[0-2])/(\d{2})$').firstMatch(
      value?.trim() ?? '',
    );
    if (match == null) {
      return 'Введите срок в формате ММ/ГГ';
    }
    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    final now = DateTime.now();
    if (year < now.year || (year == now.year && month < now.month)) {
      return 'Срок действия карты истёк';
    }
    return null;
  }

  void _submit() {
    if (_form.currentState!.validate()) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Оформление заказа'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _card,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.creditCardNumber],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Номер карты',
                    hintText: '0000000000000000',
                  ),
                  validator: _cardValidator,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expiry,
                        keyboardType: TextInputType.datetime,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9/]'),
                          ),
                          LengthLimitingTextInputFormatter(5),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'ММ/ГГ',
                          hintText: '12/28',
                        ),
                        validator: _expiryValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cvv,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        autofillHints: const [
                          AutofillHints.creditCardSecurityCode,
                        ],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          hintText: '000',
                        ),
                        validator: (value) => RegExp(
                          r'^\d{3}$',
                        ).hasMatch(value ?? '')
                            ? null
                            : 'Введите 3 цифры',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Почта для получения товаров',
                    helperText: 'На эту почту придут приобретённые товары',
                    helperMaxLines: 2,
                  ),
                  validator: Validators.email,
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Подтвердить заказ'),
        ),
      ],
    );
  }
}
