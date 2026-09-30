import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models/brand.dart';
import '../models/product.dart';
import '../models/query.dart';
import '../state/brand_state.dart';
import 'search_field.dart';

class ProductFilters extends StatefulWidget {
  const ProductFilters({
    super.key,
    required this.query,
    required this.onChanged,
  });

  final Query query;
  final ValueChanged<Query> onChanged;

  @override
  State<ProductFilters> createState() => _ProductFiltersState();
}

class _ProductFiltersState extends State<ProductFilters> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _from;
  late final TextEditingController _to;
  late Future<List<Brand>> _brands;
  int _searchVersion = 0;

  String _priceText(int? value) {
    return value == null ? '' : '${value ~/ 100}.${(value % 100).toString().padLeft(2, '0')}';
  }

  int? _parsePrice(String value) {
    final text = value.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d{1,12}(\.\d{1,2})?$').hasMatch(text)) return null;
    final parts = text.split('.');
    final rubles = int.parse(parts[0]);
    final kopecks = parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0'));
    return rubles * 100 + kopecks;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return _parsePrice(value) == null
        ? 'Введите неотрицательную цену: до 12 цифр и 2 знаков после запятой'
        : null;
  }

  @override
  void initState() {
    super.initState();
    _from = TextEditingController(text: _priceText(widget.query.priceFrom));
    _to = TextEditingController(text: _priceText(widget.query.priceTo));
    _brands = context.read<BrandState>().findOptions();
  }

  @override
  void didUpdateWidget(covariant ProductFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query.priceFrom != widget.query.priceFrom) {
      _from.text = _priceText(widget.query.priceFrom);
    }
    if (oldWidget.query.priceTo != widget.query.priceTo) {
      _to.text = _priceText(widget.query.priceTo);
    }
  }

  void _applyPrices() {
    if (!_formKey.currentState!.validate()) return;
    widget.onChanged(widget.query.copyWith(
      priceFrom: _parsePrice(_from.text),
      clearPriceFrom: _from.text.trim().isEmpty,
      priceTo: _parsePrice(_to.text),
      clearPriceTo: _to.text.trim().isEmpty,
    ));
  }

  void _reset() {
    setState(() {
      _searchVersion++;
      _from.clear();
      _to.clear();
    });
    _formKey.currentState!.validate();
    widget.onChanged(widget.query.copyWith(
      search: '',
      clearType: true,
      clearBrand: true,
      clearPriceFrom: true,
      clearPriceTo: true,
    ));
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final fieldWidth = width < 540 ? width : (width - 12) / 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SearchField(
                key: ValueKey(_searchVersion),
                value: widget.query.search,
                label: 'Поиск по названию или артикулу',
                onChanged: (value) => widget.onChanged(
                  widget.query.copyWith(search: value),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('type-${widget.query.type}'),
                      initialValue: widget.query.type?.name ?? '',
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Тип товара', border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('Все типы')),
                        for (final type in ProductType.values)
                          DropdownMenuItem(value: type.name, child: Text(productTypeName(type))),
                      ],
                      onChanged: (value) {
                        final type = value == null || value.isEmpty
                            ? null
                            : ProductType.values.firstWhere((type) => type.name == value);
                        widget.onChanged(widget.query.copyWith(type: type, clearType: type == null));
                      },
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: FutureBuilder<List<Brand>>(
                      future: _brands,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return TextButton(
                            onPressed: () => setState(() {
                              _brands = context.read<BrandState>().findOptions();
                            }),
                            child: const Text('Не удалось загрузить бренды. Повторить'),
                          );
                        }
                        final brands = snapshot.data ?? const <Brand>[];
                        final selected = widget.query.brandId;
                        return DropdownButtonFormField<int>(
                          key: ValueKey('brand-$selected'),
                          initialValue: selected ?? 0,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: snapshot.hasData ? 'Бренд' : 'Загрузка брендов…',
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(value: 0, child: Text('Все бренды')),
                            for (final brand in brands)
                              DropdownMenuItem(value: brand.id, child: Text(brand.name)),
                            if (selected != null && !brands.any((brand) => brand.id == selected))
                              DropdownMenuItem(value: selected, child: Text('Бренд № $selected')),
                          ],
                          onChanged: !snapshot.hasData ? null : (value) {
                            widget.onChanged(widget.query.copyWith(
                              brandId: value,
                              clearBrand: value == null || value == 0,
                            ));
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: TextFormField(
                      controller: _from,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Цена от, ₽', border: OutlineInputBorder(), errorMaxLines: 3,
                      ),
                      validator: _validatePrice,
                      onFieldSubmitted: (_) => _applyPrices(),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: TextFormField(
                      controller: _to,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Цена до, ₽', border: OutlineInputBorder(), errorMaxLines: 3,
                      ),
                      validator: (value) {
                        final error = _validatePrice(value);
                        if (error != null) return error;
                        final from = _parsePrice(_from.text);
                        final to = _parsePrice(value ?? '');
                        if (from != null && to != null && from > to) {
                          return 'Цена до должна быть не меньше цены от';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _applyPrices(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton(onPressed: _applyPrices, child: const Text('Применить цену')),
                  TextButton(onPressed: _reset, child: const Text('Сбросить фильтры')),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
