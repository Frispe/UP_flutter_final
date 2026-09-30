import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/query.dart';
import '../query_url.dart';
import '../screens/brand_list.dart';
import '../screens/product_list.dart';
import '../state/brand_state.dart';
import '../state/product_state.dart';
import '../state/status.dart';
import 'shop_page.dart';

class ListRoute extends StatefulWidget {
  const ListRoute({super.key, required this.uri, required this.brands});

  final Uri uri;
  final bool brands;

  @override
  State<ListRoute> createState() => _ListRouteState();
}

class _ListRouteState extends State<ListRoute> {
  bool _ready = false;
  String? _error;
  int _request = 0;

  String get _path => widget.brands ? '/brands' : '/products';

  @override
  void initState() {
    super.initState();
    _scheduleLoad();
  }

  @override
  void didUpdateWidget(covariant ListRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri || oldWidget.brands != widget.brands) {
      _scheduleLoad();
    }
  }

  void _scheduleLoad() {
    final request = ++_request;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || request != _request || widget.uri.path != _path) return;
      Query query;
      try {
        query = readQuery(widget.uri, brands: widget.brands);
      } on FormatException catch (error) {
        if (mounted) setState(() => _error = error.message);
        return;
      }
      final Future<void> loading;
      if (widget.brands) {
        loading = context.read<BrandState>().applyQuery(query);
      } else {
        loading = context.read<ProductState>().applyQuery(query);
      }
      setState(() {
        _error = null;
        _ready = true;
      });
      await loading;
      if (!mounted || request != _request || widget.uri.path != _path) return;
      final actual = widget.brands
          ? context.read<BrandState>().query
          : context.read<ProductState>().query;
      final status = widget.brands
          ? context.read<BrandState>().status
          : context.read<ProductState>().status;
      if (status != LoadStatus.error && actual.page != query.page) {
        context.replace(queryUrl(_path, actual));
      }
    });
  }

  void _change(Query query) {
    if (!mounted || widget.uri.path != _path) return;
    final url = queryUrl(_path, query);
    if (url != widget.uri.toString()) context.go(url);
  }

  @override
  void dispose() {
    ++_request;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ShopPage(
        title: 'Ошибка параметров адреса',
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go(_path),
                  child: const Text('Сбросить параметры'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (!_ready) {
      return ShopPage(
        title: widget.brands ? 'Бренды' : 'Каталог товаров',
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return widget.brands
        ? BrandList(onQueryChanged: _change)
        : ProductList(onQueryChanged: _change);
  }
}
