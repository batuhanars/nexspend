import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';

const _channelId = 'high_importance_channel_v2';
const _channelName = 'Bildirimler';
const _invitePrefix = 'INVITE:';
const _groupPrefix = 'GROUP:';
const _insightsPayload = 'INSIGHTS';
const _acceptActionId = 'accept_invite';
const _rejectActionId = 'reject_invite';

final _localNotifications = FlutterLocalNotificationsPlugin();
final _inviteController = StreamController<String>.broadcast();
final _actionController =
    StreamController<({String token, String action})>.broadcast();
final _groupNavController = StreamController<String>.broadcast();
final _insightsNavController = StreamController<void>.broadcast();

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

@pragma('vm:entry-point')
void _onNotificationTap(NotificationResponse details) {
  final payload = details.payload;
  if (payload == null) return;

  if (payload.startsWith(_invitePrefix)) {
    final token = payload.substring(_invitePrefix.length);
    final actionId = details.actionId;
    if (actionId == _acceptActionId) {
      _actionController.add((token: token, action: 'accept'));
    } else if (actionId == _rejectActionId) {
      _actionController.add((token: token, action: 'reject'));
    } else {
      _inviteController.add(token);
    }
  } else if (payload.startsWith(_groupPrefix)) {
    final groupId = payload.substring(_groupPrefix.length);
    _groupNavController.add(groupId);
  } else if (payload == _insightsPayload) {
    _insightsNavController.add(null);
  }
}

class NotificationService {
  final ApiClient _apiClient;
  String? _pendingInviteToken;
  String? _pendingGroupId;
  bool _pendingInsights = false;
  bool _initialized = false;

  NotificationService(this._apiClient);

  static Stream<String> get onInvite => _inviteController.stream;
  static Stream<({String token, String action})> get onInviteAction =>
      _actionController.stream;
  static Stream<String> get onGroupNav => _groupNavController.stream;
  static Stream<void> get onInsightsNav => _insightsNavController.stream;

  String? consumePendingInvite() {
    final token = _pendingInviteToken;
    _pendingInviteToken = null;
    return token;
  }

  String? consumePendingGroupId() {
    final id = _pendingGroupId;
    _pendingGroupId = null;
    return id;
  }

  bool consumePendingInsights() {
    final pending = _pendingInsights;
    _pendingInsights = false;
    return pending;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (kDebugMode) {
      print('[FCM] İzin durumu: ${settings.authorizationStatus}');
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

    // Cold start: uygulama kapalıyken bildirime tıklandı
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _processMessage(initial);

    // Arka plan → ön plan: her zaman pending token mekanizması kullan
    FirebaseMessaging.onMessageOpenedApp.listen(_processMessage);

    // Uygulama açıkken gelen bildirim → yerel bildirim göster
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  void _processMessage(RemoteMessage message) {
    final type = message.data['type'] as String?;

    if (type == 'FAMILY_INVITE') {
      final token = message.data['inviteToken'] as String?;
      if (token != null) _pendingInviteToken = token;
    } else if (type == 'INVITE_RESPONSE') {
      final groupId = message.data['groupId'] as String?;
      if (groupId != null) _pendingGroupId = groupId;
    } else if (type == 'MONTHLY_REPORT') {
      _pendingInsights = true;
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final type = message.data['type'] as String?;
    String? payload;
    AndroidNotificationDetails androidDetails;

    if (type == 'FAMILY_INVITE') {
      payload = '$_invitePrefix${message.data['inviteToken'] ?? ''}';
      androidDetails = const AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
        actions: [
          AndroidNotificationAction(
            _acceptActionId,
            'Kabul Et',
            cancelNotification: true,
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            _rejectActionId,
            'Reddet',
            cancelNotification: true,
          ),
        ],
      );
    } else if (type == 'INVITE_RESPONSE') {
      final groupId = message.data['groupId'] as String?;
      payload = groupId != null ? '$_groupPrefix$groupId' : null;
      androidDetails = const AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
      );
    } else if (type == 'MONTHLY_REPORT') {
      payload = _insightsPayload;
      androidDetails = const AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
      );
    } else {
      androidDetails = const AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
      );
    }

    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
        notification.title,
        notification.body,
        NotificationDetails(android: androidDetails),
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) print('[FCM] Local bildirim gösterilemedi: $e');
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
