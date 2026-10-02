import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../state/status.dart';
import '../widgets/shop_page.dart';
import '../widgets/status_view.dart';
import 'directory_form.dart';

class DirectoryList extends StatefulWidget {
  const DirectoryList({super.key, required this.kind});
  final Directory kind;
  @override
  State<DirectoryList> createState() => _DirectoryListState();
}

class _DirectoryListState extends State<DirectoryList> {
  late Future<List<({int id, String name, bool deleted})>> _items;
  @override
  void initState() { super.initState(); _items = directoryItems(context, widget.kind); }
  @override
  Widget build(BuildContext context) {
    return ShopPage(title: directoryTitle(widget.kind), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(alignment: Alignment.centerLeft, child: FilledButton(
          onPressed: () => context.go('/${widget.kind.name}/new'), child: const Text('Добавить'))),
        const SizedBox(height: 12),
        Expanded(child: FutureBuilder<List<({int id, String name, bool deleted})>>(
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return StatusView(message: errorText(snapshot.error!), onRetry: () {
                setState(() => _items = directoryItems(context, widget.kind));
              });
            }
            if (!snapshot.hasData) { return const Center(child: CircularProgressIndicator()); }
            final items = snapshot.data!.where((item) => !item.deleted).toList();
            if (items.isEmpty) { return const StatusView(message: 'Записей пока нет'); }
            return ListView.builder(itemCount: items.length, itemBuilder: (context, index) {
              final item = items[index];
              return Card(child: ListTile(title: Text(item.name), subtitle: Text('ID: ${item.id}'),
                trailing: TextButton(onPressed: () => context.go('/${widget.kind.name}/${item.id}/edit'),
                  child: const Text('Изменить'))));
            });
          },
        )),
      ],
    ));
  }
}
