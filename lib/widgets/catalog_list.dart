import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/query.dart';
import '../models/page_result.dart';
import '../state/status.dart';
import '../state/auth_state.dart';
import '../query_url.dart';
import 'entity_table.dart';
import 'pagination.dart';
import 'record_action.dart';
import 'search_field.dart';
import 'shop_page.dart';
import 'status_view.dart';

class CatalogList<T> extends StatelessWidget {
  const CatalogList({
    super.key,
    required this.path,
    required this.title,
    required this.query,
    required this.result,
    required this.status,
    required this.error,
    required this.saving,
    required this.selected,
    required this.idOf,
    required this.nameOf,
    required this.deletedOf,
    required this.columns,
    required this.onQueryChanged,
    required this.load,
    required this.toggle,
    required this.selectAll,
    required this.clearSelection,
    required this.deleteSelected,
    required this.softDelete,
    required this.hardDelete,
    required this.restore,
    required this.currentQuery,
    required this.actionError,
  });
  final String path, title;
  final Query query;
  final PageResult<T> result;
  final LoadStatus status;
  final String? error;
  final bool saving;
  final Set<int> selected;
  final int Function(T) idOf;
  final String Function(T) nameOf;
  final bool Function(T) deletedOf;
  final List<TableColumnSpec<T>> columns;
  final ValueChanged<Query> onQueryChanged;
  final Future<void> Function() load;
  final ValueChanged<int> toggle;
  final ValueChanged<bool> selectAll;
  final VoidCallback clearSelection;
  final Future<bool> Function() deleteSelected;
  final Future<bool> Function(int) softDelete, hardDelete, restore;
  final Query Function() currentQuery;
  final String? Function() actionError;

  @override
  Widget build(BuildContext context) {
    void change(String title, String message, Future<bool> Function() action) {
      changeRecord(
        context,
        title: title,
        message: message,
        action: action,
        currentQuery: currentQuery,
        actionError: actionError,
      );
    }

    final isAdmin = context.watch<AuthState>().role == 'admin';
    final users = path == '/users';
    final filter = users ? query.hasCartItems : query.hasProducts;
    final pager = Pagination(
      page: result.page,
      size: result.size,
      total: result.total,
      enabled: !saving && status != LoadStatus.loading,
      onPageChanged: (page) => onQueryChanged(query.copyWith(page: page)),
      onSizeChanged: (size) => onQueryChanged(query.copyWith(size: size)),
    );
    return ShopPage(
      title: title,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: saving ? null : () => context.go('$path/new'),
              child: const Text('Добавить'),
            ),
          ),
          const SizedBox(height: 12),
          SearchField(
            value: query.search,
            label: users
                ? 'Поиск по имени, почте или никнейму'
                : 'Поиск по названию',
            onChanged: (value) => onQueryChanged(query.copyWith(search: value)),
          ),
          DropdownButtonFormField<String>(
            key: ValueKey(filter),
            initialValue: filter?.toString() ?? 'all',
            decoration: InputDecoration(
              labelText: users ? 'Содержимое корзины' : 'Наличие товаров',
            ),
            items: [
              const DropdownMenuItem(value: 'all', child: Text('Все записи')),
              DropdownMenuItem(
                value: 'true',
                child: Text(users ? 'Корзина с товарами' : 'С товарами'),
              ),
              DropdownMenuItem(
                value: 'false',
                child: Text(users ? 'Пустая корзина' : 'Без товаров'),
              ),
            ],
            onChanged: saving
                ? null
                : (value) => onQueryChanged(
                    users
                        ? query.copyWith(
                            hasCartItems: value == 'true',
                            clearHasCartItems: value == 'all',
                          )
                        : query.copyWith(
                            hasProducts: value == 'true',
                            clearHasProducts: value == 'all',
                          ),
                  ),
          ),
          if (isAdmin)
            Row(
              children: [
                Checkbox(
                  value: query.includeDeleted,
                  onChanged: saving
                      ? null
                      : (value) => onQueryChanged(
                          query.copyWith(includeDeleted: value ?? false),
                        ),
                ),
                const Flexible(child: Text('Показывать удалённые')),
              ],
            ),
          if (status == LoadStatus.success)
            Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Всего: ${result.total}. Выбрано: ${selected.length}'),
                if (selected.isNotEmpty) ...[
                  TextButton(
                    onPressed: saving ? null : clearSelection,
                    child: const Text('Снять выделение'),
                  ),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () => change(
                            'Удалить выбранные?',
                            'Выбрано: ${selected.length}. Записи можно будет восстановить.',
                            deleteSelected,
                          ),
                    child: const Text('Удалить выбранные'),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 8),
          Expanded(
            child: switch (status) {
              LoadStatus.idle || LoadStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              LoadStatus.error => StatusView(
                message: error ?? 'Не удалось загрузить список',
                onRetry: load,
              ),
              LoadStatus.empty => const StatusView(
                message: 'Записи не найдены',
              ),
              LoadStatus.success => EntityTable<T>(
                items: result.items,
                columns: columns,
                idOf: idOf,
                selected: selected,
                canSelect: (item) => !deletedOf(item),
                onToggleSelect: saving ? null : toggle,
                onSelectAll: saving ? null : selectAll,
                sortField: query.sortField,
                sortAscending: query.sortAscending,
                onSort: saving
                    ? null
                    : (field, ascending) => onQueryChanged(
                        query.copyWith(
                          sortField: field,
                          sortAscending: ascending,
                        ),
                      ),
                actions: (item) => [
                  TextButton(
                    onPressed: () =>
                        context.go(queryUrl('$path/${idOf(item)}', query)),
                    child: const Text('Открыть'),
                  ),
                  if (!deletedOf(item)) ...[
                    TextButton(
                      onPressed: saving
                          ? null
                          : () => context.go('$path/${idOf(item)}/edit'),
                      child: const Text('Изменить'),
                    ),
                    TextButton(
                      onPressed: saving
                          ? null
                          : () => change(
                              'Удалить запись?',
                              nameOf(item),
                              () => softDelete(idOf(item)),
                            ),
                      child: const Text('Удалить'),
                    ),
                  ] else if (isAdmin) ...[
                    TextButton(
                      onPressed: saving
                          ? null
                          : () => change(
                              'Восстановить запись?',
                              nameOf(item),
                              () => restore(idOf(item)),
                            ),
                      child: const Text('Восстановить'),
                    ),
                    TextButton(
                      onPressed: saving
                          ? null
                          : () => change(
                              'Удалить навсегда?',
                              users
                                  ? '${nameOf(item)}. Корзина пользователя тоже будет удалена.'
                                  : '${nameOf(item)}. Восстановление будет невозможно.',
                              () => hardDelete(idOf(item)),
                            ),
                      child: const Text('Удалить навсегда'),
                    ),
                  ],
                ],
              ),
            },
          ),
          if (status == LoadStatus.success || status == LoadStatus.empty) pager,
        ],
      ),
    );
  }
}
