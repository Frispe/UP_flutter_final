import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/query.dart';
import '../query_url.dart';
import '../screens/category_list.dart';
import '../state/category_state.dart';
import '../screens/platform_list.dart';
import '../state/platform_state.dart';
import '../screens/user_list.dart';
import '../state/user_state.dart';

import '../state/status.dart';
import 'shop_page.dart';

class CatalogRoute extends StatefulWidget {
  const CatalogRoute({super.key, required this.uri, required this.kind});

  final Uri uri;
  final String kind;

  @override
  State<CatalogRoute> createState() => _CatalogRouteState();
}

class _CatalogRouteState extends State<CatalogRoute> {
  bool _ready = false;
  String? _error;
  int _request = 0;

  String get _path => '/${widget.kind}';

  @override
  void initState() {
    super.initState();
    _scheduleLoad();
  }

  @override
  void didUpdateWidget(covariant CatalogRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri || oldWidget.kind != widget.kind) {
      _scheduleLoad();
    }
  }

  void _scheduleLoad() {
    final request = ++_request;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || request != _request || widget.uri.path != _path) {
        return;
      }
      Query query;
      try {
        query = readQuery(widget.uri, brands: true);
      } on FormatException catch (error) {
        if (mounted) setState(() => _error = error.message);
        return;
      }
      final loading = switch (widget.kind) {
        'categories' => context.read<CategoryState>().applyQuery(query),
        'platforms' => context.read<PlatformState>().applyQuery(query),
        _ => context.read<UserState>().applyQuery(query),
      };
      setState(() {
        _error = null;
        _ready = true;
      });
      await loading;
      if (!mounted || request != _request || widget.uri.path != _path) {
        return;
      }
      final actual = switch (widget.kind) {
        'categories' => context.read<CategoryState>().query,
        'platforms' => context.read<PlatformState>().query,
        _ => context.read<UserState>().query,
      };
      final status = switch (widget.kind) {
        'categories' => context.read<CategoryState>().status,
        'platforms' => context.read<PlatformState>().status,
        _ => context.read<UserState>().status,
      };
      if (status != LoadStatus.error && actual.page != query.page) {
        context.replace(queryUrl(_path, actual));
      }
    });
  }

  void _change(Query query) {
    if (!mounted || widget.uri.path != _path) {
      return;
    }
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
        title: 'Загрузка списка',
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return switch (widget.kind) {
      'categories' => CategoryList(onQueryChanged: _change),
      'platforms' => PlatformList(onQueryChanged: _change),
      _ => UserList(onQueryChanged: _change),
    };
  }
}
