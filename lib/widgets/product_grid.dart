import 'package:flutter/material.dart';

import '../models/product.dart';
import 'product_card.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.products,
    required this.onOpen,
    this.shrinkWrap = false,
    this.physics,
  });

  final List<Product> products;
  final ValueChanged<Product> onOpen;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1080
            ? 4
            : width >= 720
            ? 3
            : width >= 480
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: physics,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: columns == 1 ? 1.08 : 0.73,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(
              product: product,
              onOpen: () => onOpen(product),
            );
          },
        );
      },
    );
  }
}
