import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VersionHistory {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;
  final String version;
  final String buildNumber;
  final String platform;
  final String updateType; // 'available', 'downloaded', 'installed'
  final String? downloadUrl;
  final String? releaseNotes;
  final DateTime timestamp;
  final bool isRead;

  VersionHistory({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
    required this.version,
    required this.buildNumber,
    required this.platform,
    required this.updateType,
    this.downloadUrl,
    this.releaseNotes,
    required this.timestamp,
    required this.isRead,
  });

  factory VersionHistory.fromJson(Map<String, dynamic> json, String id) {
    DateTime parseDate(dynamic dateValue) {
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      } else if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          return DateTime.now();
        }
      } else {
        return DateTime.now();
      }
    }

    return VersionHistory(
      id: id,
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userEmail: json['userEmail']?.toString() ?? '',
      userPhotoUrl: json['userPhotoUrl']?.toString(),
      version: json['version']?.toString() ?? '',
      buildNumber: json['buildNumber']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      updateType: json['updateType']?.toString() ?? '',
      downloadUrl: json['downloadUrl']?.toString(),
      releaseNotes: json['releaseNotes']?.toString(),
      timestamp: parseDate(json['timestamp']),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhotoUrl': userPhotoUrl,
      'version': version,
      'buildNumber': buildNumber,
      'platform': platform,
      'updateType': updateType,
      'downloadUrl': downloadUrl,
      'releaseNotes': releaseNotes,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}

class VersionHistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add version history when user receives notification
  static Future<void> addVersionHistory(VersionHistory history) async {
    try {
      await _firestore.collection('version_history').add(history.toJson());
    } catch (e) {
      throw Exception('Failed to add version history: $e');
    }
  }

  // Get version history for current user
  static Stream<List<VersionHistory>> getUserVersionHistory() {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return Stream.value(<VersionHistory>[]);
      }

      return _firestore
          .collection('version_history')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots()
          .map((snapshot) {
            try {
              final versionHistory = snapshot.docs
                  .map((doc) {
                    try {
                      final data = doc.data();
                      return VersionHistory.fromJson(data, doc.id);
                    } catch (e) {
                      print('Error parsing version history document ${doc.id}: $e');
                      return null;
                    }
                  })
                  .where((history) => history != null)
                  .cast<VersionHistory>()
                  .toList();

              return versionHistory;
            } catch (e) {
              print('Error processing version history snapshot: $e');
              return <VersionHistory>[];
            }
          })
          .handleError((error) {
            print('Error in version history stream: $error');
            return <VersionHistory>[];
          });
    } catch (e) {
      print('Error setting up version history stream: $e');
      return Stream.value(<VersionHistory>[]);
    }
  }

  // Get version history count
  static Stream<int> getVersionHistoryCount() {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return Stream.value(0);
      }

      return _firestore
          .collection('version_history')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      print('Error getting version history count: $e');
      return Stream.value(0);
    }
  }

  // Clear all version history (move to deleted collection)
  static Future<void> clearAllVersionHistory() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      print('Clearing version history for user: ${user.uid}');

      // Get all user's version history
      final historyDocs = await _firestore
          .collection('version_history')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (historyDocs.docs.isEmpty) {
        print('No version history found to clear');
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
        'deletionReason': 'user_cleared_all_version_history',
        'deletionMethod': 'bulk_clear',
        'originalCollection': 'version_history',
        'deletedRecordCount': historyDocs.docs.length,
      };

      for (int i = 0; i < historyDocs.docs.length; i++) {
        final doc = historyDocs.docs[i];
        final data = doc.data();

        // Add all deletion metadata
        data.addAll(deletionInfo);
        // Add individual record info
        data['originalDocumentId'] = doc.id;
        data['deletedRecordIndex'] = i;

        final deletedDoc = _firestore
            .collection('delete_version_history')
            .doc(doc.id);
        batch.set(deletedDoc, data);
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Successfully cleared ${historyDocs.docs.length} version history records');
    } catch (e) {
      print('Error clearing version history: $e');
      throw Exception('Failed to clear version history: $e');
    }
  }

  // Delete specific version history record
  static Future<void> deleteVersionHistory(String versionHistoryId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get the document first
      final doc = await _firestore.collection('version_history').doc(versionHistoryId).get();

      if (!doc.exists) {
        print('Version history document not found: $versionHistoryId');
        return;
      }

      // Move to deleted collection with complete info
      final data = doc.data()!;
      final deletionInfo = {
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedByUserId': user.uid,
        'deletedByUserEmail': user.email ?? '',
        'deletedByUserName': user.displayName ?? '',
        'deletionReason': 'user_deleted_single_version_record',
        'deletionMethod': 'individual_delete',
        'originalCollection': 'version_history',
        'originalDocumentId': versionHistoryId,
        'deletedRecordCount': 1,
      };

      // Add all deletion metadata
      data.addAll(deletionInfo);

      await _firestore
          .collection('delete_version_history')
          .doc(versionHistoryId)
          .set(data);

      // Delete from original collection
      await _firestore.collection('version_history').doc(versionHistoryId).delete();

      print('Successfully deleted version history: $versionHistoryId');
    } catch (e) {
      print('Error deleting version history: $e');
      rethrow;
    }
  }

  // Mark version history as read
  static Future<void> markAsRead(String versionHistoryId) async {
    try {
      await _firestore
          .collection('version_history')
          .doc(versionHistoryId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking version history as read: $e');
    }
  }

  // Get current app version from Firestore
  static Future<Map<String, dynamic>?> getCurrentAppVersion() async {
    try {
      final versionDoc = await _firestore
          .collection('app_versions')
          .doc('current')
          .get();

      if (versionDoc.exists) {
        return versionDoc.data();
      }
      return null;
    } catch (e) {
      print('Error getting current app version: $e');
      return null;
    }
  }

  // Create version history when user receives update notification
  static Future<void> createVersionHistory({
    required String version,
    required String buildNumber,
    required String platform,
    required String updateType,
    String? downloadUrl,
    String? releaseNotes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final history = VersionHistory(
        id: '',
        userId: user.uid,
        userName: user.displayName ?? '',
        userEmail: user.email ?? '',
        userPhotoUrl: user.photoURL,
        version: version,
        buildNumber: buildNumber,
        platform: platform,
        updateType: updateType,
        downloadUrl: downloadUrl,
        releaseNotes: releaseNotes,
        timestamp: DateTime.now(),
        isRead: false,
      );

      await addVersionHistory(history);
      print('Version history created for version: $version');
    } catch (e) {
      print('Error creating version history: $e');
    }
  }
}
