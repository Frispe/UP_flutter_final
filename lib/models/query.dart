import 'product.dart';

class Query {
  const Query({
    this.search = '',
    this.hasCartItems,
    this.hasProducts,
    this.type,
    this.brandId,
    this.priceFrom,
    this.priceTo,
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  }) : assert(page >= 1),
       assert(size == 10 || size == 25 || size == 50);

  final String search;
  final bool? hasCartItems;
  final bool? hasProducts;
  final ProductType? type;
  final int? brandId;
  final int? priceFrom;
  final int? priceTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  Query copyWith({
    String? search,
    bool? hasCartItems,
    bool clearHasCartItems = false,
    bool? hasProducts,
    bool clearHasProducts = false,
    ProductType? type,
    bool clearType = false,
    int? brandId,
    bool clearBrand = false,
    int? priceFrom,
    int? priceTo,
    bool clearPriceFrom = false,
    bool clearPriceTo = false,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return Query(
      search: search ?? this.search,
      hasCartItems: clearHasCartItems
          ? null
          : (hasCartItems ?? this.hasCartItems),
      hasProducts: clearHasProducts ? null : (hasProducts ?? this.hasProducts),
      type: clearType ? null : (type ?? this.type),
      brandId: clearBrand ? null : (brandId ?? this.brandId),
      priceFrom: clearPriceFrom ? null : (priceFrom ?? this.priceFrom),
      priceTo: clearPriceTo ? null : (priceTo ?? this.priceTo),
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }
}
