import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart';
import '../main.dart';
import '../models/invoice.dart';
import 'invoice_service.dart';
import '../screens/invoice_detail_screen.dart';

class PushService {
  final Dio _dio;
  PushService(this._dio);

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _localNotifInitialized = false;
  static bool _listenersAttached = false;

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

    if (!_listenersAttached) {
      _listenersAttached = true;

      // App sedang terbuka (foreground)  tampilkan local notification manual
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          _showLocalNotification(notification.title ?? '', notification.body ?? '');
        }
      });

      // App dibuka dari background dengan tap notifikasi
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message.data);
      });

      // App dibuka dari kondisi terminated (dari tap notifikasi)
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage.data);
      }
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final invoiceId = data['invoice_id'] as String?;
    if (invoiceId == null) return;

    final navState = navigatorKey.currentState;
    if (navState == null) return;

    () async {
      try {
        final service = InvoiceService(_dio);
        final json = await service.getInvoiceById(invoiceId);
        if (json == null) return;
        final invoice = Invoice.fromJson(json);
        navState.push(
          MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: invoice)),
        );
      } catch (e) {
        // gagal ambil invoice, abaikan (tidak crash)
      }
    }();
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
