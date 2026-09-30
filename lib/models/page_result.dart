class PageResult<T> {
  PageResult({
    required List<T> items,
    required this.page,
    required this.size,
    required this.total,
  }) : assert(page >= 1),
       assert(size > 0),
       assert(total >= 0),
       items = List<T>.unmodifiable(items);

  PageResult.empty({int size = 10})
    : this(items: <T>[], page: 1, size: size, total: 0);

  final List<T> items;
  final int page;
  final int size;
  final int total;

  int get totalPages => total == 0 ? 1 : (total / size).ceil();
  bool get hasPrevious => page > 1;
  bool get hasNext => page < totalPages;
}
