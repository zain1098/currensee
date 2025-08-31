import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirestoreIndexService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if indexes are missing and provide creation links
  static Future<Map<String, dynamic>> checkMissingIndexes() async {
    final results = <String, dynamic>{};

    try {
      // Test alert_history index
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _firestore
              .collection('alert_history')
              .where('userId', isEqualTo: user.uid)
              .orderBy('triggeredAt', descending: true)
              .limit(1)
              .get();
          results['alert_history'] = {'status': 'exists', 'error': null};
        }
      } catch (e) {
        if (e.toString().contains('failed-precondition') &&
            e.toString().contains('requires an index')) {
          results['alert_history'] = {
            'status': 'missing',
            'error': e.toString(),
            'createUrl': _extractCreateUrl(e.toString()),
          };
        } else {
          results['alert_history'] = {'status': 'error', 'error': e.toString()};
        }
      }

      // Test version_history index
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _firestore
              .collection('version_history')
              .where('userId', isEqualTo: user.uid)
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();
          results['version_history'] = {'status': 'exists', 'error': null};
        }
      } catch (e) {
        if (e.toString().contains('failed-precondition') &&
            e.toString().contains('requires an index')) {
          results['version_history'] = {
            'status': 'missing',
            'error': e.toString(),
            'createUrl': _extractCreateUrl(e.toString()),
          };
        } else {
          results['version_history'] = {
            'status': 'error',
            'error': e.toString(),
          };
        }
      }
    } catch (e) {
      results['general'] = {'status': 'error', 'error': e.toString()};
    }

    return results;
  }

  // Extract the create URL from the error message
  static String? _extractCreateUrl(String errorMessage) {
    final regex = RegExp(r'https://console\.firebase\.google\.com[^\s]+');
    final match = regex.firstMatch(errorMessage);
    return match?.group(0);
  }

  // Get index status summary
  static String getIndexStatusSummary(Map<String, dynamic> indexResults) {
    final missingIndexes = <String>[];
    final errors = <String>[];

    indexResults.forEach((collection, result) {
      if (result['status'] == 'missing') {
        missingIndexes.add(collection);
      } else if (result['status'] == 'error') {
        errors.add('$collection: ${result['error']}');
      }
    });

    if (missingIndexes.isNotEmpty) {
      return 'Missing indexes: ${missingIndexes.join(', ')}. Please create them to enable proper data display.';
    } else if (errors.isNotEmpty) {
      return 'Errors: ${errors.join('; ')}';
    } else {
      return 'All indexes are properly configured.';
    }
  }

  // Show index creation dialog
  static void showIndexCreationDialog(
    BuildContext context,
    Map<String, dynamic> indexResults,
  ) {
    final missingIndexes = <String, dynamic>{};
    indexResults.forEach((collection, result) {
      if (result['status'] == 'missing') {
        missingIndexes[collection] = result;
      }
    });

    if (missingIndexes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All Firestore indexes are properly configured!'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Missing Firestore Indexes'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The following Firestore indexes are missing and need to be created for proper data display:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                ...missingIndexes.entries.map((entry) {
                  final collection = entry.key;
                  final result = entry.value;
                  final createUrl = result['createUrl'] as String?;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• $collection',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (createUrl != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Create URL:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SelectableText(
                          createUrl,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  );
                }),
                Text(
                  'Steps to create indexes:\n'
                  '1. Click on the create URL above\n'
                  '2. Sign in to Firebase Console\n'
                  '3. Click "Create Index"\n'
                  '4. Wait for index to build (may take a few minutes)\n'
                  '5. Refresh this page',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Try to open the first create URL
                  final firstMissing = missingIndexes.values.first;
                  final createUrl = firstMissing['createUrl'] as String?;
                  if (createUrl != null) {
                    // You can use url_launcher here to open the URL
                    print('Create URL: $createUrl');
                  }
                },
                child: const Text('Open First URL'),
              ),
            ],
          ),
    );
  }

  // Create a simple test document to trigger index creation
  static Future<void> createTestDocument(String collection) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final testData = {
        'userId': user.uid,
        'testField': 'test_value',
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (collection == 'alert_history') {
        testData['triggeredAt'] = FieldValue.serverTimestamp();
        testData['alertId'] =
            'test_alert_${DateTime.now().millisecondsSinceEpoch}';
        testData['baseCurrency'] = 'USD';
        testData['targetCurrency'] = 'EUR';
        testData['targetRate'] = 1.0;
        testData['currentRate'] = 1.1;
        testData['triggerType'] = 'above';
        testData['notificationTitle'] = 'Test Alert';
        testData['notificationBody'] = 'This is a test alert';
        testData['sound'] = 'default';
      } else if (collection == 'version_history') {
        testData['timestamp'] = FieldValue.serverTimestamp();
        testData['userName'] = user.displayName ?? '';
        testData['userEmail'] = user.email ?? '';
        testData['version'] = '1.0.0';
        testData['buildNumber'] = '1';
        testData['platform'] = 'Android';
        testData['updateType'] = 'available';
        testData['isRead'] = false;
      }

      await _firestore.collection(collection).add(testData);
      print('Test document created in $collection');
    } catch (e) {
      print('Error creating test document in $collection: $e');
    }
  }
}
