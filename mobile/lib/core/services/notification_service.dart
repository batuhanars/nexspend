import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _registerToken(token);
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
        '/users/me/fcm-token',
        data: {'fcmToken': token},
      );
    } catch (_) {
      // Token kaydedilemezse sessizce geç — sonraki açılışta tekrar dener
    }
  }
}
