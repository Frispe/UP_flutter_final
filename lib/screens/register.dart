import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();
  final _repeatPassword = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _nickname = TextEditingController();

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    _repeatPassword.dispose();
    _name.dispose();
    _email.dispose();
    _nickname.dispose();
    super.dispose();
  }

  String? _passwordError(String? value) {
    final password = value ?? '';
    if (password.length < 8 ||
        !RegExp(r'\d').hasMatch(password) ||
        !RegExp(r'[^A-Za-zА-Яа-яЁё0-9]').hasMatch(password)) {
      return 'Минимум 8 символов, цифра и специальный знак';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthState>().register(
      username: _login.text,
      password: _password.text,
      name: _name.text,
      email: _email.text,
      nickname: _nickname.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    InputDecoration decoration(String label, String field) => InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      errorText: auth.fieldErrors[field],
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Создание аккаунта', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _name,
                        enabled: !auth.loading,
                        decoration: decoration('Имя', 'name'),
                        validator: (value) => Validators.text(value, min: 2, max: 50),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _email,
                        enabled: !auth.loading,
                        decoration: decoration('Почта', 'email'),
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nickname,
                        enabled: !auth.loading,
                        decoration: decoration('Никнейм', 'nickname'),
                        validator: (value) => Validators.text(value, min: 3, max: 50),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _login,
                        enabled: !auth.loading,
                        decoration: decoration('Логин', 'username'),
                        validator: (value) => Validators.text(value, min: 3, max: 50),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        enabled: !auth.loading,
                        obscureText: true,
                        decoration: decoration('Пароль', 'password'),
                        validator: _passwordError,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _repeatPassword,
                        enabled: !auth.loading,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Повторите пароль',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value != _password.text ? 'Пароли не совпадают' : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      if (auth.error != null) ...[
                        const SizedBox(height: 16),
                        Text(auth.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: auth.loading ? null : _submit,
                        child: auth.loading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Зарегистрироваться'),
                      ),
                      TextButton(
                        onPressed: auth.loading
                            ? null
                            : () => context.go(
                                Uri(
                                  path: '/login',
                                  queryParameters: GoRouterState.of(context)
                                      .uri
                                      .queryParameters,
                                ).toString(),
                              ),
                        child: const Text('Вернуться ко входу'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
