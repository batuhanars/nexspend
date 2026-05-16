import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class AdsService {
  static const String _androidBannerUnitId =
      'ca-app-pub-9972490944328521/3011139898';

  // Google test ID'leri — kendi reklamına tıklamak AdMob hesap banı sebebidir.
  // Debug build ve iOS (henüz prod ID yok) her zaman bunları kullanır.
  static const String _testAndroidBannerUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testIosBannerUnitId =
      'ca-app-pub-3940256099942544/2934735716';

  // Reklam gösterimi compile-time flag ile kontrol edilir.
  // Closed testing sırasında kapalı tutulur — test kullanıcısının yanlışlıkla
  // reklama tıklaması AdMob hesap banı sebebidir.
  // Production lansman build'i: flutter build appbundle --release --dart-define=ENABLE_ADS=true
  static const bool _enabled =
      bool.fromEnvironment('ENABLE_ADS', defaultValue: false);

  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isIOS) return _testIosBannerUnitId;
    if (kDebugMode) return _testAndroidBannerUnitId;
    return _androidBannerUnitId;
  }

  static bool get isSupported => _enabled && !kIsWeb;
}
