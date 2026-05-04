import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';

const _channelId = 'high_importance_channel';
const _channelName = 'Bildirimler';

final _localNotifications = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  final ApiClient _apiClient;

  NotificationService(this._apiClient);

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

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

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      if (kDebugMode) {
        print(
          '[FCM] Foreground mesaj: ${notification.title} — ${notification.body}',
        );
      }
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
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
