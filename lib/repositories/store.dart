import '../data.dart' as data;
import '../models/brand.dart';
import '../models/page_result.dart';
import '../models/product.dart';
import '../models/query.dart';

class Store {
  final List<Product> products = [...data.products];
  final List<Brand> brands = [...data.brands];

  int nextProductId = data.products.fold<int>(
    0, (largest, item) => item.id > largest ? item.id : largest,
  ) + 1;
  int nextBrandId = data.brands.fold<int>(
    0, (largest, item) => item.id > largest ? item.id : largest,
  ) + 1;
}

void validateQuery(Query query, List<String> sortFields) {
  if (query.page < 1 || ![10, 25, 50].contains(query.size)) {
    throw ArgumentError('Некорректные параметры страницы');
  }
  if (!sortFields.contains(query.sortField)) {
    throw ArgumentError('Неизвестное поле сортировки');
  }
}

PageResult<T> buildPage<T>(List<T> rows, Query query) {
  final total = rows.length;
  final totalPages = total == 0 ? 1 : (total / query.size).ceil();
  final page = query.page > totalPages ? totalPages : query.page;
  final start = (page - 1) * query.size;
  final end = start + query.size > total ? total : start + query.size;
  return PageResult(
    items: rows.sublist(start, end),
    page: page,
    size: query.size,
    total: total,
  );
}
