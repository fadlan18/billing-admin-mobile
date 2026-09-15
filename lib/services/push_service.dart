import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart';

class PushService {
  final Dio _dio;
  PushService(this._dio);

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _localNotifInitialized = false;

  Future<void> initAndRegister() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }

    await _initLocalNotifications();

    final token = await messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    messaging.onTokenRefresh.listen((newToken) {
      _registerToken(newToken);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _showLocalNotification(notification.title ?? '', notification.body ?? '');
      }
    });
  }

  Future<void> _initLocalNotifications() async {
    if (_localNotifInitialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(settings: initSettings);
    _localNotifInitialized = true;
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'billing_admin_channel',
      'Notifikasi Billing Admin',
      channelDescription: 'Notifikasi invoice dan pembayaran',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> _registerToken(String token) async {
    try {
      await _dio.post('/api/admin/devices/register', data: {
        'fcm_token': token,
        'device_info': 'Android',
      });
    } catch (e) {
      // gagal register token tidak boleh menghentikan alur app
    }
  }

  Future<void> unregisterCurrentToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    try {
      await _dio.post('/api/admin/devices/unregister', data: {'fcm_token': token});
    } catch (e) {
      // abaikan
    }
  }
}
