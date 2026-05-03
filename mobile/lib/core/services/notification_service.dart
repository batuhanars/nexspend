import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Arka planda gelen mesajlar OS tarafından otomatik gösterilir.
  // Burada sadece veri mesajları için ek işlem yapılabilir.
}

class NotificationService {
  final ApiClient _apiClient;

  NotificationService(this._apiClient);

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print('[FCM] İzin durumu: ${settings.authorizationStatus}');
    }

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      if (kDebugMode) print('[FCM] Bildirim izni reddedildi, token alınmıyor.');
      return;
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (kDebugMode) print('[FCM] getToken() sonucu: $token');
      if (token != null) {
        await _registerToken(token);
      } else {
        if (kDebugMode) {
          print(
            '[FCM] Token null — emülatörde Google Play Services olmayabilir.',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('[FCM] getToken() hatası: $e');
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

    // Foreground mesajlar — uygulama açıkken bildirim gelirse
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print(
          '[FCM] Foreground mesaj: ${message.notification?.title} — ${message.notification?.body}',
        );
      }
    });
  }

  Future<void> _registerToken(String token) async {
    try {
      await _apiClient.dio.patch(
        ApiEndpoints.meFcmToken,
        data: {'fcmToken': token},
      );
      if (kDebugMode) print('[FCM] Token backend\'e kaydedildi.');
    } catch (e) {
      if (kDebugMode) print('[FCM] Token kaydedilemedi: $e');
    }
  }
}
