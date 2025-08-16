import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MaintenanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if app is in maintenance mode
  static Future<Map<String, dynamic>?> checkMaintenanceStatus() async {
    try {
      final doc =
          await _firestore.collection('maintenance_mode').doc('status').get();

      if (doc.exists) {
        final data = doc.data();
        return {
          'isEnabled': data?['isEnabled'] ?? false,
          'message': data?['message'] ?? 'App is under maintenance',
          'reason': data?['reason'] ?? 'Scheduled maintenance',
          'startTime': data?['startTime'],
          'endTime': data?['endTime'],
          'updatedAt': data?['updatedAt'],
          'updatedBy': data?['updatedBy'],
        };
      }
      return null;
    } catch (e) {
      print('Error checking maintenance status: $e');
      return null;
    }
  }

  // Add maintenance history record
  static Future<void> addMaintenanceHistory({
    required bool isEnabled,
    required String reason,
    required String message,
    required String updatedBy,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      await _firestore.collection('maintenance_history').add({
        'isEnabled': isEnabled,
        'reason': reason,
        'message': message,
        'updatedBy': updatedBy,
        'startTime': startTime,
        'endTime': endTime,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Maintenance history added successfully');
    } catch (e) {
      print('Error adding maintenance history: $e');
    }
  }

  // Show maintenance modal
  static void showMaintenanceModal(
    BuildContext context,
    Map<String, dynamic> maintenanceData,
  ) {
    // Check if modal is already showing
    if (Navigator.of(context).canPop()) {
      return; // Modal already showing
    }
    
    showDialog(
      context: context,
      barrierDismissible: false, // User cannot dismiss by tapping outside
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button from closing modal
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Maintenance Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.build_circle,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'Under Maintenance',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Message
                  Text(
                    maintenanceData['message'] ??
                        'App is currently under maintenance',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Reason
                  if (maintenanceData['reason'] != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        maintenanceData['reason'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Time information
                  if (maintenanceData['startTime'] != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.schedule,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Started: ${_formatDateTime(maintenanceData['startTime'])}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (maintenanceData['endTime'] != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.timer,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Expected: ${_formatDateTime(maintenanceData['endTime'])}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Retry button
                  ElevatedButton(
                    onPressed: () {
                      // Close the modal and let user try again
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF6A11CB),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Last updated info
                  if (maintenanceData['updatedAt'] != null) ...[
                    Text(
                      'Last updated: ${_formatDateTime(maintenanceData['updatedAt'])}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Format datetime for display
  static String _formatDateTime(dynamic dateTime) {
    try {
      if (dateTime is Timestamp) {
        final date = dateTime.toDate();
        return DateFormat('MMM dd, yyyy HH:mm').format(date);
      } else if (dateTime is String) {
        final date = DateTime.parse(dateTime);
        return DateFormat('MMM dd, yyyy HH:mm').format(date);
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  // Check if maintenance is active and show modal if needed
  static Future<bool> checkAndShowMaintenanceModal(BuildContext context) async {
    try {
      final maintenanceData = await checkMaintenanceStatus();

      if (maintenanceData != null && maintenanceData['isEnabled'] == true) {
        showMaintenanceModal(context, maintenanceData);
        return true; // Maintenance is active
      }

      return false; // No maintenance
    } catch (e) {
      print('Error in checkAndShowMaintenanceModal: $e');
      return false;
    }
  }
}
