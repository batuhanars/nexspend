import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'core/di/injection.dart';
import 'core/theme/app_palette.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/currency_notifier.dart';
import 'core/utils/locale_notifier.dart';
import 'core/utils/theme_notifier.dart';
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
    getIt<LocaleNotifier>().addListener(_onLocaleChanged);
    getIt<CurrencyNotifier>().addListener(_onCurrencyChanged);
    getIt<ThemeNotifier>().addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    getIt<LocaleNotifier>().removeListener(_onLocaleChanged);
    getIt<CurrencyNotifier>().removeListener(_onCurrencyChanged);
    getIt<ThemeNotifier>().removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onLocaleChanged() => setState(() {});
  void _onCurrencyChanged() => setState(() {});
  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NexSpend',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: getIt<ThemeNotifier>().value,
      routerConfig: _router,
      locale: getIt<LocaleNotifier>().value,
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final palette = isDark ? AppPalette.dark : AppPalette.light;
        final overlay = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: palette.surface,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarDividerColor: palette.surface,
        );
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlay,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
