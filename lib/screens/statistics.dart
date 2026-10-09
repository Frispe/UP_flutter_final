import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../format.dart';
import '../widgets/shop_page.dart';
import '../widgets/status_view.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final response = await guard(() => context.read<Dio>().get('/statistics'));
      if (!mounted) return;
      setState(() => _data = Map<String, dynamic>.from(response.data as Map));
    } catch (exception) {
      if (!mounted) return;
      setState(() => _error = exception is ApiException ? exception.message : '$exception');
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final roles = data == null ? const <String, dynamic>{} : Map<String, dynamic>.from(data['roles'] as Map);
    return ShopPage(
      title: 'Статистика',
      child: _error != null
          ? StatusView(message: _error!, onRetry: _load)
          : data == null
          ? const Center(child: CircularProgressIndicator())
          : GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width < 700 ? 2 : 4,
              childAspectRatio: 1.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _card('Товаров', '${data['products']}'),
                _card('Пользователей', '${data['customers']}'),
                _card('Заказов', '${data['orders']}'),
                _card('Выручка', formatPrice(data['revenue'] as int? ?? 0)),
                _card('Покупателей', '${roles['customer'] ?? 0}'),
                _card('Менеджеров', '${roles['manager'] ?? 0}'),
                _card('Администраторов', '${roles['admin'] ?? 0}'),
              ],
            ),
    );
  }

  Widget _card(String title, String value) => Card(
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          Text(title, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
