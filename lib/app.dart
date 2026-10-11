import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'router.dart';
import 'state/auth_state.dart';
import 'state/server_state.dart';
import 'widgets/server_banner.dart';
import 'widgets/session_guard.dart';

class ShopApp extends StatefulWidget {
  const ShopApp({super.key});

  @override
  State<ShopApp> createState() => _ShopAppState();
}

class _ShopAppState extends State<ShopApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(context.read<AuthState>());
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final server = context.watch<ServerState>();
    return MaterialApp.router(
      title: 'Digital Shop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        focusColor: const Color(0x55725CFF),
        hoverColor: const Color(0x22725CFF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF725CFF),
          brightness: Brightness.dark,
          surface: const Color(0xFF191B24),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF171922),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF191B24),
          elevation: 0,
          margin: const EdgeInsets.all(4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFF292C38)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF171922),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF303342)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF303342)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF725CFF), width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF725CFF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      routerConfig: _router,
      builder: (context, child) => _AppBackground(
        child: ServerBanner(
          child: KeyedSubtree(
            key: ValueKey(server.recovery),
            child: SessionGuard(child: child ?? const SizedBox.shrink()),
          ),
        ),
      ),
    );
  }
}

class _AppBackground extends StatelessWidget {
  const _AppBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF101116),
        gradient: RadialGradient(
          center: Alignment(0.9, -0.75),
          radius: 1.15,
          colors: [Color(0x29725CFF), Color(0x00101116)],
          stops: [0, 0.58],
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.95, 0.8),
            radius: 1.1,
            colors: [Color(0x244C8DFF), Color(0x00101116)],
            stops: [0, 0.56],
          ),
        ),
        child: child,
      ),
    );
  }
}
