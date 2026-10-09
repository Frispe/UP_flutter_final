import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';

class SessionGuard extends StatefulWidget {
  const SessionGuard({super.key, required this.child});

  final Widget child;

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard> {
  static const _idleLimit = Duration(minutes: 3);
  static const _warningBefore = Duration(seconds: 30);
  static const _sessionLimit = Duration(minutes: 30);

  AuthState? _auth;
  Timer? _timer;
  DateTime _lastActivity = DateTime.now();
  bool _warningOpen = false;
  bool _expiring = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthState>();
    if (identical(auth, _auth)) return;
    _auth?.removeListener(_authChanged);
    _auth = auth..addListener(_authChanged);
    _authChanged();
  }

  void _authChanged() {
    final auth = _auth;
    if (auth == null || !auth.signedIn) {
      _timer?.cancel();
      _timer = null;
      _warningOpen = false;
      _expiring = false;
      return;
    }
    if (_timer != null) return;
    _lastActivity = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _check());
  }

  void _activity([PointerEvent? event]) {
    if (_auth?.signedIn != true || _warningOpen) return;
    _lastActivity = DateTime.now();
  }

  Future<void> _check() async {
    final auth = _auth;
    if (auth == null || !auth.signedIn || _expiring) return;
    final now = DateTime.now();
    final startedAt = auth.sessionStartedAt ?? now;
    if (now.difference(startedAt) >= _sessionLimit) {
      await _expire('Максимальное время сеанса истекло. Войдите снова.');
      return;
    }
    final idle = now.difference(_lastActivity);
    if (idle >= _idleLimit) {
      await _expire('Сеанс завершён из-за отсутствия активности.');
      return;
    }
    if (idle >= _idleLimit - _warningBefore && !_warningOpen) {
      _showWarning();
    }
  }

  Future<void> _showWarning() async {
    if (!mounted || _warningOpen) return;
    _warningOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Сеанс скоро завершится'),
        content: const Text(
          'Активность не обнаружена. Через 30 секунд будет выполнен выход.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              _lastActivity = DateTime.now();
              _warningOpen = false;
              Navigator.pop(dialogContext);
            },
            child: const Text('Продолжить работу'),
          ),
        ],
      ),
    );
    _warningOpen = false;
  }

  Future<void> _expire(String message) async {
    if (_expiring) return;
    _expiring = true;
    if (_warningOpen && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _warningOpen = false;
    }
    await _auth?.expireSession(message);
    _expiring = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _auth?.removeListener(_authChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        _activity();
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onHover: _activity,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _activity,
          onPointerSignal: _activity,
          child: widget.child,
        ),
      ),
    );
  }
}
