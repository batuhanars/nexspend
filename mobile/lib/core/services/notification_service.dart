import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';

const _channelId = 'high_importance_channel_v2';
const _channelName = 'Bildirimler';
const _invitePrefix = 'INVITE:';

final _localNotifications = FlutterLocalNotificationsPlugin();
final _inviteController = StreamController<String>.broadcast();
final _debugController = StreamController<String>.broadcast();

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

@pragma('vm:entry-point')
void _onNotificationTap(NotificationResponse details) {
  final payload = details.payload;
  if (payload != null && payload.startsWith(_invitePrefix)) {
    _inviteController.add(payload.substring(_invitePrefix.length));
  }
}

class NotificationService {
  final ApiClient _apiClient;
  String? _pendingInviteToken;
  bool _initialized = false;

  NotificationService(this._apiClient);

  static Stream<String> get onInvite => _inviteController.stream;
  static Stream<String> get onDebug => _debugController.stream;

  String? consumePendingInvite() {
    final token = _pendingInviteToken;
    _pendingInviteToken = null;
    return token;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
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

    // Android 13+ local notification izni
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // FCM izni (iOS + Android 13+)
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (kDebugMode) print('[FCM] İzin durumu: ${settings.authorizationStatus}');

    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

    // Uygulama kapalıyken bildirime tıklandı (cold start)
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _processMessage(initial, pending: true);

    // Uygulama arka plandayken bildirime tıklandı
    FirebaseMessaging.onMessageOpenedApp.listen(
      (msg) => _processMessage(msg, pending: false),
    );

    // Uygulama açıkken gelen bildirim → yerel bildirim göster
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      if (notification == null) {
        _debugController.add('onMessage tetiklendi ama notification=null');
        return;
      }

      // DEBUG: onMessage tetiklendiğini onayla
      _debugController.add('onMessage: ${notification.title}');

      final isInvite = message.data['type'] == 'FAMILY_INVITE';
      final payload = isInvite
          ? '$_invitePrefix${message.data['inviteToken']}'
          : null;

      try {
        await _localNotifications.show(
          DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
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
          payload: payload,
        );
        _debugController.add('show() başarılı');
      } catch (e) {
        _debugController.add('show() HATA: $e');
      }
    });
  }

  void _processMessage(RemoteMessage message, {required bool pending}) {
    if (message.data['type'] != 'FAMILY_INVITE') return;
    final token = message.data['inviteToken'] as String?;
    if (token == null) return;
    if (pending) {
      _pendingInviteToken = token;
    } else {
      _inviteController.add(token);
    }
  }

  Future<void> tryRegisterToken() async {
    try {
      String? token;
      for (int i = 0; i < 3; i++) {
        token = await FirebaseMessaging.instance.getToken();
        if (token != null) break;
        await Future.delayed(const Duration(seconds: 2));
      }
      if (kDebugMode) print('[FCM] getToken() sonucu: $token');
      if (token != null) {
        await _registerToken(token);
      } else {
        if (kDebugMode) print('[FCM] Token null — 3 denemede alınamadı.');
      }
    } catch (e) {
      if (kDebugMode) print('[FCM] getToken() hatası: $e');
    }
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
