import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/category_state.dart';
import '../state/platform_state.dart';
import '../state/status.dart';
import '../widgets/shop_page.dart';
import '../widgets/status_view.dart';

class DirectoryDetail extends StatefulWidget {
  const DirectoryDetail({super.key, required this.kind, required this.id});
  final String kind;
  final int id;
  @override
  State<DirectoryDetail> createState() => _DirectoryDetailState();
}

class _DirectoryDetailState extends State<DirectoryDetail> {
  late Future<({String name, bool deleted, int count})?> _item;
  @override
  void initState() { super.initState(); _item = _load(); }
  Future<({String name, bool deleted, int count})?> _load() async {
    if (widget.kind == 'categories') {
      final state = context.read<CategoryState>();
      final item = await state.findById(widget.id);
      await state.load();
      return item == null ? null : (name: item.name, deleted: item.isDeleted, count: state.productCount(item.id));
    }
    final state = context.read<PlatformState>();
    final item = await state.findById(widget.id);
    await state.load();
    return item == null ? null : (name: item.name, deleted: item.isDeleted, count: state.productCount(item.id));
  }
  @override
  Widget build(BuildContext context) {
    final path = '/${widget.kind}';
    return ShopPage(title: widget.kind == 'categories' ? 'Категория' : 'Платформа',
      child: FutureBuilder<({String name, bool deleted, int count})?>(future: _item,
        builder: (context, snapshot) {
          if (snapshot.hasError) { return StatusView(message: errorText(snapshot.error!), onRetry: () => setState(() => _item = _load())); }
          if (snapshot.connectionState != ConnectionState.done) { return const Center(child: CircularProgressIndicator()); }
          final item = snapshot.data;
          return ListView(children: [
            Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: () => context.go(Uri(path: path,
              queryParameters: GoRouterState.of(context).uri.queryParameters).toString()), child: const Text('К списку'))),
            if (item == null) const Text('Запись не найдена') else ...[
              Text(item.name, style: Theme.of(context).textTheme.titleLarge),
              Text('ID: ${widget.id}'), Text('Статус: ${item.deleted ? 'Удалён' : 'Активен'}'),
              Text('Связанных товаров: ${item.count}'),
              if (!item.deleted) Align(alignment: Alignment.centerLeft, child: FilledButton(
                onPressed: () => context.go('$path/${widget.id}/edit'), child: const Text('Изменить'))),
            ],
          ]);
        }));
  }
}
