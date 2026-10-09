import '../widgets/record_action.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../widgets/product_filters.dart';
import '../models/product.dart';
import '../models/query.dart';
import '../query_url.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination.dart';
import '../state/product_state.dart';
import '../state/auth_state.dart';
import '../state/status.dart';
import '../widgets/shop_page.dart';
import '../widgets/status_view.dart';

class ProductList extends StatelessWidget {
  const ProductList({super.key, required this.onQueryChanged});

  final ValueChanged<Query> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProductState>();
    final auth = context.watch<AuthState>();
    final canManage = auth.role == 'manager' || auth.role == 'admin';
    final isAdmin = auth.role == 'admin';
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
        message: state.error ?? 'Не удалось загрузить товары',
        onRetry: state.load,
      ),
      LoadStatus.empty => Column(
        children: [
          const Expanded(child: StatusView(message: 'Товары не найдены')),
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
              if (canManage) Text('Выбрано: ${state.selected.length}'),
              if (canManage && state.hasSelection)
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

              if (canManage && state.hasSelection)
                TextButton(
                  onPressed: state.saving ? null : state.clearSelection,
                  child: const Text('Снять выделение'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: EntityTable<Product>(
              items: state.result.items,
              idOf: (item) => item.id,
              selected: state.selected,
              onToggleSelect: !canManage || state.saving ? null : state.toggleSelection,
              onSelectAll: !canManage || state.saving ? null : state.selectAll,
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
                  label: 'Артикул',
                  sortField: 'sku',
                  build: (item) => Text(item.sku),
                ),
                TableColumnSpec(
                  label: 'Тип',
                  build: (item) => Text(productTypeName(item.type)),
                ),
                TableColumnSpec(
                  label: 'Цена',
                  sortField: 'price',
                  numeric: true,
                  build: (item) => Text(formatPrice(item.price)),
                ),
                TableColumnSpec(
                  label: 'Платформа',
                  build: (item) => Text(state.platformName(item.platformId)),
                ),
                TableColumnSpec(
                  label: 'Статус',
                  build: (item) => Text(item.isDeleted ? 'Удалён' : 'Активен'),
                ),
              ],
              actions: (item) => [
                if (canManage && !item.isDeleted)
                  TextButton(
                    onPressed: state.saving
                        ? null
                        : () => context.go('/products/${item.id}/edit'),
                    child: const Text('Изменить'),
                  ),
                TextButton(
                  onPressed: () =>
                      context.go(queryUrl('/products/${item.id}', state.query)),
                  child: const Text('Открыть'),
                ),
                if (canManage && !item.isDeleted)
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
                if (isAdmin && item.isDeleted) ...[
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
      title: 'Каталог товаров',
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              if (canManage)
                Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  onPressed: state.saving
                      ? null
                      : () => context.go('/products/new'),
                  child: const Text('Добавить товар'),
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight * 0.55,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: MediaQuery.sizeOf(context).width < 600
                        ? ExpansionTile(
                            title: const Text('Поиск и фильтры'),
                            maintainState: true,
                            children: [
                              ProductFilters(
                                query: state.query,
                                onChanged: onQueryChanged,
                              ),
                            ],
                          )
                        : ProductFilters(
                            query: state.query,
                            onChanged: onQueryChanged,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (isAdmin) deletedSwitch,
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}
