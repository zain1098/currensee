import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AlertHistory {
  final String id;
  final String userId;
  final String alertId;
  final String baseCurrency;
  final String targetCurrency;
  final double targetRate;
  final String triggerType;
  final DateTime triggeredAt;
  final double currentRate;
  final String notificationTitle;
  final String notificationBody;
  final String sound;
  final DateTime createdAt;

  AlertHistory({
    required this.id,
    required this.userId,
    required this.alertId,
    required this.baseCurrency,
    required this.targetCurrency,
    required this.targetRate,
    required this.triggerType,
    required this.triggeredAt,
    required this.currentRate,
    required this.notificationTitle,
    required this.notificationBody,
    required this.sound,
    required this.createdAt,
  });

  factory AlertHistory.fromJson(Map<String, dynamic> json, String docId) {
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is String) {
        return DateTime.parse(timestamp);
      } else {
        return DateTime.now();
      }
    }

    return AlertHistory(
      id: docId,
      userId: json['userId']?.toString() ?? '',
      alertId: json['alertId']?.toString() ?? '',
      baseCurrency: json['baseCurrency']?.toString() ?? '',
      targetCurrency: json['targetCurrency']?.toString() ?? '',
      targetRate: (json['targetRate'] ?? 0.0).toDouble(),
      triggerType: json['triggerType']?.toString() ?? '',
      triggeredAt: parseTimestamp(json['triggeredAt']),
      currentRate: (json['currentRate'] ?? 0.0).toDouble(),
      notificationTitle: json['notificationTitle']?.toString() ?? '',
      notificationBody: json['notificationBody']?.toString() ?? '',
      sound: json['sound']?.toString() ?? '',
      createdAt: parseTimestamp(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'alertId': alertId,
      'baseCurrency': baseCurrency,
      'targetCurrency': targetCurrency,
      'targetRate': targetRate,
      'triggerType': triggerType,
      'triggeredAt': Timestamp.fromDate(triggeredAt),
      'currentRate': currentRate,
      'notificationTitle': notificationTitle,
      'notificationBody': notificationBody,
      'sound': sound,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class AlertHistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'alert_history';
  static const String _deletedCollectionName = 'deleted_alert_history';

  // Get user's alert history
  static Stream<List<AlertHistory>> getUserAlertHistory() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in for alert history');
        return Stream.value(<AlertHistory>[]);
      }

      print(
        'Fetching alert history for user: ${user.uid} from collection: $_collectionName',
      );

      // Fetch all documents and filter in memory to avoid index requirements
      return _firestore
          .collection(_collectionName)
          .limit(100) // Limit to prevent too many documents
          .snapshots()
          .map((snapshot) {
            try {
              print(
                'Received ${snapshot.docs.length} alert history records from Firestore',
              );
              
              // Filter by userId in memory
              final userDocs = snapshot.docs.where((doc) {
                final data = doc.data();
                return data['userId'] == user.uid;
              }).toList();
              
              print('Filtered to ${userDocs.length} documents for user ${user.uid}');
              
              final alertHistory =
                  userDocs
                      .map((doc) {
                        try {
                          final data = doc.data();
                          print('Processing alert history document: ${doc.id}');
                          return AlertHistory.fromJson(data, doc.id);
                        } catch (e) {
                          print(
                            'Error parsing alert history document ${doc.id}: $e',
                          );
                          return null;
                        }
                      })
                      .where((alert) => alert != null)
                      .cast<AlertHistory>()
                      .toList();

              // Sort in memory by triggeredAt descending
              alertHistory.sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));

              print(
                'Successfully parsed ${alertHistory.length} alert history records',
              );
              return alertHistory;
            } catch (e) {
              print('Error processing alert history snapshot: $e');
              return <AlertHistory>[];
            }
          })
          .handleError((error) {
            print('Error in alert history stream: $error');
            return <AlertHistory>[];
          });
    } catch (e) {
      print('Error setting up alert history stream: $e');
      return Stream.value(<AlertHistory>[]);
    }
  }



  // Clear all alert history (move to deleted collection)
  static Future<void> clearAllAlertHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print('Clearing alert history for user: ${user.uid}');

      // Get all documents and filter in memory to avoid index requirements
      final snapshot = await _firestore.collection(_collectionName).get();
      final userDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['userId'] == user.uid;
      }).toList();

      if (userDocs.isEmpty) {
        print('No alert history found to clear');
        return;
      }

      // Move to deleted collection with complete user info
      final batch = _firestore.batch();
      final deletedAt = FieldValue.serverTimestamp();
      final deletionInfo = {
        'deletedAt': deletedAt,
        'deletedByUserId': user.uid,
        'deletedByUserEmail': user.email ?? '',
        'deletedByUserName': user.displayName ?? '',
        'deletionReason': 'user_cleared_all_history',
        'deletionMethod': 'bulk_clear',
        'originalCollection': _collectionName,
        'deletedRecordCount': userDocs.length,
      };

      for (final doc in userDocs) {
        final data = doc.data();
        // Add all deletion metadata
        data.addAll(deletionInfo);
        // Add individual record info
        data['originalDocumentId'] = doc.id;
        data['deletedRecordIndex'] = userDocs.indexOf(doc);

        final deletedDoc = _firestore
            .collection(_deletedCollectionName)
            .doc(doc.id);
        batch.set(deletedDoc, data);
        batch.delete(doc.reference);
      }

      await batch.commit();
      print(
        'Successfully cleared ${userDocs.length} alert history records',
      );
    } catch (e) {
      print('Error clearing alert history: $e');
      rethrow;
    }
  }

  // Delete specific alert history record
  static Future<void> deleteAlertHistory(String alertHistoryId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get the document first
      final doc =
          await _firestore
              .collection(_collectionName)
              .doc(alertHistoryId)
              .get();

      if (!doc.exists) {
        print('Alert history document not found: $alertHistoryId');
        return;
      }

      // Move to deleted collection with complete info
      final data = doc.data()!;
      final deletionInfo = {
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedByUserId': user.uid,
        'deletedByUserEmail': user.email ?? '',
        'deletedByUserName': user.displayName ?? '',
        'deletionReason': 'user_deleted_single_record',
        'deletionMethod': 'individual_delete',
        'originalCollection': _collectionName,
        'originalDocumentId': alertHistoryId,
        'deletedRecordCount': 1,
      };

      // Add all deletion metadata
      data.addAll(deletionInfo);

      await _firestore
          .collection(_deletedCollectionName)
          .doc(alertHistoryId)
          .set(data);

      // Delete from original collection
      await _firestore.collection(_collectionName).doc(alertHistoryId).delete();

      print('Successfully deleted alert history: $alertHistoryId');
    } catch (e) {
      print('Error deleting alert history: $e');
      rethrow;
    }
  }

  // Get alert history count
  static Stream<int> getAlertHistoryCount() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return Stream.value(0);

      return _firestore
          .collection(_collectionName)
          .snapshots()
          .map((snapshot) {
            final userDocs = snapshot.docs.where((doc) {
              final data = doc.data();
              return data['userId'] == user.uid;
            }).toList();
            return userDocs.length;
          });
    } catch (e) {
      print('Error getting alert history count: $e');
      return Stream.value(0);
    }
  }

  // Format trigger type for display
  static String getTriggerTypeDisplay(String triggerType) {
    switch (triggerType) {
      case 'above':
        return 'Above';
      case 'below':
        return 'Below';
      case 'equal':
        return 'Equal';
      default:
        return 'Unknown';
    }
  }

  // Get trigger type icon
  static IconData getTriggerTypeIcon(String triggerType) {
    switch (triggerType) {
      case 'above':
        return Icons.trending_up;
      case 'below':
        return Icons.trending_down;
      case 'equal':
        return Icons.remove;
      default:
        return Icons.notifications;
    }
  }

  // Get trigger type color
  static Color getTriggerTypeColor(String triggerType) {
    switch (triggerType) {
      case 'above':
        return Colors.green;
      case 'below':
        return Colors.red;
      case 'equal':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Format currency pair for display
  static String formatCurrencyPair(String base, String target) {
    return '$base/$target';
  }

  // Format rate for display
  static String formatRate(double rate) {
    return rate.toStringAsFixed(4);
  }

  // Format date for display
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
