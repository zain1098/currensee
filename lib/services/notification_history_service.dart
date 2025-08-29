import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationHistory {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String
  category; // 'app_update', 'alert_target', 'task_complete', 'general'
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? additionalData;

  NotificationHistory({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.additionalData,
  });

  factory NotificationHistory.fromJson(Map<String, dynamic> json) {
    try {
      DateTime timestamp;
      if (json['timestamp'] is Timestamp) {
        timestamp = (json['timestamp'] as Timestamp).toDate();
      } else if (json['timestamp'] is String) {
        timestamp = DateTime.parse(json['timestamp']);
      } else {
        timestamp = DateTime.now();
      }

      return NotificationHistory(
        id:
            json['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        userId: json['userId']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Unknown Notification',
        body: json['body']?.toString() ?? 'No content available',
        category: json['category']?.toString() ?? 'general',
        timestamp: timestamp,
        isRead: json['isRead'] == true,
        additionalData:
            json['additionalData'] is Map
                ? Map<String, dynamic>.from(json['additionalData'])
                : null,
      );
    } catch (e) {
      print('Error parsing NotificationHistory from JSON: $e');
      print('JSON data: $json');
      // Return a fallback notification
      return NotificationHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: json['userId']?.toString() ?? '',
        title: 'Error Loading Notification',
        body: 'This notification could not be loaded properly.',
        category: 'general',
        timestamp: DateTime.now(),
        isRead: false,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'category': category,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'additionalData': additionalData,
    };
  }

  NotificationHistory copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? category,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? additionalData,
  }) {
    return NotificationHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}

class NotificationHistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'notificationHistory';
  static const String _archivedCollectionName = 'archivedNotifications';

  // Add new notification to history
  static Future<void> addNotification({
    required String title,
    required String body,
    required String category,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        title: title,
        body: body,
        category: category,
        timestamp: DateTime.now(),
        additionalData: additionalData,
      );

      await _firestore
          .collection(_collectionName)
          .doc(notification.id)
          .set(notification.toJson());
    } catch (e) {
      print('Error adding notification to history: $e');
    }
  }

  // Get user's notification history
  static Stream<List<NotificationHistory>> getUserNotifications() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in for notification history');
        return Stream.value(<NotificationHistory>[]);
      }

      print(
        'Fetching notifications for user: ${user.uid} from collection: $_collectionName',
      );

      return _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(50) // Limit to prevent too many documents
          .snapshots()
          .map((snapshot) {
            try {
              print(
                'Received ${snapshot.docs.length} notifications from Firestore',
              );
              final notifications =
                  snapshot.docs
                      .map((doc) {
                        try {
                          final data = doc.data();
                          print('Processing notification document: ${doc.id}');
                          return NotificationHistory.fromJson(data);
                        } catch (e) {
                          print(
                            'Error parsing notification document ${doc.id}: $e',
                          );
                          return null;
                        }
                      })
                      .where((notification) => notification != null)
                      .cast<NotificationHistory>()
                      .toList();

              print(
                'Successfully parsed ${notifications.length} notifications',
              );
              return notifications;
            } catch (e) {
              print('Error processing notification snapshot: $e');
              return <NotificationHistory>[];
            }
          })
          .handleError((error) {
            print('Error in notification history stream: $error');
            return <NotificationHistory>[];
          });
    } catch (e) {
      print('Error setting up notification history stream: $e');
      return Stream.value(<NotificationHistory>[]);
    }
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collectionName).doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Clear all notifications (move to archived collection)
  static Future<void> clearAllNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get all user notifications
      final snapshot =
          await _firestore
              .collection(_collectionName)
              .where('userId', isEqualTo: user.uid)
              .get();

      // Move to archived collection
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        final archivedDoc = _firestore
            .collection(_archivedCollectionName)
            .doc(doc.id);
        batch.set(archivedDoc, doc.data());
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  // Get notification count by category
  static Stream<Map<String, int>> getNotificationCounts() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in for notification counts');
        return Stream.value({});
      }

      return _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .map((snapshot) {
            try {
              final Map<String, int> counts = {};
              for (final doc in snapshot.docs) {
                try {
                  final category = doc.data()['category'] ?? 'general';
                  counts[category] = (counts[category] ?? 0) + 1;
                } catch (e) {
                  print(
                    'Error processing notification count for document ${doc.id}: $e',
                  );
                }
              }
              return counts;
            } catch (e) {
              print('Error processing notification counts: $e');
              return <String, int>{};
            }
          })
          .handleError((error) {
            print('Error in notification counts stream: $error');
            return <String, int>{};
          });
    } catch (e) {
      print('Error setting up notification counts stream: $e');
      return Stream.value(<String, int>{});
    }
  }

  // Get unread notification count
  static Stream<int> getUnreadCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get category display name
  static String getCategoryDisplayName(String category) {
    switch (category) {
      case 'app_update':
        return 'App Updates';
      case 'alert_target':
        return 'Alert Targets';
      case 'task_complete':
        return 'Task Completion';
      case 'general':
        return 'General';
      default:
        return 'Other';
    }
  }

  // Get category icon
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'app_update':
        return Icons.system_update;
      case 'alert_target':
        return Icons.notifications_active;
      case 'task_complete':
        return Icons.task_alt;
      case 'general':
        return Icons.notifications;
      default:
        return Icons.notifications;
    }
  }

  // Get category color
  static Color getCategoryColor(String category) {
    switch (category) {
      case 'app_update':
        return Colors.blue;
      case 'alert_target':
        return Colors.orange;
      case 'task_complete':
        return Colors.green;
      case 'general':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
