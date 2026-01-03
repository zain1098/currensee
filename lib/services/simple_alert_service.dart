import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CurrencyAlert {
  final String? id;
  final String userId;
  final String baseCurrency;
  final String targetCurrency;
  final double targetRate;
  final String triggerType; // 'above', 'below', 'equal'
  final DateTime createdAt;
  final String? userEmail;

  CurrencyAlert({
    this.id,
    required this.userId,
    required this.baseCurrency,
    required this.targetCurrency,
    required this.targetRate,
    required this.triggerType,
    required this.createdAt,
    this.userEmail,
  });

  factory CurrencyAlert.fromMap(String id, Map<String, dynamic> data) {
    return CurrencyAlert(
      id: id,
      userId: data['userId'] ?? '',
      baseCurrency: data['baseCurrency'] ?? 'USD',
      targetCurrency: data['targetCurrency'] ?? '',
      targetRate: (data['targetRate'] ?? 0.0).toDouble(),
      triggerType: data['triggerType'] ?? 'above',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userEmail: data['userEmail'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'baseCurrency': baseCurrency,
      'targetCurrency': targetCurrency,
      'targetRate': targetRate,
      'triggerType': triggerType,
      'createdAt': Timestamp.fromDate(createdAt),
      'userEmail': userEmail,
    };
  }
}

class SimpleAlertService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    print('SimpleAlertService initialized');
  }

  void checkForMissedAlerts() {
    print('Checking for missed alerts');
  }

  /// Add new alert (backend will handle monitoring)
  static Future<void> addAlert(CurrencyAlert alert) async {
    try {
      await _firestore.collection('alerts').add(alert.toMap());
      print('✅ Alert added - Backend will monitor it');
    } catch (e) {
      print('❌ Error adding alert: $e');
      rethrow;
    }
  }

  /// Get user's active alerts
  static Stream<List<CurrencyAlert>> getUserAlerts() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('alerts')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CurrencyAlert.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Remove alert
  static Future<void> removeAlert(String alertId) async {
    try {
      await _firestore.collection('alerts').doc(alertId).delete();
      print('✅ Alert removed');
    } catch (e) {
      print('❌ Error removing alert: $e');
    }
  }
}