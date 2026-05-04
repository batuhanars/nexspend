import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_router.dart';

class WalletApp extends StatefulWidget {
  const WalletApp({super.key});

  @override
  State<WalletApp> createState() => _WalletAppState();
}

class _WalletAppState extends State<WalletApp> {
  late final _router = createRouter();

  @override
  void initState() {
    super.initState();
    if (!GetIt.instance.isRegistered<GoRouter>()) {
      GetIt.instance.registerSingleton<GoRouter>(_router);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Wallet App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}
