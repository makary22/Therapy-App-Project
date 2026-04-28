import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message received: ${message.messageId}');
  debugPrint('[FCM] Title: ${message.notification?.title}');
  debugPrint('[FCM] Body: ${message.notification?.body}');
}

class PushNotificationService {
  PushNotificationService._();

  static bool _isInitialized = false;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const int _dailyReminderId = 1101;
  static const String _dailyReminderChannelId = 'daily_reminders';
  static const String _dailyReminderChannelName = 'Daily Reminders';

  /// Initialize FCM and local notifications
  static Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(settings);

    final androidLocal =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Request permissions first, then create channel
    await androidLocal?.requestNotificationsPermission();
    await androidLocal?.requestExactAlarmsPermission();

    await androidLocal?.createNotificationChannel(
      const AndroidNotificationChannel(
        _dailyReminderChannelId,
        _dailyReminderChannelName,
        description: 'Daily reminder notifications selected by the user.',
        importance: Importance.max,
      ),
    );

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;

    // Request notification permissions (Android 13+ & iOS)
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Get FCM token (for debug only)
    final token = await messaging.getToken();
    debugPrint('[FCM] Device Token: $token');

    // Unsubscribe from topic-based daily pushes; reminders are scheduled locally
    await messaging.unsubscribeFromTopic('daily_notifications');
    debugPrint('[FCM] Unsubscribed from daily_notifications topic');

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground message received: ${message.messageId}');
      debugPrint('[FCM] Title: ${message.notification?.title}');
      debugPrint('[FCM] Body: ${message.notification?.body}');
    });

    // Listen when app opens from notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Message opened app: ${message.messageId}');
      debugPrint('[FCM] Title: ${message.notification?.title}');
      debugPrint('[FCM] Body: ${message.notification?.body}');
    });

    _isInitialized = true;
    debugPrint('[FCM] Initialize completed');
  }

  static Future<void> _configureLocalTimezone() async {
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    try {
      // 1. Cancel old reminder first
      await _localNotifications.cancel(_dailyReminderId);

      // 2. Make sure timezone is configured
      await _configureLocalTimezone();

      final now = tz.TZDateTime.now(tz.local);

      // 3. Build next scheduled time correctly
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
        0, // seconds = 0
      );

      // If time already passed today, schedule for tomorrow
      if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      debugPrint('[LocalNotif] Scheduling daily reminder at: $scheduled');

      const androidDetails = AndroidNotificationDetails(
        _dailyReminderChannelId,
        _dailyReminderChannelName,
        channelDescription:
            'Daily reminder notifications selected by the user.',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _localNotifications.zonedSchedule(
        _dailyReminderId,
        'Safe Space 🌿',
        'Your reflection reminder is here. Take a calm minute for yourself.',
        scheduled,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // repeats daily
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      // Log pending notifications for debugging
      final pending = await _localNotifications.pendingNotificationRequests();
      debugPrint(
          '[LocalNotif] ✅ Scheduled! Pending count: ${pending.length}');
      for (final p in pending) {
        debugPrint(
            '[LocalNotif] → ID: ${p.id}, Title: ${p.title}, Body: ${p.body}');
      }
    } catch (e, st) {
      debugPrint('[LocalNotif] scheduleDailyReminder error: $e');
      debugPrint(st.toString());
    }
  }

  static Future<void> showImmediateNotification(
      String title, String body) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        _dailyReminderChannelId,
        _dailyReminderChannelName,
        channelDescription: 'Immediate notification',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
      );
    } catch (e, st) {
      debugPrint('[LocalNotif] showImmediateNotification error: $e');
      debugPrint(st.toString());
    }
  }

  static Future<void> scheduleDailyReminderFromLabel(String label) async {
    final parsed = _parseTimeLabel(label);
    await scheduleDailyReminder(hour: parsed.hour, minute: parsed.minute);
  }

  static TimeOfDay _parseTimeLabel(String value) {
    try {
      final parts = value.trim().split(' ');
      if (parts.length != 2) return const TimeOfDay(hour: 8, minute: 0);

      final hourMinute = parts[0].split(':');
      if (hourMinute.length != 2) return const TimeOfDay(hour: 8, minute: 0);

      int hour = int.parse(hourMinute[0]);
      final minute = int.parse(hourMinute[1]);
      final period = parts[1].toUpperCase();

      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }
}