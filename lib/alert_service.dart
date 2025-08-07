import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _alertCheckTimer;
  bool _isInitialized = false;
  String _baseCurrency = 'USD';
  Map<String, dynamic> _currentRates = {};
  List<CurrencyAlert> _activeAlerts = [];
  User? _currentUser;
  DateTime? _lastCheckTime;

  // Initialize the alert service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize notifications
      await _initializeNotifications();

      // Get current user
      _currentUser = FirebaseAuth.instance.currentUser;

      // Load user preferences
      await _loadUserPreferences();

      // Load active alerts
      await _loadActiveAlerts();

      // Check for missed alerts when app reopens
      await _checkForMissedAlerts();

      // Start background monitoring
      _startBackgroundMonitoring();

      _isInitialized = true;
      debugPrint('AlertService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AlertService: $e');
    }
  }

  // Initialize local notifications
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        debugPrint('Notification tapped: ${response.payload}');
      },
    );
  }

  // Load user preferences
  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _baseCurrency = prefs.getString('baseCurrency') ?? 'USD';
    _lastCheckTime = DateTime.tryParse(prefs.getString('lastAlertCheck') ?? '');
  }

  // Load active alerts from Firestore
  Future<void> _loadActiveAlerts() async {
    if (_currentUser == null) return;

    try {
      final querySnapshot =
          await _firestore
              .collection('alerts')
              .where('userId', isEqualTo: _currentUser!.uid)
              .get();

      _activeAlerts =
          querySnapshot.docs
              .map((doc) => CurrencyAlert.fromMap(doc.id, doc.data()))
              .toList();

      debugPrint('Loaded ${_activeAlerts.length} active alerts');
    } catch (e) {
      debugPrint('Error loading alerts: $e');
    }
  }

  // Check for missed alerts when app reopens
  Future<void> _checkForMissedAlerts() async {
    if (_currentUser == null) return;

    try {
      debugPrint('Checking for missed alerts...');

      // Get alert history since last check
      final lastCheck =
          _lastCheckTime ?? DateTime.now().subtract(const Duration(hours: 1));

      final historyQuery =
          await _firestore
              .collection('alert_history')
              .where('userId', isEqualTo: _currentUser!.uid)
              .where('triggeredAt', isGreaterThan: lastCheck.toIso8601String())
              .orderBy('triggeredAt', descending: true)
              .get();

      if (historyQuery.docs.isNotEmpty) {
        debugPrint('Found ${historyQuery.docs.length} missed alerts');

        // Show notification for each missed alert
        for (final doc in historyQuery.docs) {
          final data = doc.data();
          await _showMissedAlertNotification(data);
        }
      }

      // Update last check time
      _lastCheckTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'lastAlertCheck',
        _lastCheckTime!.toIso8601String(),
      );
    } catch (e) {
      debugPrint('Error checking for missed alerts: $e');
    }
  }

  // Show notification for missed alert
  Future<void> _showMissedAlertNotification(
    Map<String, dynamic> alertData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String selectedSound =
          prefs.getString('notificationSound') ?? 'notification.mp3';

      String soundName = selectedSound.replaceAll('.mp3', '');
      String channelId = 'missed_alerts_$soundName';

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            channelId,
            'Missed Currency Alerts',
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'ticker',
            sound: RawResourceAndroidNotificationSound(soundName),
          );

      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentSound: true,
        sound: selectedSound,
      );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final title = 'Missed Currency Alert!';
      final body =
          alertData['notificationBody'] ??
          'A currency alert was triggered while you were away';

      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        platformDetails,
      );

      debugPrint('Missed alert notification shown: $title');
    } catch (e) {
      debugPrint('Error showing missed alert notification: $e');
    }
  }

  // Start background monitoring
  void _startBackgroundMonitoring() {
    // Check alerts every 2 minutes for more responsive alerts
    _alertCheckTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _checkAlertsInBackground();
    });

    // Also check immediately
    _checkAlertsInBackground();

    debugPrint('Background monitoring started - checking every 2 minutes');
  }

  // Check alerts in background
  Future<void> _checkAlertsInBackground() async {
    try {
      debugPrint('Checking alerts in background...');

      // Fetch latest rates
      await _fetchLatestRates();

      debugPrint('Current rates: $_currentRates');
      debugPrint('Active alerts: ${_activeAlerts.length}');

      // Check each alert
      for (final alert in _activeAlerts.toList()) {
        if (alert.baseCurrency != _baseCurrency) {
          debugPrint(
            'Skipping alert - base currency mismatch: ${alert.baseCurrency} vs $_baseCurrency',
          );
          continue;
        }

        final currentRate = _currentRates[alert.targetCurrency];
        if (currentRate == null) {
          debugPrint(
            'Skipping alert - no rate found for ${alert.targetCurrency}',
          );
          continue;
        }

        debugPrint(
          'Checking alert: ${alert.targetCurrency} - Target: ${alert.targetRate} (${alert.triggerType}), Current: $currentRate',
        );

        final shouldTrigger =
            (() {
              if (alert.triggerType == 'above') {
                return currentRate > alert.targetRate;
              } else if (alert.triggerType == 'below') {
                return currentRate < alert.targetRate;
              } else if (alert.triggerType == 'equal') {
                return (currentRate - alert.targetRate).abs() < 0.0001;
              } else {
                return false;
              }
            })();

        if (shouldTrigger) {
          debugPrint(
            'Alert triggered! ${alert.targetCurrency} rate is ${alert.triggerType} target',
          );
          await _triggerAlertNotification(alert, currentRate);
          await _removeAlert(alert.id!);
        } else {
          debugPrint('Alert not triggered - condition not met');
        }
      }

      // Update last check time
      _lastCheckTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'lastAlertCheck',
        _lastCheckTime!.toIso8601String(),
      );
    } catch (e) {
      debugPrint('Error checking alerts in background: $e');
    }
  }

  // Fetch latest exchange rates
  Future<void> _fetchLatestRates() async {
    try {
      debugPrint('Fetching latest rates for $_baseCurrency...');

      final response = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/$_baseCurrency'),
      );

      debugPrint('API Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == 'success') {
          _currentRates = data['rates'];
          debugPrint(
            'Successfully fetched ${_currentRates.length} rates for $_baseCurrency',
          );
          debugPrint('Sample rates: ${_currentRates.entries.take(5).toList()}');
        } else {
          debugPrint('API returned error: ${data['error-type']}');
        }
      } else {
        debugPrint('API request failed with status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching rates: $e');
    }
  }

  // Trigger alert notification
  Future<void> _triggerAlertNotification(
    CurrencyAlert alert,
    double currentRate,
  ) async {
    try {
      // Get user's preferred notification sound
      final prefs = await SharedPreferences.getInstance();
      String selectedSound =
          prefs.getString('notificationSound') ?? 'notification.mp3';

      // Validate sound file exists
      const availableSounds = [
        'zapsplat_multimedia_notification_bell_chime_ring_alert_001_41155.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_002_41156.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_003_41157.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_004_41158.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_005_41159.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_006_41160.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_007_41161.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_008_41162.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_009_41163.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_010_41164.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_011_41165.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_012_41166.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_013_41167.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_014_41168.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_015_41169.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_016_41170.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_017_41171.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_018_41181.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_019_41182.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_020_41183.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_021_41184.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_022_41185.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_023_41186.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_024_41187.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_025_41188.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_026_41189.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_027_41190.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_028_41172.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_029_41173.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_030_41191.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_031_41192.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_032_41193.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_033_41194.mp3',
        'zapsplat_multimedia_notification_bell_chime_ring_alert_034_41195.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_001_41174.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_002_41175.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_003_41196.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_004_41197.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_005_41198.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_006_41199.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_007_41200.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_008_41201.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_009_41202.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_010_41203.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_011_41204.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_012_41205.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_013_41206.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_014_41207.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_015_41208.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_016_41209.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_017_41210.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_018_41211.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_019_41112.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_020_41213.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_021_41214.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_022_41215.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_023_41216.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_024_41217.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_025_41218.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_026_41219.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_027_41220.mp3',
        'zapsplat_multimedia_notification_bell_glassy_chime_028_41221.mp3',
        'notification.mp3',
      ];

      if (!availableSounds.contains(selectedSound)) {
        selectedSound = availableSounds.first;
      }

      String soundName = selectedSound.replaceAll('.mp3', '');
      String channelId = 'currency_alerts_$soundName';

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            channelId,
            'Currency Rate Alerts',
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'ticker',
            sound: RawResourceAndroidNotificationSound(soundName),
          );

      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentSound: true,
        sound: selectedSound,
      );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final title = 'Currency Rate Alert!';
      final body =
          '1 ${alert.baseCurrency} = ${currentRate.toStringAsFixed(4)} ${alert.targetCurrency} '
          '(${alert.triggerType} ${alert.targetRate})';

      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        platformDetails,
      );

      // Add to notification history
      await _addNotificationToHistory(
        alert,
        currentRate,
        title,
        body,
        selectedSound,
      );

      // Save to alert history in Firestore
      await _saveAlertHistory(alert, currentRate, title, body, selectedSound);

      // Play sound for web
      if (kIsWeb) {
        final player = AudioPlayer();
        await player.play(AssetSource('sounds/$selectedSound'));
      }

      debugPrint('Alert notification triggered: $title');
    } catch (e) {
      debugPrint('Error triggering alert notification: $e');
    }
  }

  // Add notification to history
  Future<void> _addNotificationToHistory(
    CurrencyAlert alert,
    double currentRate,
    String title,
    String body,
    String soundName,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('notification_history') ?? [];

      final entry = {
        'title': title,
        'body': body,
        'soundName': soundName,
        'timestamp': DateTime.now().toIso8601String(),
      };

      history.insert(0, jsonEncode(entry));

      // Keep only last 50 notifications
      if (history.length > 50) {
        history.removeRange(50, history.length);
      }

      await prefs.setStringList('notification_history', history);
    } catch (e) {
      debugPrint('Error adding notification to history: $e');
    }
  }

  // Save alert history to Firestore
  Future<void> _saveAlertHistory(
    CurrencyAlert alert,
    double currentRate,
    String title,
    String body,
    String sound,
  ) async {
    try {
      await _firestore.collection('alert_history').add({
        'userId': alert.userId,
        'alertId': alert.id,
        'baseCurrency': alert.baseCurrency,
        'targetCurrency': alert.targetCurrency,
        'targetRate': alert.targetRate,
        'triggerType': alert.triggerType,
        'createdAt': alert.createdAt.toIso8601String(),
        'triggeredAt': DateTime.now().toIso8601String(),
        'currentRate': currentRate,
        'notificationTitle': title,
        'notificationBody': body,
        'sound': sound,
      });
    } catch (e) {
      debugPrint('Error saving alert history: $e');
    }
  }

  // Remove alert from Firestore and local list
  Future<void> _removeAlert(String alertId) async {
    try {
      await _firestore.collection('alerts').doc(alertId).delete();
      _activeAlerts.removeWhere((alert) => alert.id == alertId);
      debugPrint('Alert removed: $alertId');
    } catch (e) {
      debugPrint('Error removing alert: $e');
    }
  }

  // Add new alert
  Future<void> addAlert(CurrencyAlert alert) async {
    try {
      final docRef = await _firestore.collection('alerts').add(alert.toMap());
      final newAlert = CurrencyAlert(
        id: docRef.id,
        baseCurrency: alert.baseCurrency,
        targetCurrency: alert.targetCurrency,
        targetRate: alert.targetRate,
        triggerType: alert.triggerType,
        createdAt: alert.createdAt,
        userId: alert.userId,
        userEmail: alert.userEmail,
      );

      _activeAlerts.add(newAlert);
      debugPrint('Alert added: ${newAlert.id}');

      // Immediately check if this alert should be triggered
      await _checkSpecificAlert(newAlert);
    } catch (e) {
      debugPrint('Error adding alert: $e');
    }
  }

  // Check a specific alert immediately
  Future<void> _checkSpecificAlert(CurrencyAlert alert) async {
    try {
      debugPrint(
        'Checking specific alert immediately: ${alert.targetCurrency}',
      );

      // Fetch latest rates if not available
      if (_currentRates.isEmpty) {
        await _fetchLatestRates();
      }

      if (alert.baseCurrency != _baseCurrency) {
        debugPrint('Alert base currency mismatch, skipping immediate check');
        return;
      }

      final currentRate = _currentRates[alert.targetCurrency];
      if (currentRate == null) {
        debugPrint(
          'No current rate found for ${alert.targetCurrency}, skipping immediate check',
        );
        return;
      }

      debugPrint(
        'Immediate check: ${alert.targetCurrency} - Target: ${alert.targetRate} (${alert.triggerType}), Current: $currentRate',
      );

      final shouldTrigger =
          (() {
            if (alert.triggerType == 'above') {
              return currentRate > alert.targetRate;
            } else if (alert.triggerType == 'below') {
              return currentRate < alert.targetRate;
            } else if (alert.triggerType == 'equal') {
              return (currentRate - alert.targetRate).abs() < 0.0001;
            } else {
              return false;
            }
          })();

      if (shouldTrigger) {
        debugPrint(
          'Alert triggered immediately! ${alert.targetCurrency} rate is ${alert.triggerType} target',
        );
        await _triggerAlertNotification(alert, currentRate);
        await _removeAlert(alert.id!);
      } else {
        debugPrint('Alert not triggered immediately - condition not met');
      }
    } catch (e) {
      debugPrint('Error checking specific alert: $e');
    }
  }

  // Update base currency
  Future<void> updateBaseCurrency(String newBaseCurrency) async {
    _baseCurrency = newBaseCurrency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('baseCurrency', newBaseCurrency);

    // Refresh rates with new base currency
    await _fetchLatestRates();
  }

  // Get active alerts
  List<CurrencyAlert> getActiveAlerts() {
    return List.from(_activeAlerts);
  }

  // Manual check alerts (public method)
  Future<void> manualCheckAlerts() async {
    debugPrint('Manual alert check triggered');
    await _checkAlertsInBackground();
  }

  // Check for missed alerts when app reopens (public method)
  Future<void> checkForMissedAlerts() async {
    debugPrint('Checking for missed alerts manually');
    await _checkForMissedAlerts();
  }

  // Force refresh alerts from Firestore
  Future<void> refreshAlerts() async {
    debugPrint('Refreshing alerts from Firestore');
    await _loadActiveAlerts();
    await _checkAlertsInBackground();
  }

  // Stop background monitoring
  void stopBackgroundMonitoring() {
    _alertCheckTimer?.cancel();
    _alertCheckTimer = null;
    _isInitialized = false;
    debugPrint('AlertService background monitoring stopped');
  }

  // Dispose resources
  void dispose() {
    stopBackgroundMonitoring();
  }
}

// Update CurrencyAlert model
class CurrencyAlert {
  final String? id;
  final String baseCurrency;
  final String targetCurrency;
  final double targetRate;
  final String triggerType; // "above", "below", "equal"
  final DateTime createdAt;
  final String userId;
  final String? userEmail;

  CurrencyAlert({
    this.id,
    required this.baseCurrency,
    required this.targetCurrency,
    required this.targetRate,
    required this.triggerType,
    required this.createdAt,
    required this.userId,
    this.userEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'baseCurrency': baseCurrency,
      'targetCurrency': targetCurrency,
      'targetRate': targetRate,
      'triggerType': triggerType,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'userEmail': userEmail,
    };
  }

  factory CurrencyAlert.fromMap(String id, Map<String, dynamic> map) {
    // Backward compatibility: if triggerType is missing, use isAbove
    String triggerType =
        map['triggerType'] ??
        (map['isAbove'] == null
            ? 'above'
            : (map['isAbove'] == true ? 'above' : 'below'));
    return CurrencyAlert(
      id: id,
      baseCurrency: map['baseCurrency'],
      targetCurrency: map['targetCurrency'],
      targetRate: map['targetRate'],
      triggerType: triggerType,
      createdAt: DateTime.parse(map['createdAt']),
      userId: map['userId'],
      userEmail: map['userEmail'],
    );
  }
}
