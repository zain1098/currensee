import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class Task {
  final String id;
  final String userId;
  final String userName; // User's display name
  final String userEmail; // User's email
  final String? userPhotoUrl; // User's profile photo URL
  final String taskName;
  final String fromCurrency;
  final String toCurrency;
  final double amount;
  final String frequency; // 'daily', 'weekly', 'monthly'
  final TimeOfDay time;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastExecuted;
  final DateTime? nextExecution;

  Task({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
    required this.taskName,
    required this.fromCurrency,
    required this.toCurrency,
    required this.amount,
    required this.frequency,
    required this.time,
    required this.isActive,
    required this.createdAt,
    this.lastExecuted,
    this.nextExecution,
  });

  factory Task.fromJson(Map<String, dynamic> json, String id) {
    TimeOfDay parseTime(dynamic timeValue) {
      if (timeValue is String) {
        final parts = timeValue.split(':');
        if (parts.length == 2) {
          return TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
      return const TimeOfDay(hour: 0, minute: 0);
    }

    DateTime? parseDate(dynamic dateValue) {
      if (dateValue == null) return null;
      if (dateValue is Timestamp) return dateValue.toDate();
      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return Task(
      id: id,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      userPhotoUrl: json['userPhotoUrl'],
      taskName: json['taskName'] ?? '',
      fromCurrency: json['fromCurrency'] ?? '',
      toCurrency: json['toCurrency'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      frequency: json['frequency'] ?? 'daily',
      time: parseTime(json['time']),
      isActive: json['isActive'] ?? true,
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      lastExecuted: parseDate(json['lastExecuted']),
      nextExecution: parseDate(json['nextExecution']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhotoUrl': userPhotoUrl,
      'taskName': taskName,
      'fromCurrency': fromCurrency,
      'toCurrency': toCurrency,
      'amount': amount,
      'frequency': frequency,
      'time':
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastExecuted':
          lastExecuted != null ? Timestamp.fromDate(lastExecuted!) : null,
      'nextExecution':
          nextExecution != null ? Timestamp.fromDate(nextExecution!) : null,
    };
  }

  Task copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhotoUrl,
    String? taskName,
    String? fromCurrency,
    String? toCurrency,
    double? amount,
    String? frequency,
    TimeOfDay? time,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastExecuted,
    DateTime? nextExecution,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      taskName: taskName ?? this.taskName,
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      time: time ?? this.time,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastExecuted: lastExecuted ?? this.lastExecuted,
      nextExecution: nextExecution ?? this.nextExecution,
    );
  }
}

class TaskHistory {
  final String id;
  final String taskId;
  final String userId;
  final String userName; // User's display name
  final String userEmail; // User's email
  final String? userPhotoUrl; // User's profile photo URL
  final String action; // 'completed' or 'deleted'
  final String taskName;
  final String fromCurrency;
  final String toCurrency;
  final double amount;
  final double? convertedAmount;
  final double? rate;
  final DateTime timestamp;
  final String? reason; // for deletion

  TaskHistory({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
    required this.action,
    required this.taskName,
    required this.fromCurrency,
    required this.toCurrency,
    required this.amount,
    this.convertedAmount,
    this.rate,
    required this.timestamp,
    this.reason,
  });

  factory TaskHistory.fromJson(Map<String, dynamic> json, String id) {
    DateTime parseDate(dynamic dateValue) {
      if (dateValue is Timestamp) return dateValue.toDate();
      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return TaskHistory(
      id: id,
      taskId: json['taskId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      userPhotoUrl: json['userPhotoUrl'],
      action: json['action'] ?? '',
      taskName: json['taskName'] ?? '',
      fromCurrency: json['fromCurrency'] ?? '',
      toCurrency: json['toCurrency'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      convertedAmount: json['convertedAmount']?.toDouble(),
      rate: json['rate']?.toDouble(),
      timestamp: parseDate(json['timestamp']),
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhotoUrl': userPhotoUrl,
      'action': action,
      'taskName': taskName,
      'fromCurrency': fromCurrency,
      'toCurrency': toCurrency,
      'amount': amount,
      'convertedAmount': convertedAmount,
      'rate': rate,
      'timestamp': Timestamp.fromDate(timestamp),
      'reason': reason,
    };
  }
}

class TaskService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Initialize notifications
  static Future<void> initializeNotifications() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notifications.initialize(initializationSettings);

    // Set up notification action handlers
    _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) async {
    final taskId = response.payload ?? response.id.toString();
    final action = response.actionId;
    
    print('Notification action: $action for task: $taskId');
    
    if (action == 'execute' || action == null) {
      // Execute the task automatically
      await _executeTaskAutomatically(taskId);
    }
  }

  // Execute task automatically when notification is triggered
  static Future<void> _executeTaskAutomatically(String taskId) async {
    try {
      // Get the task from Firestore
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) {
        print('Task not found: $taskId');
        return;
      }

      final task = Task.fromJson(taskDoc.data()!, taskId);
      
      // Check if task is still active
      if (!task.isActive) {
        print('Task is not active: ${task.taskName}');
        return;
      }

      // Simulate currency conversion (in real app, this would call actual API)
      final rate = 1.0 + (DateTime.now().millisecondsSinceEpoch % 100) / 1000;
      final convertedAmount = task.amount * rate;

      // Complete the task
      await completeTask(taskId, convertedAmount, rate);
      
      // Show completion notification
      await showTaskNotification(task, convertedAmount, rate);
      
      print('Task executed automatically: ${task.taskName}');
      
    } catch (e) {
      print('Error executing task automatically: $e');
    }
  }

  // Get current user details from Firestore
  static Future<Map<String, String?>> _getCurrentUserDetails() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      final userDoc = await _firestore.collection('currentUser').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      return {
        'userName': userData['displayName'] ?? user.displayName ?? '',
        'userEmail': user.email ?? '',
        'userPhotoUrl': userData['photoURL'] ?? user.photoURL,
      };
    } catch (e) {
      // Fallback to Firebase Auth data if Firestore fails
      return {
        'userName': user.displayName ?? '',
        'userEmail': user.email ?? '',
        'userPhotoUrl': user.photoURL,
      };
    }
  }

  // Create a new task with automatic notification scheduling
  static Future<String> createTask(Task task) async {
    try {
      // Get current user details and update task
      final userDetails = await _getCurrentUserDetails();
      final taskWithUserDetails = task.copyWith(
        userName: userDetails['userName'] ?? '',
        userEmail: userDetails['userEmail'] ?? '',
        userPhotoUrl: userDetails['userPhotoUrl'],
      );

      final docRef = await _firestore.collection('tasks').add(taskWithUserDetails.toJson());

      // Schedule notification for the new task
      if (task.isActive) {
        await scheduleTaskNotification(taskWithUserDetails);
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  // Get all tasks for current user with caching
  static Stream<List<Task>> getUserTasks() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .limit(20) // Limit to prevent excessive data loading
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Task.fromJson(doc.data(), doc.id))
                  .where(
                    (task) => task.isActive,
                  ) // Filter active tasks in memory
                  .toList()
                ..sort(
                  (a, b) => b.createdAt.compareTo(a.createdAt),
                ), // Sort in memory
        );
  }

  // Update task with notification management
  static Future<void> updateTask(Task task) async {
    try {
      await _firestore.collection('tasks').doc(task.id).update(task.toJson());

      // Handle notification scheduling based on task status
      if (task.isActive) {
        await scheduleTaskNotification(task);
      } else {
        await cancelTaskNotification(task.id);
      }
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  // Delete task
  static Future<void> deleteTask(String taskId, String reason) async {
    try {
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (taskDoc.exists) {
        final task = Task.fromJson(taskDoc.data()!, taskId);

        // Add to history
        await addTaskHistory(
          TaskHistory(
            id: '',
            taskId: taskId,
            userId: task.userId,
            userName: task.userName,
            userEmail: task.userEmail,
            userPhotoUrl: task.userPhotoUrl,
            action: 'deleted',
            taskName: task.taskName,
            fromCurrency: task.fromCurrency,
            toCurrency: task.toCurrency,
            amount: task.amount,
            timestamp: DateTime.now(),
            reason: reason,
          ),
        );

        // Delete the task
        await _firestore.collection('tasks').doc(taskId).delete();
      }
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  // Complete task
  static Future<void> completeTask(
    String taskId,
    double convertedAmount,
    double rate,
  ) async {
    try {
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (taskDoc.exists) {
        final task = Task.fromJson(taskDoc.data()!, taskId);

        // Add to history
        await addTaskHistory(
          TaskHistory(
            id: '',
            taskId: taskId,
            userId: task.userId,
            userName: task.userName,
            userEmail: task.userEmail,
            userPhotoUrl: task.userPhotoUrl,
            action: 'completed',
            taskName: task.taskName,
            fromCurrency: task.fromCurrency,
            toCurrency: task.toCurrency,
            amount: task.amount,
            convertedAmount: convertedAmount,
            rate: rate,
            timestamp: DateTime.now(),
          ),
        );

        // Update task with last executed time
        final updatedTask = task.copyWith(
          lastExecuted: DateTime.now(),
          nextExecution: _calculateNextExecution(task),
        );
        await updateTask(updatedTask);
      }
    } catch (e) {
      throw Exception('Failed to complete task: $e');
    }
  }

  // Add task history
  static Future<void> addTaskHistory(TaskHistory history) async {
    try {
      await _firestore.collection('task_history').add(history.toJson());
    } catch (e) {
      throw Exception('Failed to add task history: $e');
    }
  }

  // Get task history for current user with optimized loading
  static Stream<List<TaskHistory>> getUserTaskHistory() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('task_history')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(30) // Reduced limit for better performance
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => TaskHistory.fromJson(doc.data(), doc.id))
                  .toList(),
        );
  }

  // Clear task history
  static Future<void> clearTaskHistory() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final batch = _firestore.batch();
      final historyDocs =
          await _firestore
              .collection('task_history')
              .where('userId', isEqualTo: userId)
              .get();

      for (final doc in historyDocs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear task history: $e');
    }
  }

  // Calculate next execution time
  static DateTime _calculateNextExecution(Task task) {
    final now = DateTime.now();
    DateTime nextExecution = DateTime(
      now.year,
      now.month,
      now.day,
      task.time.hour,
      task.time.minute,
    );

    // If time has passed today, schedule for next occurrence
    if (nextExecution.isBefore(now)) {
      switch (task.frequency) {
        case 'daily':
          nextExecution = nextExecution.add(const Duration(days: 1));
          break;
        case 'weekly':
          nextExecution = nextExecution.add(const Duration(days: 7));
          break;
        case 'monthly':
          nextExecution = DateTime(
            now.year,
            now.month + 1,
            now.day,
            task.time.hour,
            task.time.minute,
          );
          break;
      }
    }

    return nextExecution;
  }

  // Schedule notification for task with optimization
  static Future<void> scheduleTaskNotification(Task task) async {
    try {
      // Cancel existing notification for this task
      await cancelTaskNotification(task.id);

      final nextExecution = _calculateNextExecution(task);

      // Don't schedule if the time is too far in the future (more than 1 year)
      if (nextExecution.isAfter(
        DateTime.now().add(const Duration(days: 365)),
      )) {
        print(
          'Task ${task.taskName} scheduled too far in future, skipping notification',
        );
        return;
      }

      final scheduledDate = tz.TZDateTime.from(nextExecution, tz.local);

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'task_channel',
            'Task Notifications',
            channelDescription: 'Notifications for currency monitoring tasks',
            importance: Importance.high,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('notification'),
            actions: [
              AndroidNotificationAction('execute', 'Execute Now'),
              AndroidNotificationAction('dismiss', 'Dismiss'),
            ],
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _notifications.zonedSchedule(
        task.id.hashCode,
        'Currency Task: ${task.taskName}',
        'Time to check ${task.amount} ${task.fromCurrency} to ${task.toCurrency}',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: task.id, // Pass task ID as payload
      );

      print(
        'Task notification scheduled for ${task.taskName} at $scheduledDate',
      );
    } catch (e) {
      print('Error scheduling task notification: $e');
    }
  }

  // Cancel task notification
  static Future<void> cancelTaskNotification(String taskId) async {
    await _notifications.cancel(taskId.hashCode);
  }

  // Show immediate notification
  static Future<void> showTaskNotification(
    Task task,
    double convertedAmount,
    double rate,
  ) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'task_channel',
          'Task Notifications',
          channelDescription: 'Notifications for currency monitoring tasks',
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('notification'),
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      task.id.hashCode,
      'Currency Task Completed: ${task.taskName}',
      '${task.amount} ${task.fromCurrency} = ${convertedAmount.toStringAsFixed(2)} ${task.toCurrency} (Rate: ${rate.toStringAsFixed(4)})',
      notificationDetails,
    );
  }

  // Get task execution statistics for performance monitoring
  static Future<Map<String, dynamic>> getTaskStatistics() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return {};

    try {
      final tasksSnapshot =
          await _firestore
              .collection('tasks')
              .where('userId', isEqualTo: userId)
              .get();

      final historySnapshot =
          await _firestore
              .collection('task_history')
              .where('userId', isEqualTo: userId)
              .where(
                'timestamp',
                isGreaterThan: DateTime.now().subtract(
                  const Duration(days: 30),
                ),
              )
              .get();

      return {
        'totalTasks': tasksSnapshot.docs.length,
        'activeTasks':
            tasksSnapshot.docs
                .where((doc) => doc.data()['isActive'] == true)
                .length,
        'completedThisMonth':
            historySnapshot.docs
                .where((doc) => doc.data()['action'] == 'completed')
                .length,
        'deletedThisMonth':
            historySnapshot.docs
                .where((doc) => doc.data()['action'] == 'deleted')
                .length,
      };
    } catch (e) {
      print('Error getting task statistics: $e');
      return {};
    }
  }

  // Clean up old task history to improve performance
  static Future<void> cleanupOldTaskHistory() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
      final oldHistoryDocs =
          await _firestore
              .collection('task_history')
              .where('userId', isEqualTo: userId)
              .where('timestamp', isLessThan: cutoffDate)
              .get();

      if (oldHistoryDocs.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in oldHistoryDocs.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        print(
          'Cleaned up ${oldHistoryDocs.docs.length} old task history records',
        );
      }
    } catch (e) {
      print('Error cleaning up old task history: $e');
    }
  }

  // Check for tasks that need to be executed (called periodically)
  static Future<void> checkAndExecuteDueTasks() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final now = DateTime.now();
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in tasksSnapshot.docs) {
        final task = Task.fromJson(doc.data(), doc.id);
        
        // Check if task is due for execution
        if (_isTaskDue(task, now)) {
          print('Task due for execution: ${task.taskName}');
          await _executeTaskAutomatically(task.id);
        }
      }
    } catch (e) {
      print('Error checking due tasks: $e');
    }
  }

  // Check if a task is due for execution
  static bool _isTaskDue(Task task, DateTime now) {
    final taskTime = DateTime(
      now.year,
      now.month,
      now.day,
      task.time.hour,
      task.time.minute,
    );

    // Check if it's time to execute (within 5 minutes of scheduled time)
    final timeDifference = now.difference(taskTime).abs();
    if (timeDifference.inMinutes > 5) return false;

    // Check frequency
    switch (task.frequency) {
      case 'daily':
        return true; // Execute daily at the same time
      case 'weekly':
        // Execute weekly on the same day of week
        final lastExecuted = task.lastExecuted;
        if (lastExecuted == null) return true;
        return now.difference(lastExecuted).inDays >= 7;
      case 'monthly':
        // Execute monthly on the same day
        final lastExecuted = task.lastExecuted;
        if (lastExecuted == null) return true;
        return now.difference(lastExecuted).inDays >= 30;
      default:
        return false;
    }
  }
}
