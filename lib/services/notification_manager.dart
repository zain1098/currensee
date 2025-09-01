import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:async';
import '../models/task_model.dart';

class NotificationManager {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Initialize notifications
  static Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Android settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialize settings
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  // Request permissions
  static Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final androidGranted =
        await _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();

    final iosGranted = await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return (androidGranted ?? false) || (iosGranted ?? false);
  }

  // Schedule a task notification
  static Future<void> scheduleTaskNotification(Task task) async {
    if (!_initialized) await initialize();

    try {
      print('🔔 Scheduling notification for task: ${task.taskName}');
      
      // Calculate next execution time
      final nextExecution = _calculateNextExecution(task);
      if (nextExecution == null) {
        print('❌ Could not calculate next execution time for task: ${task.taskName}');
        return;
      }

      print('📅 Next execution time: $nextExecution');

      // Create notification details
      const androidDetails = AndroidNotificationDetails(
        'currency_tasks',
        'Currency Tasks',
        channelDescription: 'Notifications for currency conversion tasks',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
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

      // Cancel any existing notification for this task
      await _notifications.cancel(task.id.hashCode);

      // Schedule notification
      await _notifications.zonedSchedule(
        task.id.hashCode, // Use hash code as notification ID
        'Currency Task: ${task.taskName}',
        'Time to check ${task.amount} ${task.fromCurrency} to ${task.toCurrency}',
        tz.TZDateTime.from(nextExecution, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: _getDateTimeComponents(task.frequency),
      );

      print('✅ Notification scheduled successfully for task: ${task.taskName}');
      
      // Verify the notification was scheduled
      final pending = await getPendingNotifications();
      final isScheduled = pending.any((notification) => notification.id == task.id.hashCode);
      print('🔍 Notification verification: ${isScheduled ? 'Scheduled' : 'Not scheduled'}');
      
    } catch (e) {
      print('❌ Failed to schedule notification for task ${task.taskName}: $e');
    }
  }

  // Cancel a task notification
  static Future<void> cancelTaskNotification(Task task) async {
    if (!_initialized) await initialize();
    await _notifications.cancel(task.id.hashCode);
  }

  // Show immediate notification
  static Future<void> showTaskNotification(
    Task task,
    double convertedAmount,
    double rate,
  ) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'currency_tasks',
      'Currency Tasks',
      channelDescription: 'Notifications for currency conversion tasks',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
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

    await _notifications.show(
      task.id.hashCode,
      'Currency Conversion Complete',
      '${task.amount} ${task.fromCurrency} = ${convertedAmount.toStringAsFixed(2)} ${task.toCurrency} (Rate: ${rate.toStringAsFixed(4)})',
      details,
    );
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    if (!_initialized) await initialize();
    await _notifications.cancelAll();
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to task page or show details
    print('Notification tapped: ${response.payload}');
  }

  // Calculate next execution time for a task
  static DateTime? _calculateNextExecution(Task task) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Create today's execution time
    final todayExecution = DateTime(
      today.year,
      today.month,
      today.day,
      task.time.hour,
      task.time.minute,
    );

    // If today's execution time has passed, calculate next one
    if (todayExecution.isBefore(now)) {
      switch (task.frequency) {
        case 'daily':
          return todayExecution.add(const Duration(days: 1));
        case 'weekly':
          return todayExecution.add(const Duration(days: 7));
        case 'monthly':
          // Add one month (simplified)
          final nextMonth = DateTime(today.year, today.month + 1, today.day);
          return DateTime(
            nextMonth.year,
            nextMonth.month,
            nextMonth.day,
            task.time.hour,
            task.time.minute,
          );
        default:
          return todayExecution.add(const Duration(days: 1));
      }
    }

    return todayExecution;
  }

  // Get DateTimeComponents for recurring notifications
  static DateTimeComponents? _getDateTimeComponents(String frequency) {
    switch (frequency) {
      case 'daily':
        return DateTimeComponents.time;
      case 'weekly':
        return DateTimeComponents.dayOfWeekAndTime;
      case 'monthly':
        return DateTimeComponents.dayOfMonthAndTime;
      default:
        return DateTimeComponents.time;
    }
  }

  // Get pending notifications
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    if (!_initialized) await initialize();
    return await _notifications.pendingNotificationRequests();
  }

  // Check if notification is scheduled
  static Future<bool> isNotificationScheduled(Task task) async {
    final pending = await getPendingNotifications();
    return pending.any((notification) => notification.id == task.id.hashCode);
  }
}
