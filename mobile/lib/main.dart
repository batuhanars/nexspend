import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'core/services/notification_service.dart';
import 'core/storage/secure_storage.dart';
import 'core/utils/currency_notifier.dart';
import 'core/utils/locale_notifier.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Firebase dokümantasyonuna göre runApp öncesi çağrılmalı
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF131313),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await configureDependencies();

  final language = await getIt<SecureStorage>().getLanguage();
  getIt.registerSingleton<LocaleNotifier>(LocaleNotifier(language));

  final currency = await getIt<SecureStorage>().getCurrency();
  getIt.registerSingleton<CurrencyNotifier>(CurrencyNotifier(currency));

  await Future.wait([
    initializeDateFormatting('tr_TR', null),
    initializeDateFormatting('en_US', null),
  ]);

  runApp(const WalletApp());
}
