import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SimpleNotificationManager {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Initialize notifications (basic setup only)
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  static Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();
    return true;
  }

  static Future<void> showTaskNotification(task, convertedAmount, rate) async {
    await showNotification('Task Completed', 'Currency conversion completed');
  }

  static Future<void> scheduleTaskNotification(task) async {
    print('Task notification scheduled');
  }

  static Future<void> cancelTaskNotification(task) async {
    print('Task notification cancelled');
  }

  /// Show simple notification
  static Future<void> showNotification(String title, String body) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'general',
      'General Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(0, title, body, details);
  }
}