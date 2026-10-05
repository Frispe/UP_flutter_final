import 'package:go_router/go_router.dart';

import '../form_guard.dart';

import 'package:flutter/material.dart';

import '../state/status.dart';
import 'shop_page.dart';

class ShopForm extends StatefulWidget {
  const ShopForm({
    super.key,
    required this.title,
    required this.fields,
    required this.onSubmit,
    required this.onSaved,
    required this.onCancel,
    this.submitLabel = 'Сохранить',
    this.actionError,
    this.onChanged,
  });

  final String title;
  final List<Widget> fields;
  final Future<bool> Function() onSubmit;
  final VoidCallback onSaved;
  final VoidCallback onCancel;
  final String submitLabel;
  final String? Function()? actionError;
  final VoidCallback? onChanged;

  @override
  State<ShopForm> createState() => _ShopFormState();
}

class _ShopFormState extends State<ShopForm> {
  final _key = GlobalKey<FormState>();
  bool _saving = false;
  bool _submitted = false;
  String? _error;
  bool _dirty = false;
  String? _path;
  Future<bool>? _confirmation;
  late final Future<bool> Function() _check = _confirmExit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final path = GoRouterState.of(context).uri.path;
    if (_path != path) {
      if (_path != null) {
        FormGuard.unregister(_path!, _check);
      }
      _path = path;
      FormGuard.register(path, _check);
    }
  }

  void _changed() {
    if (!_dirty) {
      setState(() => _dirty = true);
    }
    widget.onChanged?.call();
  }

  Future<bool> _confirmExit() async {
    if (!mounted || _saving) {
      return false;
    }
    if (!_dirty) {
      return true;
    }
    return _confirmation ??= _showConfirmation().whenComplete(() {
      _confirmation = null;
    });
  }

  Future<bool> _showConfirmation() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Есть несохранённые изменения'),
        content: const Text('Уйти со страницы и потерять внесённые изменения?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Остаться'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Уйти без сохранения'),
          ),
        ],
      ),
    );
    if (!mounted) {
      return false;
    }
    if (leave == true) {
      setState(() => _dirty = false);
      return true;
    }
    return false;
  }

  Future<void> _cancel() async {
    final leave = await _confirmExit();
    if (mounted && leave) {
      widget.onCancel();
    }
  }

  @override
  void dispose() {
    if (_path != null) {
      FormGuard.unregister(_path!, _check);
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_key.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    var success = false;
    String? error;
    try {
      success = await widget.onSubmit();
      if (!success) {
        error = widget.actionError?.call() ?? 'Не удалось сохранить запись';
      }
    } catch (e) {
      error = errorText(e);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
      _error = error;
      if (success) {
        _dirty = false;
      }
    });
    if (success) {
      widget.onSaved();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _key.currentState?.validate();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !_dirty && !_saving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _cancel();
        }
      },
      child: ShopPage(
        title: widget.title,
        child: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Form(
                key: _key,
                onChanged: _changed,
                autovalidateMode: _submitted
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AbsorbPointer(
                      absorbing: _saving,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final field in widget.fields)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: field,
                            ),
                        ],
                      ),
                    ),
                    if (_saving) const LinearProgressIndicator(),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        FilledButton(
                          onPressed: _saving ? null : _submit,
                          child: Text(
                            _saving ? 'Сохранение…' : widget.submitLabel,
                          ),
                        ),
                        TextButton(
                          onPressed: _saving ? null : _cancel,
                          child: const Text('Отмена'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
