import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'services/maintenance_service.dart';

class MaintenanceDashboard extends StatefulWidget {
  const MaintenanceDashboard({super.key});

  @override
  State<MaintenanceDashboard> createState() => _MaintenanceDashboardState();
}

class _MaintenanceDashboardState extends State<MaintenanceDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _isMaintenanceEnabled = false;
  String _maintenanceMessage = '';
  String _maintenanceReason = '';
  DateTime? _startTime;
  DateTime? _endTime;
  List<Map<String, dynamic>> _maintenanceHistory = [];

  @override
  void initState() {
    super.initState();
    _loadMaintenanceStatus();
    _loadMaintenanceHistory();
  }

  Future<void> _loadMaintenanceStatus() async {
    setState(() => _isLoading = true);
    try {
      final doc = await _firestore
          .collection('maintenance_mode')
          .doc('status')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _isMaintenanceEnabled = data['isEnabled'] ?? false;
          _maintenanceMessage = data['message'] ?? '';
          _maintenanceReason = data['reason'] ?? '';
          _startTime = data['startTime']?.toDate();
          _endTime = data['endTime']?.toDate();
        });
      }
    } catch (e) {
      print('Error loading maintenance status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading status: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMaintenanceHistory() async {
    try {
      final querySnapshot = await _firestore
          .collection('maintenance_history')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      setState(() {
        _maintenanceHistory = querySnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
      });
    } catch (e) {
      print('Error loading maintenance history: $e');
    }
  }

  Future<void> _updateMaintenanceStatus({
    required bool isEnabled,
    required String message,
    required String reason,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Update maintenance status
      await _firestore.collection('maintenance_mode').doc('status').set({
        'isEnabled': isEnabled,
        'message': message,
        'reason': reason,
        'startTime': startTime,
        'endTime': endTime,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user.email ?? 'admin',
      });

      // Add to history
      await MaintenanceService.addMaintenanceHistory(
        isEnabled: isEnabled,
        message: message,
        reason: reason,
        updatedBy: user.email ?? 'admin',
        startTime: startTime,
        endTime: endTime,
      );

      // Reload data
      await _loadMaintenanceStatus();
      await _loadMaintenanceHistory();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEnabled ? 'Maintenance mode enabled' : 'Maintenance mode disabled',
          ),
          backgroundColor: isEnabled ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating maintenance status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMaintenanceDialog() {
    final messageController = TextEditingController(text: _maintenanceMessage);
    final reasonController = TextEditingController(text: _maintenanceReason);
    DateTime? startTime = _startTime;
    DateTime? endTime = _endTime;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isMaintenanceEnabled ? 'Disable Maintenance' : 'Enable Maintenance'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message for Users',
                  hintText: 'App is currently under maintenance...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Scheduled maintenance',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: startTime ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(startTime ?? DateTime.now()),
                          );
                          if (time != null) {
                            startTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          }
                        }
                      },
                      child: const Text('Start Time'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: endTime ?? DateTime.now().add(const Duration(hours: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(endTime ?? DateTime.now().add(const Duration(hours: 1))),
                          );
                          if (time != null) {
                            endTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          }
                        }
                      },
                      child: const Text('End Time'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateMaintenanceStatus(
                isEnabled: !_isMaintenanceEnabled,
                message: messageController.text,
                reason: reasonController.text,
                startTime: startTime,
                endTime: endTime,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isMaintenanceEnabled ? Colors.green : Colors.orange,
            ),
            child: Text(_isMaintenanceEnabled ? 'Disable' : 'Enable'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Dashboard'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Status Card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isMaintenanceEnabled ? Icons.build : Icons.check_circle,
                                color: _isMaintenanceEnabled ? Colors.orange : Colors.green,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isMaintenanceEnabled ? 'Maintenance Active' : 'App Running',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _isMaintenanceEnabled ? 'Users cannot access the app' : 'All users can access the app',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_isMaintenanceEnabled) ...[
                            if (_maintenanceMessage.isNotEmpty) ...[
                              const Text(
                                'Message:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(_maintenanceMessage),
                              const SizedBox(height: 8),
                            ],
                            if (_maintenanceReason.isNotEmpty) ...[
                              const Text(
                                'Reason:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(_maintenanceReason),
                              const SizedBox(height: 8),
                            ],
                            if (_startTime != null) ...[
                              const Text(
                                'Started:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(DateFormat('MMM dd, yyyy HH:mm').format(_startTime!)),
                              const SizedBox(height: 8),
                            ],
                            if (_endTime != null) ...[
                              const Text(
                                'Expected End:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(DateFormat('MMM dd, yyyy HH:mm').format(_endTime!)),
                            ],
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _showMaintenanceDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isMaintenanceEnabled ? Colors.green : Colors.orange,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                _isMaintenanceEnabled ? 'Disable Maintenance' : 'Enable Maintenance',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // History Section
                  const Text(
                    'Maintenance History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_maintenanceHistory.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No maintenance history found'),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _maintenanceHistory.length,
                      itemBuilder: (context, index) {
                        final history = _maintenanceHistory[index];
                        final createdAt = history['createdAt'] as Timestamp?;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              history['isEnabled'] ? Icons.build : Icons.check_circle,
                              color: history['isEnabled'] ? Colors.orange : Colors.green,
                            ),
                            title: Text(history['reason'] ?? 'No reason'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (history['message'] != null)
                                  Text(history['message']),
                                if (createdAt != null)
                                  Text(
                                    DateFormat('MMM dd, yyyy HH:mm').format(createdAt.toDate()),
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                              ],
                            ),
                            trailing: Text(
                              history['isEnabled'] ? 'Enabled' : 'Disabled',
                              style: TextStyle(
                                color: history['isEnabled'] ? Colors.orange : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
