import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/brand.dart' as model;
import '../models/category.dart' as model;
import '../models/platform.dart' as model;
import '../state/brand_state.dart';
import '../state/category_state.dart';
import '../state/platform_state.dart';
import '../state/status.dart';
import '../validators.dart';
import '../widgets/form_input.dart';
import '../widgets/shop_form.dart';
import '../widgets/shop_page.dart';
import '../widgets/status_view.dart';

enum Directory { brands, categories, platforms }

String directoryTitle(Directory kind) => switch (kind) {
  Directory.brands => 'Бренды',
  Directory.categories => 'Категории',
  Directory.platforms => 'Платформы',
};

Future<List<({int id, String name, bool deleted})>> directoryItems(BuildContext context, Directory kind) async {
  return switch (kind) {
    Directory.brands => (await context.read<BrandState>().findOptions(includeDeleted: true))
        .map((item) => (id: item.id, name: item.name, deleted: item.isDeleted)).toList(),
    Directory.categories => (await context.read<CategoryState>().findOptions(includeDeleted: true))
        .map((item) => (id: item.id, name: item.name, deleted: item.isDeleted)).toList(),
    Directory.platforms => (await context.read<PlatformState>().findOptions(includeDeleted: true))
        .map((item) => (id: item.id, name: item.name, deleted: item.isDeleted)).toList(),
  };
}

class DirectoryForm extends StatefulWidget {
  const DirectoryForm({super.key, required this.kind, this.id});
  final Directory kind;
  final int? id;
  @override
  State<DirectoryForm> createState() => _DirectoryFormState();
}

class _DirectoryFormState extends State<DirectoryForm> {
  final _name = TextEditingController();
  bool _loading = true;
  String? _loadError;
  String? _fieldError;
  List<String> _names = [];
  List<model.Platform> _platforms = [];
  List<int> _selected = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _loadError = null; });
    try {
      final platformState = context.read<PlatformState>();
      final brandState = context.read<BrandState>();
      final items = await directoryItems(context, widget.kind);
      final current = items.where((item) => item.id == widget.id).toList();
      if (widget.id != null && current.isEmpty) {
        throw StateError('Запись не найдена');
      }
      if (current.isNotEmpty && current.single.deleted) {
        throw StateError('Перед редактированием восстановите запись');
      }
      var platforms = <model.Platform>[];
      var selected = <int>[];
      if (widget.kind == Directory.brands) {
        platforms = await platformState.findOptions();
        if (widget.id != null) {
          final brand = await brandState.findById(widget.id!);
          selected = List.of(brand?.platformIds ?? []);
        }
      }
      if (!mounted) { return; }
      _name.text = current.isEmpty ? '' : current.single.name;
      setState(() {
        _names = items.where((item) => item.id != widget.id).map((item) => item.name).toList();
        _platforms = platforms;
        _selected = selected;
        _loading = false;
      });
    } catch (e) {
      if (mounted) { setState(() { _loadError = errorText(e); _loading = false; }); }
    }
  }

  Future<bool> _save() async {
    final brands = context.read<BrandState>();
    final categories = context.read<CategoryState>();
    final platforms = context.read<PlatformState>();
    final items = await directoryItems(context, widget.kind);
    if (!mounted) { return false; }
    final duplicate = Validators.unique(_name.text,
        items.where((item) => item.id != widget.id).map((item) => item.name));
    setState(() => _fieldError = duplicate);
    if (duplicate != null) { return false; }
    final id = widget.id ?? 0;
    switch (widget.kind) {
      case Directory.brands:
        final item = model.Brand(id: id, name: _name.text, platformIds: List.unmodifiable(_selected));
        return widget.id == null ? brands.create(item) : brands.update(item);
      case Directory.categories:
        final item = model.Category(id: id, name: _name.text);
        return widget.id == null ? categories.create(item) : categories.update(item);
      case Directory.platforms:
        final item = model.Platform(id: id, name: _name.text);
        return widget.id == null ? platforms.create(item) : platforms.update(item);
    }
  }

  @override
  void dispose() { _name.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final title = '${widget.id == null ? 'Создание' : 'Редактирование'}: ${directoryTitle(widget.kind).toLowerCase()}';
    if (_loading || _loadError != null) {
      return ShopPage(title: title, child: _loading
          ? const Center(child: CircularProgressIndicator())
          : StatusView(message: _loadError!, onRetry: _load));
    }
    return ShopForm(
      title: title,
      submitLabel: widget.id == null ? 'Создать' : 'Сохранить',
      onSubmit: _save,
      onSaved: () => context.go('/${widget.kind.name}'),
      onCancel: () => context.go('/${widget.kind.name}'),
      actionError: () => _fieldError ?? switch (widget.kind) {
        Directory.brands => context.read<BrandState>().actionError,
        Directory.categories => context.read<CategoryState>().actionError,
        Directory.platforms => context.read<PlatformState>().actionError,
      },
      fields: [
        FormInput(label: 'Название', controller: _name,
          fieldError: _fieldError,
          onChanged: (_) { if (_fieldError != null) { setState(() => _fieldError = null); } },
          validator: (value) => Validators.text(value) ?? Validators.unique(value, _names)),
        if (widget.kind == Directory.brands)
          FormField<List<int>>(
            initialValue: _selected,
            validator: (value) {
              if (value != null && value.any((id) => !_platforms.any((item) => item.id == id))) {
                return 'Уберите недоступные платформы';
              }
              return null;
            },
            builder: (field) => InputDecorator(
              decoration: InputDecoration(labelText: 'Доступные платформы',
                border: const OutlineInputBorder(), errorText: field.errorText),
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                if (_platforms.isEmpty) const Text('Сначала добавьте платформу в разделе «Платформы»'),
                for (final platform in _platforms)
                  FilterChip(label: Text(platform.name), selected: _selected.contains(platform.id),
                    onSelected: (selected) {
                      final next = [..._selected];
                      if (selected) { next.add(platform.id); } else { next.remove(platform.id); }
                      field.didChange(next);
                      setState(() => _selected = next);
                    }),
                for (final id in _selected.where((id) => !_platforms.any((item) => item.id == id)))
                  FilterChip(label: Text('Недоступная платформа № $id'), selected: true,
                    onSelected: (_) { final next = [..._selected]..remove(id); field.didChange(next); setState(() => _selected = next); }),
              ]),
            ),
          ),
      ],
    );
  }
}
