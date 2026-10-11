import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../state/auth_state.dart';
import '../widgets/shop_page.dart';
import '../widgets/status_view.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<Map<String, dynamic>> _items = [];
  String? _error;
  bool _loading = true;
  int? _savingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await guard(
        () => context.read<Dio>().get(
          '/accounts',
          queryParameters: {'page': 1, 'size': 100, 'sort': 'name,asc'},
        ),
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      if (!mounted) return;
      setState(() {
        _items = (data['items'] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _loading = false;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        _error = exception is ApiException ? exception.message : '$exception';
        _loading = false;
      });
    }
  }

  Future<void> _changeRole(Map<String, dynamic> item, String role) async {
    final id = item['id'] as int;
    setState(() => _savingId = id);
    try {
      final response = await guard(
        () => context.read<Dio>().patch(
          '/accounts/$id/role',
          data: {'role': role},
        ),
      );
      final changed = Map<String, dynamic>.from(response.data as Map);
      if (!mounted) return;
      setState(() {
        final index = _items.indexWhere((value) => value['id'] == id);
        if (index >= 0) _items[index] = changed;
      });
    } catch (exception) {
      if (!mounted) return;
      final message = exception is ApiException
          ? exception.message
          : '$exception';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _savingId = null);
    }
  }

  String _roleName(String role) => switch (role) {
    'admin' => 'Администратор',
    'manager' => 'Менеджер',
    _ => 'Покупатель',
  };

  @override
  Widget build(BuildContext context) {
    final currentId = context.watch<AuthState>().user?.id;
    return ShopPage(
      title: 'Аккаунты и роли',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? StatusView(message: _error!, onRetry: _load)
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final id = item['id'] as int;
                final role = item['role'] as String;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 520;
                        final details = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] as String? ?? '',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${item['username']} · ${item['email'] ?? ''}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        );
                        final roles = SizedBox(
                          width: compact ? constraints.maxWidth : 190,
                          child: DropdownButtonFormField<String>(
                            initialValue: role,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Роль',
                            ),
                            items: [
                              for (final value in [
                                'customer',
                                'manager',
                                'admin',
                              ])
                                DropdownMenuItem(
                                  value: value,
                                  child: Text(_roleName(value)),
                                ),
                            ],
                            onChanged: id == currentId || _savingId == id
                                ? null
                                : (value) {
                                    if (value != null && value != role) {
                                      _changeRole(item, value);
                                    }
                                  },
                          ),
                        );
                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              details,
                              const SizedBox(height: 12),
                              roles,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: details),
                            const SizedBox(width: 16),
                            roles,
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
