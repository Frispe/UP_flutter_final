import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });

  final String label;
  final Widget Function(T item) build;
  final String? sortField;
  final bool numeric;
}

class EntityTable<T> extends StatefulWidget {
  const EntityTable({
    super.key,
    required this.items,
    required this.columns,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.onSelectAll,
    this.canSelect,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
  });

  final List<T> items;
  final List<TableColumnSpec<T>> columns;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final ValueChanged<bool>? onSelectAll;
  final bool Function(T item)? canSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field, bool ascending)? onSort;
  final List<Widget> Function(T item)? actions;

  @override
  State<EntityTable<T>> createState() => _EntityTableState<T>();
}

class _EntityTableState<T> extends State<EntityTable<T>> {
  final _vertical = ScrollController();
  final _horizontal = ScrollController();

  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  Widget _cards(BuildContext context) {
    final selectable = widget.items.where((item) => widget.canSelect?.call(item) ?? true).toList();
    final selectedCount = selectable.where((item) => widget.selected.contains(widget.idOf(item))).length;
    final sortColumns = widget.columns.where((column) => column.sortField != null).toList();
    return ListView(
      key: const PageStorageKey('cards'),
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        if (sortColumns.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            key: ValueKey(widget.sortField),
            initialValue: widget.sortField,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Сортировать по',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final column in sortColumns)
                DropdownMenuItem(value: column.sortField, child: Text(column.label)),
            ],
            onChanged: widget.onSort == null ? null : (value) {
              if (value != null) widget.onSort!(value, widget.sortAscending);
            },
          ),
          TextButton(
            onPressed: widget.onSort == null || widget.sortField == null ? null : () {
              widget.onSort!(widget.sortField!, !widget.sortAscending);
            },
            child: Text(widget.sortAscending ? 'По возрастанию ↑' : 'По убыванию ↓'),
          ),
        ],
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Выбрать все на странице'),
          tristate: true,
          value: selectedCount == 0 ? false : selectedCount == selectable.length ? true : null,
          onChanged: widget.onSelectAll == null || selectable.isEmpty
              ? null : (_) => widget.onSelectAll!(selectedCount != selectable.length),
        ),
        for (final item in widget.items)
          Card(
            key: ValueKey(widget.idOf(item)),
            margin: const EdgeInsets.only(bottom: 12),
            color: widget.selected.contains(widget.idOf(item))
                ? Theme.of(context).colorScheme.secondaryContainer : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text('Запись № ${widget.idOf(item)}'),
                    value: widget.selected.contains(widget.idOf(item)),
                    onChanged: widget.onToggleSelect == null || !(widget.canSelect?.call(item) ?? true)
                        ? null : (_) => widget.onToggleSelect!(widget.idOf(item)),
                  ),
                  for (final column in widget.columns)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(column.label, style: Theme.of(context).textTheme.labelMedium),
                          const SizedBox(height: 2),
                          column.build(item),
                        ],
                      ),
                    ),
                  if (widget.actions != null)
                    Wrap(spacing: 8, runSpacing: 8, children: widget.actions!(item)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortIndex = widget.sortField == null
        ? -1
        : widget.columns.indexWhere((column) => column.sortField == widget.sortField);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (MediaQuery.sizeOf(context).width < 600) return _cards(context);
        return Scrollbar(
          controller: _horizontal,
          thumbVisibility: true,
          notificationPredicate: (notification) => notification.depth == 0,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Scrollbar(
                controller: _vertical,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _vertical,
                  child: DataTable(
                    columnSpacing: 24,
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 88,
                    showCheckboxColumn: widget.onToggleSelect != null,
                    onSelectAll: widget.onSelectAll == null
                        ? null
                        : (value) => widget.onSelectAll!(value ?? false),
                    sortColumnIndex: sortIndex < 0 ? null : sortIndex,
                    sortAscending: widget.sortAscending,
                    columns: [
                      for (final column in widget.columns)
                        DataColumn(
                          label: Text(column.label),
                          numeric: column.numeric,
                          onSort: column.sortField == null || widget.onSort == null
                              ? null
                              : (index, ascending) =>
                                  widget.onSort!(column.sortField!, ascending),
                        ),
                      if (widget.actions != null)
                        const DataColumn(label: Text('Действия')),
                    ],
                    rows: [
                      for (final item in widget.items)
                        DataRow(
                          key: ValueKey(widget.idOf(item)),
                          selected: widget.selected.contains(widget.idOf(item)),
                          onSelectChanged: widget.onToggleSelect == null ||
                                  !(widget.canSelect?.call(item) ?? true)
                              ? null
                              : (value) => widget.onToggleSelect!(widget.idOf(item)),
                          cells: [
                            for (final column in widget.columns)
                              DataCell(column.build(item)),
                            if (widget.actions != null)
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: widget.actions!(item),
                              )),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
