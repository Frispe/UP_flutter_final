import 'models/product.dart';
import 'models/query.dart';

int? _number(Map<String, String> values, String name, {int minimum = 0}) {
  if (!values.containsKey(name)) return null;
  final number = int.tryParse(values[name]!);
  if (number == null || number < minimum || number > 9007199254740991) {
    throw FormatException('Некорректный параметр $name');
  }
  return number;
}

int? _price(Map<String, String> values, String name) {
  if (!values.containsKey(name)) return null;
  final text = values[name]!.replaceAll(',', '.');
  if (!RegExp(r'^\d{1,12}(\.\d{1,2})?$').hasMatch(text)) {
    throw FormatException('Некорректная цена в параметре $name');
  }
  final parts = text.split('.');
  return int.parse(parts[0]) * 100 +
      (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
}

Query readQuery(Uri uri, {required bool brands}) {
  final values = uri.queryParameters;
  final fields = brands ? ['name', 'id', 'productCount'] : ['name', 'sku', 'price'];
  final sort = (values['sort'] ?? 'name,asc').split(',');
  if (sort.length != 2 || !fields.contains(sort[0]) ||
      !['asc', 'desc'].contains(sort[1])) {
    throw const FormatException('Некорректные параметры сортировки');
  }
  final size = _number(values, 'size', minimum: 1) ?? 10;
  if (![10, 25, 50].contains(size)) {
    throw const FormatException('Размер страницы должен быть 10, 25 или 50');
  }
  final deleted = values['includeDeleted'] ?? 'false';
  if (!['true', 'false'].contains(deleted)) {
    throw const FormatException('includeDeleted должен быть true или false');
  }
  ProductType? type;
  if (!brands && values.containsKey('type')) {
    for (final value in ProductType.values) {
      if (value.name == values['type']) type = value;
    }
    if (type == null) throw const FormatException('Неизвестный тип товара');
  }
  final priceFrom = brands ? null : _price(values, 'priceFrom');
  final priceTo = brands ? null : _price(values, 'priceTo');
  if (priceFrom != null && priceTo != null && priceFrom > priceTo) {
    throw const FormatException('Цена от не должна превышать цену до');
  }
  return Query(
    search: values['search'] ?? '',
    type: type,
    brandId: brands ? null : _number(values, 'brandId', minimum: 1),
    priceFrom: priceFrom,
    priceTo: priceTo,
    sortField: sort[0],
    sortAscending: sort[1] == 'asc',
    page: _number(values, 'page', minimum: 1) ?? 1,
    size: size,
    includeDeleted: deleted == 'true',
  );
}

String queryUrl(String path, Query query) {
  String price(int value) => '${value ~/ 100}.${(value % 100).toString().padLeft(2, '0')}';
  final brands = path.startsWith('/brands');
  return Uri(
    path: path,
    queryParameters: {
      if (query.search.isNotEmpty) 'search': query.search,
      if (!brands && query.type != null) 'type': query.type!.name,
      if (!brands && query.brandId != null) 'brandId': '${query.brandId}',
      if (!brands && query.priceFrom != null) 'priceFrom': price(query.priceFrom!),
      if (!brands && query.priceTo != null) 'priceTo': price(query.priceTo!),
      'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
      'page': '${query.page}',
      'size': '${query.size}',
      if (query.includeDeleted) 'includeDeleted': 'true',
    },
  ).toString();
}
