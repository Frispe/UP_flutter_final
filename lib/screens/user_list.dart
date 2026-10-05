import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart' as model;
import '../models/query.dart';
import '../state/user_state.dart';
import '../widgets/catalog_list.dart';
import '../widgets/entity_table.dart';

class UserList extends StatelessWidget {
  const UserList({super.key, required this.onQueryChanged});
  final ValueChanged<Query> onQueryChanged;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<UserState>();
    return CatalogList<model.User>(
      path: '/users',
      title: 'Пользователи',
      query: state.query,
      result: state.result,
      status: state.status,
      error: state.error,
      saving: state.saving,
      selected: state.selected,
      idOf: (item) => item.id,
      nameOf: (item) => item.name,
      deletedOf: (item) => item.isDeleted,
      onQueryChanged: onQueryChanged,
      load: state.load,
      toggle: state.toggleSelection,
      selectAll: state.selectAll,
      clearSelection: state.clearSelection,
      deleteSelected: state.deleteSelected,
      softDelete: state.softDelete,
      hardDelete: state.hardDelete,
      restore: state.restore,
      currentQuery: () => state.query,
      actionError: () => state.actionError,
      columns: [
        TableColumnSpec(
          label: 'ID',
          sortField: 'id',
          numeric: true,
          build: (item) => Text('${item.id}'),
        ),
        TableColumnSpec(
          label: 'Имя',
          sortField: 'name',
          build: (item) => SizedBox(
            width: 200,
            child: Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        TableColumnSpec(
          label: 'Почта',
          sortField: 'email',
          build: (item) => Text(item.email),
        ),
        TableColumnSpec(
          label: 'Никнейм',
          sortField: 'nickname',
          build: (item) => Text(item.nickname),
        ),
        TableColumnSpec(
          label: 'Статус',
          build: (item) => Text(item.isDeleted ? 'Удалён' : 'Активен'),
        ),
      ],
    );
  }
}
