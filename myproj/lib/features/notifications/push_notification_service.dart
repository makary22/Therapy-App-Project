import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Background message handler - يتم استدعاء هذا عندما يصل إشعار وهو التطبيق مقفول أو في background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message received: ${message.messageId}');
  debugPrint('[FCM] Title: ${message.notification?.title}');
  debugPrint('[FCM] Body: ${message.notification?.body}');
}

class PushNotificationService {
  PushNotificationService._();

  static bool _isInitialized = false;

  /// Initialize FCM and set up message handlers
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;

    // Request notification permissions (Android 13+ و iOS)
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Get FCM token (للـ debug فقط - الـ Cloud Function تستخدم topic subscription)
    final token = await messaging.getToken();
    debugPrint('[FCM] Device Token: $token');

    // Subscribe to daily notifications topic (الـ Cloud Function ترسل للـ topic دا)
    await messaging.subscribeToTopic('daily_notifications');
    debugPrint('[FCM] Subscribed to daily_notifications topic');

    // Listen to foreground messages (لما التطبيق مفتوح)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground message received: ${message.messageId}');
      debugPrint('[FCM] Title: ${message.notification?.title}');
      debugPrint('[FCM] Body: ${message.notification?.body}');

      // يمكنك هنا تحديث UI أو تشغيل صوت إذا كنت تريد
    });

    // Listen to message when app opens from notification (notification tap)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Message opened app: ${message.messageId}');
      debugPrint('[FCM] Title: ${message.notification?.title}');
      debugPrint('[FCM] Body: ${message.notification?.body}');
      // يمكنك هنا navigate لـ screen معين مثلاً
    });

    _isInitialized = true;
    debugPrint('[FCM] Initialize completed');
  }
}
