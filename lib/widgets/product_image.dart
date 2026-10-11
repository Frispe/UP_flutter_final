import 'dart:convert';

import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.semanticLabel = 'Изображение товара',
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final String semanticLabel;

  Widget _placeholder(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Изображение отсутствует',
      child: ExcludeSemantics(
        child: Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: const Icon(Icons.image_outlined, size: 36),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = imageUrl;
    Widget image;
    if (value == null || value.isEmpty) {
      image = _placeholder(context);
    } else if (value.startsWith('data:') && value.contains(',')) {
      try {
        image = Image.memory(
          base64Decode(value.substring(value.indexOf(',') + 1)),
          width: width,
          height: height,
          fit: BoxFit.cover,
          semanticLabel: semanticLabel,
          errorBuilder: (_, _, _) => _placeholder(context),
        );
      } catch (_) {
        image = _placeholder(context);
      }
    } else {
      image = Image.network(
        value,
        width: width,
        height: height,
        fit: BoxFit.cover,
        semanticLabel: semanticLabel,
        errorBuilder: (_, _, _) => _placeholder(context),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: image,
    );
  }
}
