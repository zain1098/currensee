import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import 'notification_manager.dart';
import 'package:uuid/uuid.dart';

class TaskService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String tasksCollection = 'tasks';
  static const String taskHistoryCollection = 'task_history';
  static const String deletedTaskHistoryCollection = 'deleted_task_history';

  // Stream controllers for real-time updates
  static Stream<List<Task>> getUserTasks() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection(tasksCollection)
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                data['id'] = doc.id; // Ensure id is set
                return Task.fromMap(data);
              })
              .where((task) => task.isActive) // Filter active tasks in memory
              .toList()
            ..sort(
              (a, b) => b.createdAt.compareTo(a.createdAt),
            ); // Sort by creation date
        });
  }

  Stream<List<TaskHistory>> getTaskHistoryStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection(taskHistoryCollection)
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
              final data = doc.data();
              data['notificationId'] = doc.id; // Ensure notificationId is set
              return TaskHistory.fromMap(data);
            }).toList()
            ..sort(
              (a, b) => b.triggeredAt.compareTo(a.triggeredAt),
            ) // Sort by triggered date
            ..take(50); // Limit to last 50 entries
        });
  }

  // Create a new task
  static Future<String> createTask(Task task) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final taskId = const Uuid().v4();
    final now = DateTime.now();

    // Get user info
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    final userData = userDoc.data() ?? {};
    final userName = userData['name'] ?? user.displayName ?? 'User';
    final userEmail = user.email ?? '';
    final userPhotoUrl = user.photoURL;

    final taskWithId = task.copyWith(
      id: taskId,
      userId: user.uid,
      userName: userName,
      userEmail: userEmail,
      userPhotoUrl: userPhotoUrl,
      createdAt: now,
    );

    await FirebaseFirestore.instance
        .collection(tasksCollection)
        .doc(taskId)
        .set(taskWithId.toMap());

    // Schedule notification for the task
    await scheduleTaskNotification(taskWithId);

    return taskId;
  }

  // Update an existing task
  static Future<void> updateTask(Task task) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await FirebaseFirestore.instance
        .collection(tasksCollection)
        .doc(task.id)
        .update(task.toMap());
  }

  // Delete a task (soft delete by setting isActive to false)
  static Future<void> deleteTask(String taskId, String reason) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await FirebaseFirestore.instance
        .collection(tasksCollection)
        .doc(taskId)
        .update({
          'isActive': false,
          'deletedAt': Timestamp.fromDate(DateTime.now()),
          'deleteReason': reason,
        });
  }

  // Get a single task by ID
  Future<Task?> getTask(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection(tasksCollection).doc(taskId).get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    data['id'] = doc.id;
    return Task.fromMap(data);
  }

  // Get all active tasks for a user
  Future<List<Task>> getActiveTasks() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot =
        await _firestore
            .collection(tasksCollection)
            .where('userId', isEqualTo: user.uid)
            .get();

    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Task.fromMap(data);
        })
        .where((task) => task.isActive) // Filter active tasks in memory
        .toList()
      ..sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      ); // Sort by creation date
  }

  // Create task history entry
  static Future<void> completeTask(
    String taskId,
    double convertedAmount,
    double rate,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final notificationId = const Uuid().v4();
    final now = DateTime.now();

    // Get task details
    final taskDoc =
        await FirebaseFirestore.instance
            .collection(tasksCollection)
            .doc(taskId)
            .get();

    if (!taskDoc.exists) throw Exception('Task not found');

    final taskData = taskDoc.data()!;
    final task = Task.fromMap({...taskData, 'id': taskId});

    final taskHistory = TaskHistory(
      notificationId: notificationId,
      taskId: taskId,
      userId: user.uid,
      rate: rate,
      convertedAmount: convertedAmount,
      triggeredAt: now,
      isRead: false,
    );

    await FirebaseFirestore.instance
        .collection(taskHistoryCollection)
        .doc(notificationId)
        .set(taskHistory.toMap());

    // Update task with last executed time
    await FirebaseFirestore.instance
        .collection(tasksCollection)
        .doc(taskId)
        .update({'lastExecuted': Timestamp.fromDate(now)});
  }

  // Show task notification
  static Future<void> showTaskNotification(
    Task task,
    double convertedAmount,
    double rate,
  ) async {
    try {
      await NotificationManager.showTaskNotification(
        task,
        convertedAmount,
        rate,
      );
    } catch (e) {
      print('Failed to show notification: $e');
    }
  }

  // Schedule task notification
  static Future<void> scheduleTaskNotification(Task task) async {
    try {
      await NotificationManager.scheduleTaskNotification(task);
    } catch (e) {
      print('Failed to schedule notification: $e');
    }
  }

  // Check and execute due tasks
  static Future<void> checkAndExecuteDueTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);

    final snapshot =
        await FirebaseFirestore.instance
            .collection(tasksCollection)
            .where('userId', isEqualTo: user.uid)
            .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      final task = Task.fromMap(data);

      // Only process active tasks
      if (!task.isActive) continue;

      // Check if it's time to execute this task
      if (_shouldExecuteTask(task, currentTime)) {
        try {
          // Simulate getting rate from API
          final rate =
              1.0 + (DateTime.now().millisecondsSinceEpoch % 100) / 1000;
          final convertedAmount = task.amount * rate;

          await completeTask(task.id, convertedAmount, rate);
          await showTaskNotification(task, convertedAmount, rate);
        } catch (e) {
          print('Failed to execute task ${task.id}: $e');
        }
      }
    }
  }

  // Helper method to determine if task should be executed
  static bool _shouldExecuteTask(Task task, TimeOfDay currentTime) {
    // Simple check: if current time matches task time (within 5 minutes)
    final timeDiff =
        (currentTime.hour * 60 + currentTime.minute) -
        (task.time.hour * 60 + task.time.minute);
    return timeDiff.abs() <= 5;
  }

  // Cleanup old task history
  static Future<void> cleanupOldTaskHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    final snapshot =
        await FirebaseFirestore.instance
            .collection(taskHistoryCollection)
            .where('userId', isEqualTo: user.uid)
            .get();

    // Filter old entries in memory
    final oldDocs = snapshot.docs.where((doc) {
      final data = doc.data();
      final triggeredAt = data['triggeredAt'] as Timestamp?;
      if (triggeredAt == null) return false;
      return triggeredAt.toDate().isBefore(thirtyDaysAgo);
    });

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in oldDocs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Mark task history as read
  Future<void> markTaskHistoryAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection(taskHistoryCollection)
        .doc(notificationId)
        .update({'isRead': true});

    notifyListeners();
  }

  // Mark all task history as read
  Future<void> markAllTaskHistoryAsRead() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final batch = _firestore.batch();
    final snapshot =
        await _firestore
            .collection(taskHistoryCollection)
            .where('userId', isEqualTo: user.uid)
            .get();

    // Filter unread entries in memory
    final unreadDocs = snapshot.docs.where((doc) {
      final data = doc.data();
      return data['isRead'] == false;
    });

    for (final doc in unreadDocs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
    notifyListeners();
  }

  // Clear all task history (move to deleted_task_history)
  Future<void> clearAllTaskHistory() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final batch = _firestore.batch();
    final snapshot =
        await _firestore
            .collection(taskHistoryCollection)
            .where('userId', isEqualTo: user.uid)
            .get();

    for (final doc in snapshot.docs) {
      // Move to deleted_task_history
      final deletedRef = _firestore
          .collection(deletedTaskHistoryCollection)
          .doc(doc.id);
      batch.set(deletedRef, doc.data());

      // Delete from task_history
      batch.delete(doc.reference);
    }

    await batch.commit();
    notifyListeners();
  }

  // Get unread task history count
  Future<int> getUnreadTaskHistoryCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final snapshot =
        await _firestore
            .collection(taskHistoryCollection)
            .where('userId', isEqualTo: user.uid)
            .get();

    // Count unread entries in memory
    return snapshot.docs.where((doc) {
      final data = doc.data();
      return data['isRead'] == false;
    }).length;
  }

  // Get task history by ID
  Future<TaskHistory?> getTaskHistory(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc =
        await _firestore
            .collection(taskHistoryCollection)
            .doc(notificationId)
            .get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    data['notificationId'] = doc.id;
    return TaskHistory.fromMap(data);
  }

  // Get task history for a specific task
  Future<List<TaskHistory>> getTaskHistoryForTask(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot =
        await _firestore
            .collection(taskHistoryCollection)
            .where('userId', isEqualTo: user.uid)
            .get();

    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          data['notificationId'] = doc.id;
          return TaskHistory.fromMap(data);
        })
        .where(
          (history) => history.taskId == taskId,
        ) // Filter by taskId in memory
        .toList()
      ..sort(
        (a, b) => b.triggeredAt.compareTo(a.triggeredAt),
      ); // Sort by triggered date
  }

  // Delete specific task history entry
  Future<void> deleteTaskHistory(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // First, move to deleted_task_history
    final doc =
        await _firestore
            .collection(taskHistoryCollection)
            .doc(notificationId)
            .get();

    if (doc.exists) {
      await _firestore
          .collection(deletedTaskHistoryCollection)
          .doc(notificationId)
          .set(doc.data()!);

      // Then delete from task_history
      await _firestore
          .collection(taskHistoryCollection)
          .doc(notificationId)
          .delete();
    }

    notifyListeners();
  }

  // Get all tasks for notification scheduling (used by NotificationManager)
  Future<List<Task>> getAllActiveTasksForNotifications() async {
    final snapshot = await _firestore.collection(tasksCollection).get();

    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Task.fromMap(data);
        })
        .where((task) => task.isActive) // Filter active tasks in memory
        .toList();
  }
}
