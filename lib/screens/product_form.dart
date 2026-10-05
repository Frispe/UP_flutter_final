import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../models/brand.dart';
import '../models/category.dart' as model;
import '../models/platform.dart' as model;
import '../state/product_state.dart';
import '../state/brand_state.dart';
import '../state/category_state.dart';
import '../state/platform_state.dart';
import '../state/status.dart';
import '../format.dart';
import '../validators.dart';
import '../widgets/form_input.dart';
import '../widgets/shop_form.dart';
import '../widgets/shop_page.dart';
import '../widgets/status_view.dart';

class ProductForm extends StatefulWidget {
  const ProductForm({super.key, this.id});
  final int? id;
  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _region = TextEditingController();
  final _duration = TextEditingController();
  List<Brand> _brands = [];
  List<model.Category> _categories = [];
  List<model.Platform> _platforms = [];
  List<int> _categoryIds = [];
  int? _brandId;
  int? _platformId;
  ProductType _type = ProductType.gameKey;
  bool _loading = true;
  String? _loadError;
  Map<String, String> _serverErrors = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final products = context.read<ProductState>();
    final brands = context.read<BrandState>();
    final categories = context.read<CategoryState>();
    final platforms = context.read<PlatformState>();
    try {
      final brandRows = await brands.findOptions();
      final categoryRows = await categories.findOptions();
      final platformRows = await platforms.findOptions();
      final item = widget.id == null
          ? null
          : await products.findById(widget.id!);
      if (widget.id != null && item == null) {
        throw StateError('Товар не найден');
      }
      if (item?.isDeleted ?? false) {
        throw StateError('Сначала восстановите товар');
      }
      if (!mounted) {
        return;
      }
      _name.text = item?.name ?? '';
      _sku.text = item?.sku ?? '';
      _description.text = item?.description ?? '';
      _region.text = item?.region ?? '';
      _price.text = item == null
          ? ''
          : '${item.price ~/ 100}.${(item.price % 100).toString().padLeft(2, '0')}';
      _duration.text = item?.durationMonths?.toString() ?? '';
      setState(() {
        _brands = brandRows;
        _categories = categoryRows;
        _platforms = platformRows;
        _brandId = item?.brandId;
        _platformId = item?.platformId;
        _categoryIds = List.of(item?.categoryIds ?? []);
        _type = item?.type ?? ProductType.gameKey;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = errorText(e);
          _loading = false;
        });
      }
    }
  }

  List<model.Platform> get _availablePlatforms {
    final brands = _brands.where((item) => item.id == _brandId);
    if (brands.isEmpty) {
      return [];
    }
    return _platforms
        .where((item) => brands.first.platformIds.contains(item.id))
        .toList();
  }

  Future<bool> _save() async {
    final state = context.read<ProductState>();
    setState(() => _serverErrors = {});
    final item = Product(
      id: widget.id ?? 0,
      name: _name.text,
      sku: _sku.text,
      description: _description.text,
      type: _type,
      brandId: _brandId!,
      price: Validators.priceValue(_price.text)!,
      platformId: _platformId!,
      categoryIds: List.unmodifiable(_categoryIds),
      region: _region.text,
      durationMonths: _type == ProductType.aiSubscription
          ? int.parse(_duration.text.trim())
          : null,
    );
    final success = widget.id == null
        ? await state.create(item)
        : await state.update(item);
    if (!success && mounted) {
      setState(() => _serverErrors = state.validationErrors);
    }
    return success;
  }

  void _clearServerError(String field) {
    if (!_serverErrors.containsKey(field)) return;
    setState(() => _serverErrors = Map.of(_serverErrors)..remove(field));
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _sku,
      _description,
      _price,
      _region,
      _duration,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.id == null
        ? 'Создание товара'
        : 'Редактирование товара';
    if (_loading || _loadError != null) {
      return ShopPage(
        title: title,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : StatusView(message: _loadError!, onRetry: _load),
      );
    }
    final available = _availablePlatforms;
    return ShopForm(
      title: title,
      submitLabel: widget.id == null ? 'Создать' : 'Сохранить',
      onSubmit: _save,
      onSaved: () => context.go('/products'),
      onCancel: () => context.go('/products'),
      actionError: () => context.read<ProductState>().actionError,
      fields: [
        FormInput(
          label: 'Название',
          controller: _name,
          validator: (value) => Validators.text(value, max: 150),
          fieldError: _serverErrors['name'],
          onChanged: (_) => _clearServerError('name'),
        ),
        FormInput(
          label: 'Артикул',
          controller: _sku,
          validator: (value) => Validators.text(value, max: 50),
          fieldError: _serverErrors['sku'],
          onChanged: (_) => _clearServerError('sku'),
        ),
        FormInput(
          label: 'Описание',
          controller: _description,
          maxLines: 4,
          validator: (value) => Validators.text(value, max: 2000),
          fieldError: _serverErrors['description'],
          onChanged: (_) => _clearServerError('description'),
        ),
        DropdownButtonFormField<ProductType>(
          initialValue: _type,
          decoration: InputDecoration(
            labelText: 'Тип товара',
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final type in ProductType.values)
              DropdownMenuItem(value: type, child: Text(productTypeName(type))),
          ],
          validator: (value) =>
              value == null ? 'Выберите тип товара' : _serverErrors['type'],
          onChanged: (value) {
            if (value != null) {
              setState(() => _type = value);
              _clearServerError('type');
            }
          },
        ),
        DropdownButtonFormField<int>(
          key: ValueKey('brand-$_brandId'),
          initialValue: _brandId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Бренд',
            border: const OutlineInputBorder(),
            errorMaxLines: 3,
          ),
          items: [
            for (final item in _brands)
              DropdownMenuItem(value: item.id, child: Text(item.name)),
            if (_brandId != null && !_brands.any((item) => item.id == _brandId))
              DropdownMenuItem(
                value: _brandId,
                child: const Text('Недоступный бренд'),
              ),
          ],
          validator: (value) => !_brands.any((item) => item.id == value)
              ? 'Выберите активный бренд'
              : _serverErrors['brandId'],
          onChanged: (value) {
            setState(() {
              _brandId = value;
              _serverErrors = Map.of(_serverErrors)..remove('brandId');
              if (!_availablePlatforms.any((item) => item.id == _platformId)) {
                _platformId = null;
              }
            });
          },
        ),
        DropdownButtonFormField<int>(
          key: ValueKey('platform-$_brandId-$_platformId'),
          initialValue: _platformId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Платформа',
            border: const OutlineInputBorder(),
            errorMaxLines: 3,
            helperText: available.isEmpty
                ? 'Выберите бренд с доступными платформами'
                : null,
          ),
          items: [
            for (final item in available)
              DropdownMenuItem(value: item.id, child: Text(item.name)),
            if (_platformId != null &&
                !available.any((item) => item.id == _platformId))
              DropdownMenuItem(
                value: _platformId,
                child: const Text('Недоступная платформа'),
              ),
          ],
          validator: (value) => !available.any((item) => item.id == value)
              ? 'Выберите платформу выбранного бренда'
              : _serverErrors['platformId'],
          onChanged: (value) {
            setState(() {
              _platformId = value;
              _serverErrors = Map.of(_serverErrors)..remove('platformId');
            });
          },
        ),
        FormField<List<int>>(
          initialValue: _categoryIds,
          validator: (value) =>
              Validators.choices(value) ??
              (value!.any((id) => !_categories.any((item) => item.id == id))
                  ? 'Уберите недоступные категории'
                  : _serverErrors['categoryIds']),
          builder: (field) => InputDecorator(
            decoration: InputDecoration(
              labelText: 'Категории',
              border: const OutlineInputBorder(),
              errorText: field.errorText,
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_categories.isEmpty)
                  const Text('Сначала создайте категорию'),
                for (final item in _categories)
                  FilterChip(
                    label: Text(item.name),
                    selected: _categoryIds.contains(item.id),
                    onSelected: (selected) {
                      final next = [..._categoryIds];
                      if (selected) {
                        next.add(item.id);
                      } else {
                        next.remove(item.id);
                      }
                      field.didChange(next);
                      setState(() {
                        _categoryIds = next;
                        _serverErrors = Map.of(_serverErrors)
                          ..remove('categoryIds');
                      });
                    },
                  ),
                for (final id in _categoryIds.where(
                  (id) => !_categories.any((item) => item.id == id),
                ))
                  FilterChip(
                    label: Text('Недоступная категория № $id'),
                    selected: true,
                    onSelected: (_) {
                      final next = [..._categoryIds]..remove(id);
                      field.didChange(next);
                      setState(() {
                        _categoryIds = next;
                        _serverErrors = Map.of(_serverErrors)
                          ..remove('categoryIds');
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
        FormInput(
          label: 'Цена, ₽',
          controller: _price,
          validator: Validators.price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          fieldError: _serverErrors['price'],
          onChanged: (_) => _clearServerError('price'),
        ),
        FormInput(
          label: 'Регион активации',
          controller: _region,
          validator: (value) => Validators.text(value),
          fieldError: _serverErrors['region'],
          onChanged: (_) => _clearServerError('region'),
        ),
        if (_type == ProductType.aiSubscription)
          FormInput(
            key: const ValueKey('duration'),
            label: 'Срок подписки, месяцев',
            controller: _duration,
            validator: (value) => Validators.integer(value, max: 120),
            keyboardType: TextInputType.number,
            fieldError: _serverErrors['durationMonths'],
            onChanged: (_) => _clearServerError('durationMonths'),
          ),
      ],
    );
  }
}
