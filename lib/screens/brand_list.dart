import '../widgets/record_action.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/brand.dart';
import '../models/query.dart';
import '../query_url.dart';
import '../widgets/search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination.dart';
import '../state/brand_state.dart';
import '../state/status.dart';
import '../widgets/shop_page.dart';
import '../widgets/status_view.dart';

class BrandList extends StatelessWidget {
  const BrandList({super.key, required this.onQueryChanged});

  final ValueChanged<Query> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BrandState>();
    void change(String title, String message, Future<bool> Function() action) {
      changeRecord(
        context,
        title: title,
        message: message,
        action: action,
        currentQuery: () => state.query,
        actionError: () => state.actionError,
      );
    }

    final deletedSwitch = Row(
      children: [
        Checkbox(
          value: state.query.includeDeleted,
          onChanged: state.saving
              ? null
              : (value) => onQueryChanged(
                  state.query.copyWith(includeDeleted: value ?? false),
                ),
        ),
        const Flexible(child: Text('Показывать удалённые')),
      ],
    );

    final pagination = Pagination(
      page: state.result.page,
      size: state.result.size,
      total: state.result.total,
      enabled: !state.saving,
      onPageChanged: (page) => onQueryChanged(state.query.copyWith(page: page)),
      onSizeChanged: (size) => onQueryChanged(state.query.copyWith(size: size)),
    );
    final content = switch (state.status) {
      LoadStatus.idle ||
      LoadStatus.loading => const Center(child: CircularProgressIndicator()),
      LoadStatus.error => StatusView(
        message: state.error ?? 'Не удалось загрузить бренды',
        onRetry: state.load,
      ),
      LoadStatus.empty => Column(
        children: [
          const Expanded(child: StatusView(message: 'Бренды не найдены')),
          pagination,
        ],
      ),
      LoadStatus.success => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Показано: ${state.result.items.length} из ${state.result.total}',
              ),
              Text('Выбрано: ${state.selected.length}'),
              if (state.hasSelection)
                FilledButton(
                  onPressed: state.saving
                      ? null
                      : () => change(
                          'Удалить выбранные записи?',
                          'Выбрано записей: ${state.selected.length}. Их можно будет восстановить.',
                          state.deleteSelected,
                        ),
                  child: const Text('Удалить выбранные'),
                ),

              if (state.hasSelection)
                TextButton(
                  onPressed: state.saving ? null : state.clearSelection,
                  child: const Text('Снять выделение'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: EntityTable<Brand>(
              items: state.result.items,
              idOf: (item) => item.id,
              selected: state.selected,
              onToggleSelect: state.saving ? null : state.toggleSelection,
              onSelectAll: state.saving ? null : state.selectAll,
              canSelect: (item) => !item.isDeleted,
              sortField: state.query.sortField,
              sortAscending: state.query.sortAscending,
              onSort: state.saving
                  ? null
                  : (field, ascending) {
                      onQueryChanged(
                        state.query.copyWith(
                          sortField: field,
                          sortAscending: ascending,
                        ),
                      );
                    },
              columns: [
                TableColumnSpec(
                  label: 'ID',
                  sortField: 'id',
                  numeric: true,
                  build: (item) => Text('${item.id}'),
                ),
                TableColumnSpec(
                  label: 'Название',
                  sortField: 'name',
                  build: (item) => SizedBox(
                    width: 220,
                    child: Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                TableColumnSpec(
                  label: 'Товаров',
                  sortField: 'productCount',
                  numeric: true,
                  build: (item) => Text('${state.productCount(item.id)}'),
                ),
                TableColumnSpec(
                  label: 'Статус',
                  build: (item) => Text(item.isDeleted ? 'Удалён' : 'Активен'),
                ),
              ],
              actions: (item) => [
                if (!item.isDeleted)
                  TextButton(
                    onPressed: state.saving
                        ? null
                        : () => context.go('/brands/${item.id}/edit'),
                    child: const Text('Изменить'),
                  ),
                TextButton(
                  onPressed: () =>
                      context.go(queryUrl('/brands/${item.id}', state.query)),
                  child: const Text('Открыть'),
                ),
                if (!item.isDeleted)
                  TextButton(
                    onPressed: state.saving
                        ? null
                        : () => change(
                            'Удалить запись?',
                            '«${item.name}» будет скрыт из обычного списка. Запись можно восстановить.',
                            () => state.softDelete(item.id),
                          ),
                    child: const Text('Удалить'),
                  ),
                if (item.isDeleted) ...[
                  TextButton(
                    onPressed: state.saving
                        ? null
                        : () => change(
                            'Восстановить запись?',
                            '«${item.name}» снова появится в обычном списке.',
                            () => state.restore(item.id),
                          ),
                    child: const Text('Восстановить'),
                  ),
                  TextButton(
                    onPressed: state.saving
                        ? null
                        : () => change(
                            'Удалить навсегда?',
                            '«${item.name}» будет полностью удалён. Восстановление через интерфейс будет невозможно.',
                            () => state.hardDelete(item.id),
                          ),
                    child: const Text('Удалить навсегда'),
                  ),
                ],
              ],
            ),
          ),
          pagination,
        ],
      ),
    };
    return ShopPage(
      title: 'Бренды',
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: () => context.go('/brands/new'),
              child: const Text('Добавить бренд'),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SearchField(
              value: state.query.search,
              label: 'Поиск по названию бренда',
              onChanged: (value) =>
                  onQueryChanged(state.query.copyWith(search: value)),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey(state.query.hasProducts),
            initialValue: state.query.hasProducts?.toString() ?? 'all',
            decoration: const InputDecoration(labelText: 'Наличие товаров'),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Все бренды')),
              DropdownMenuItem(value: 'true', child: Text('С товарами')),
              DropdownMenuItem(value: 'false', child: Text('Без товаров')),
            ],
            onChanged: state.saving
                ? null
                : (value) => onQueryChanged(
                    state.query.copyWith(
                      hasProducts: value == 'true',
                      clearHasProducts: value == 'all',
                    ),
                  ),
          ),
          deletedSwitch,
          Expanded(child: content),
        ],
      ),
    );
  }
}
