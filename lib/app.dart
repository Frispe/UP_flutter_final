import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'router.dart';
import 'screens/login.dart';
import 'state/auth_state.dart';

class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
    );
    if (!auth.signedIn) {
      return MaterialApp(
        title: 'Digital Shop',
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const LoginScreen(),
      );
    }
    return MaterialApp.router(
      title: 'Digital Shop',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: router,
    );
  }
}
