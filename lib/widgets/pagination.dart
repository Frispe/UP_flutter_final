import 'package:flutter/material.dart';

class Pagination extends StatelessWidget {
  const Pagination({
    super.key,
    required this.page,
    required this.size,
    required this.total,
    required this.onPageChanged,
    required this.onSizeChanged,
    this.enabled = true,
  });

  final int page;
  final int size;
  final int total;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onSizeChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final pages = total == 0 ? 1 : (total / size).ceil();
    final hasPrevious = enabled && page > 1;
    final hasNext = enabled && page < pages;
    final first = total == 0 ? 0 : (page - 1) * size + 1;
    final last = page * size > total ? total : page * size;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Страница $page из $pages · Записи $first–$last из $total'),
          SizedBox(
            width: 145,
            child: DropdownButtonFormField<int>(
              key: ValueKey(size),
              initialValue: size,
              decoration: const InputDecoration(
                labelText: 'На странице',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 10, child: Text('10')),
                DropdownMenuItem(value: 25, child: Text('25')),
                DropdownMenuItem(value: 50, child: Text('50')),
              ],
              onChanged: !enabled
                  ? null
                  : (value) {
                      if (value != null && value != size) onSizeChanged(value);
                    },
            ),
          ),
          TextButton(
            onPressed: hasPrevious ? () => onPageChanged(1) : null,
            child: const Text('Первая'),
          ),
          TextButton(
            onPressed: hasPrevious ? () => onPageChanged(page - 1) : null,
            child: const Text('Предыдущая'),
          ),
          TextButton(
            onPressed: hasNext ? () => onPageChanged(page + 1) : null,
            child: const Text('Следующая'),
          ),
          TextButton(
            onPressed: hasNext ? () => onPageChanged(pages) : null,
            child: const Text('Последняя'),
          ),
        ],
      ),
    );
  }
}
