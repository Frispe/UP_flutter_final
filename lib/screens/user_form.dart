import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../state/user_state.dart';
import '../state/status.dart';
import '../validators.dart';
import '../widgets/form_input.dart';
import '../widgets/shop_form.dart';
import '../widgets/shop_page.dart';
import '../widgets/status_view.dart';

class UserForm extends StatefulWidget {
  const UserForm({super.key, this.id});
  final int? id;
  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _nickname = TextEditingController();
  bool _loading = true;
  String? _loadError;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final state = context.read<UserState>();
      final item = widget.id == null ? null : await state.findById(widget.id!);
      if (widget.id != null && item == null) {
        throw StateError('Пользователь не найден');
      }
      if (item?.isDeleted ?? false) {
        throw StateError('Сначала восстановите пользователя');
      }
      if (!mounted) {
        return;
      }
      _name.text = item?.name ?? '';
      _email.text = item?.email ?? '';
      _nickname.text = item?.nickname ?? '';
      setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = errorText(e);
          _loading = false;
        });
      }
    }
  }

  Future<bool> _save() async {
    final state = context.read<UserState>();
    final exists = await state.emailExists(_email.text, exceptId: widget.id);
    if (!mounted) {
      return false;
    }
    setState(
      () => _emailError = exists
          ? 'Пользователь с такой почтой уже существует'
          : null,
    );
    if (exists) {
      return false;
    }
    final item = User(
      id: widget.id ?? 0,
      name: _name.text,
      email: _email.text,
      nickname: _nickname.text,
    );
    final saved = widget.id == null
        ? await state.create(item)
        : await state.update(item);
    if (!saved &&
        mounted &&
        state.actionError == 'Пользователь с такой почтой уже существует') {
      setState(() => _emailError = state.actionError);
    }
    return saved;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _nickname.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.id == null
        ? 'Создание пользователя'
        : 'Редактирование пользователя';
    if (_loading || _loadError != null) {
      return ShopPage(
        title: title,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : StatusView(message: _loadError!, onRetry: _load),
      );
    }
    void back() =>
        context.go(widget.id == null ? '/users' : '/users/${widget.id}');
    return ShopForm(
      title: title,
      onSubmit: _save,
      onSaved: back,
      onCancel: back,
      submitLabel: widget.id == null ? 'Создать' : 'Сохранить',
      actionError: () => _emailError ?? context.read<UserState>().actionError,
      fields: [
        FormInput(
          label: 'Имя',
          controller: _name,
          validator: (value) => Validators.text(value),
        ),
        FormInput(
          label: 'Почта',
          controller: _email,
          validator: Validators.email,
          keyboardType: TextInputType.emailAddress,
          fieldError: _emailError,
          onChanged: (_) {
            if (_emailError != null) {
              setState(() => _emailError = null);
            }
          },
        ),
        FormInput(
          label: 'Никнейм (необязательно)',
          controller: _nickname,
          validator: (value) =>
              Validators.text(value, max: 50, required: false),
        ),
      ],
    );
  }
}
