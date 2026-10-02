import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/query.dart';
import '../query_url.dart';

Future<void> changeRecord(
  BuildContext context, {
  required String title,
  required String message,
  required Future<bool> Function() action,
  required Query Function() currentQuery,
  required String? Function() actionError,
}) async {
  final uri = GoRouterState.of(context).uri;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Подтвердить'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  if (GoRouterState.of(context).uri != uri) return;
  final success = await action();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        success
            ? 'Операция выполнена'
            : actionError() ?? 'Не удалось выполнить операцию',
      ),
    ),
  );
  if (success && GoRouterState.of(context).uri == uri) {
    final query = currentQuery();
    final oldPage = int.tryParse(uri.queryParameters['page'] ?? '1');
    if (oldPage != query.page) context.replace(queryUrl(uri.path, query));
  }
}
