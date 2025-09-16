import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../features/auth/auth_email_screen.dart';
import '../services/api_service.dart' show ApiService;

/// Показывает либо `child` (приложение), либо экран авторизации —
/// в зависимости от того, есть ли сохранённый токен в SecureStorage.
class AuthGate extends StatefulWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  /// Позволяет потомкам получить состояние [AuthGate] и
  /// инициировать повторную проверку токена.
  static _AuthGateState? of(BuildContext context) =>
      context.findAncestorStateOfType<_AuthGateState>();

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final ok = await ApiService().isLoggedIn();
      if (!mounted) return;
      setState(() {
        _loggedIn = ok;
        _loading = false;
      });
    } catch (e) {
      debugPrint('AuthGate._check error: $e');
      if (!mounted) return;
      setState(() {
        _loggedIn = false;
        _loading = false;
      });
    }
  }

  /// Выполняет повторную проверку токена и обновляет состояние виджета.
  Future<void> refreshAuthState() async {
    setState(() => _loading = true);
    await _check();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _loggedIn ? widget.child : const AuthEmailScreen();
  }
}
