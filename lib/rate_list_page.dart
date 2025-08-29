// rate_list_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart'; // For CustomAppBar
import 'news_page.dart';
import 'trend_chart.dart';
import 'world_clock.dart';
import 'package:provider/provider.dart';
import 'calculator_page.dart';
import 'setting_page.dart';
import 'multi_currency_page.dart' as multi_currency; // Add prefix
import 'package:lottie/lottie.dart';
import 'support_help_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alert_service.dart';
import 'services/currency_service.dart'; // Add this import
import 'app_theme.dart';

// EmailJS Configuration (keeping user's existing service ID)
// const String _serviceId = 'service_ih5ns2r';
// const String _templateId = 'template_dxxjw09';
// const String _userId = 'AvgkUbQFSsE27b003';
// const String _accessToken = 'MI_orvD-Qi96ykAmp3zIF';

// EmailJS Templates
// final String _alertTriggeredTemplate = '''
// <!DOCTYPE html>
// <html>
// <head>
//     <style>
//         body { font-family: Arial, sans-serif; }
//         .container { max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px; }
//         .header { background-color: #1E3A8A; color: white; padding: 15px; text-align: center; border-radius: 8px 8px 0 0; }
//         .content { padding: 20px; }
//         .alert-info { background-color: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px; }
//         .currency-row { display: flex; justify-content: space-between; margin-bottom: 10px; }
//         .footer { text-align: center; padding: 15px; color: #6c757d; font-size: 12px; }
//     </style>
// </head>
// <body>
//     <div class="container">
//         <div class="header">
//             <h2>Currency Alert Triggered!</h2>
//         </div>
//         <div class="content">
//             <p>Hello,</p>
//             <p>Your currency alert has been triggered:</p>

//             <div class="alert-info">
//                 <div class="currency-row">
//                     <span><strong>Base Currency:</strong></span>
//                     <span>\${baseCurrency}</span>
//                 </div>
//                 <div class="currency-row">
//                     <span><strong>Target Currency:</strong></span>
//                     <span>\${targetCurrency}</span>
//                 </div>
//                 <div class="currency-row">
//                     <span><strong>Condition:</strong></span>
//                     <span>Rate is \${condition} \${targetRate}</span>
//                 </div>
//                 <div class="currency-row">
//                     <span><strong>Current Rate:</strong></span>
//                     <span>\${currentRate}</span>
//                 </div>
//                 <div class="currency-row">
//                     <span><strong>Time:</strong></span>
//                     <span>\${date}</span>
//                 </div>
//             </div>

//             <p>You can manage your alerts in the CurrenSee Pro app.</p>
//         </div>
//         <div class="footer">
//             <p>This is an automated message. Please do not reply.</p>
//             <p>&copy; \${year} CurrenSee Pro</p>
//         </div>
//     </div>
// </body>
// </html>
// ''';

// final String _alertRemovedTemplate = '''
// <!DOCTYPE html>
// <html>
// <head>
//     <style>
//         body { font-family: Arial, sans-serif; }
//         .container { max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px; }
//         .header { background-color: #1E3A8A; color: white; padding: 15px; text-align: center; border-radius: 8px 8px 0 0; }
//         .content { padding: 20px; }
//         .alert-info { background-color: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px; }
//         .currency-row { display: flex; justify-content: space-between; margin-bottom: 10px; }
//         .footer { text-align: center; padding: 15px; color: #6c757d; font-size: 12px; }
//     </style>
// </head>
// <body>
//     <div class="container">
//         <div class="header">
//             <h2>Currency Alert Removed</h2>
//         </div>
//         <div class="content">
//             <p>Hello,</p>
//             <p>Your currency alert has been removed:</p>

//             <div class="alert-info">
//                 <div class="currency-row">
//                     <span><strong>Base Currency:</strong></span>
//                     <span>\${baseCurrency}</span>
//                 </div>
//                 <div class="currency-row">
//                     <span><strong>Target Currency:</strong></span>
//                     <span>\${targetCurrency}</span>
//                 </div>
//                 <div class="currency-row">
//                     <span><strong>Target Rate:</strong></span>
//                     <span>\${targetRate}</span>
//                 </div>
//                 <div class="currency-row">
//                     <span><strong>Time:</strong></span>
//                     <span>\${date}</span>
//                 </div>
//             </div>

//             <p>You can set new alerts in the CurrenSee Pro app.</p>
//         </div>
//         <div class="footer">
//             <p>This is an automated message. Please do not reply.</p>
//             <p>&copy; \${year} CurrenSee Pro</p>
//         </div>
//     </div>
// </body>
// </html>
// ''';

class RateListPage extends StatefulWidget {
  const RateListPage({super.key});

  @override
  State<RateListPage> createState() => _RateListPageState();
}

class _RateListPageState extends State<RateListPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, dynamic> _exchangeRates = {};
  String _baseCurrency = 'USD';
  bool _isLoading = true;
  String _error = '';
  String _searchQuery = '';
  String _lastUpdated = '';
  List<String> _allCurrencies = [];
  List<Currency> _currencies = []; // Add this for database currencies
  final List<String> _popularCurrencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'AUD',
    'CAD',
    'CHF',
    'CNY',
    'INR',
    'SGD',
  ];
  bool _sortAscending = true;
  String _sortColumn = 'code';
  final ScrollController _scrollController = ScrollController();

  // Currency Alert Variables
  List<CurrencyAlert> _alerts = [];
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _showAlertSection = false;

  // Firebase variables
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;

  // Alert Service
  final AlertService _alertService = AlertService();

  // Comprehensive currency data
  final Map<String, Map<String, String>> _currencyData = {
    'USD': {'name': 'US Dollar', 'symbol': '\$', 'flag': '🇺🇸'},
    'EUR': {'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
    'GBP': {'name': 'British Pound', 'symbol': '£', 'flag': '🇬🇧'},
    'JPY': {'name': 'Japanese Yen', 'symbol': '¥', 'flag': '🇯🇵'},
    'AUD': {'name': 'Australian Dollar', 'symbol': 'A\$', 'flag': '🇦🇺'},
    'CAD': {'name': 'Canadian Dollar', 'symbol': 'C\$', 'flag': '🇨🇦'},
    'CHF': {'name': 'Swiss Franc', 'symbol': 'Fr', 'flag': '🇨🇭'},
    'CNY': {'name': 'Chinese Yuan', 'symbol': '¥', 'flag': '🇨🇳'},
    'INR': {'name': 'Indian Rupee', 'symbol': '₹', 'flag': '🇮🇳'},
    'SGD': {'name': 'Singapore Dollar', 'symbol': 'S\$', 'flag': '🇸🇬'},
    'NZD': {'name': 'New Zealand Dollar', 'symbol': 'NZ\$', 'flag': '🇳🇿'},
    'MXN': {'name': 'Mexican Peso', 'symbol': '\$', 'flag': '🇲🇽'},
    'BRL': {'name': 'Brazilian Real', 'symbol': 'R\$', 'flag': '🇧🇷'},
    'RUB': {'name': 'Russian Ruble', 'symbol': '₽', 'flag': '🇷🇺'},
    'KRW': {'name': 'South Korean Won', 'symbol': '₩', 'flag': '🇰🇷'},
    'TRY': {'name': 'Turkish Lira', 'symbol': '₺', 'flag': '🇹🇷'},
    'ZAR': {'name': 'South African Rand', 'symbol': 'R', 'flag': '🇿🇦'},
    'SEK': {'name': 'Swedish Krona', 'symbol': 'kr', 'flag': '🇸🇪'},
    'NOK': {'name': 'Norwegian Krone', 'symbol': 'kr', 'flag': '🇳🇴'},
    'DKK': {'name': 'Danish Krone', 'symbol': 'kr', 'flag': '🇩🇰'},
    'HKD': {'name': 'Hong Kong Dollar', 'symbol': 'HK\$', 'flag': '🇭🇰'},
    'THB': {'name': 'Thai Baht', 'symbol': '฿', 'flag': '🇹🇭'},
    'MYR': {'name': 'Malaysian Ringgit', 'symbol': 'RM', 'flag': '🇲🇾'},
    'PHP': {'name': 'Philippine Peso', 'symbol': '₱', 'flag': '🇵🇭'},
    'IDR': {'name': 'Indonesian Rupiah', 'symbol': 'Rp', 'flag': '🇮🇩'},
    'SAR': {'name': 'Saudi Riyal', 'symbol': '﷼', 'flag': '🇸🇦'},
    'AED': {'name': 'UAE Dirham', 'symbol': 'د.إ', 'flag': '🇦🇪'},
    'PLN': {'name': 'Polish Złoty', 'symbol': 'zł', 'flag': '🇵🇱'},
    'HUF': {'name': 'Hungarian Forint', 'symbol': 'Ft', 'flag': '🇭🇺'},
    'CZK': {'name': 'Czech Koruna', 'symbol': 'Kč', 'flag': '🇨🇿'},
    'ILS': {'name': 'Israeli Shekel', 'symbol': '₪', 'flag': '🇮🇱'},
    'CLP': {'name': 'Chilean Peso', 'symbol': '\$', 'flag': '🇨🇱'},
    'PKR': {'name': 'Pakistani Rupee', 'symbol': '₨', 'flag': '🇵🇰'},
    'BDT': {'name': 'Bangladeshi Taka', 'symbol': '৳', 'flag': '🇧🇩'},
    'EGP': {'name': 'Egyptian Pound', 'symbol': '£', 'flag': '🇪🇬'},
    'VND': {'name': 'Vietnamese Dong', 'symbol': '₫', 'flag': '🇻🇳'},
    'NGN': {'name': 'Nigerian Naira', 'symbol': '₦', 'flag': '🇳🇬'},
    'UAH': {'name': 'Ukrainian Hryvnia', 'symbol': '₴', 'flag': '🇺🇦'},
    'RON': {'name': 'Romanian Leu', 'symbol': 'lei', 'flag': '🇷🇴'},
    'PEN': {'name': 'Peruvian Sol', 'symbol': 'S/', 'flag': '🇵🇪'},
    'COP': {'name': 'Colombian Peso', 'symbol': '\$', 'flag': '🇨🇴'},
    'ARS': {'name': 'Argentine Peso', 'symbol': '\$', 'flag': '🇦🇷'},
    'KZT': {'name': 'Kazakhstani Tenge', 'symbol': '₸', 'flag': '🇰🇿'},
    'QAR': {'name': 'Qatari Riyal', 'symbol': '﷼', 'flag': '🇶🇦'},
    'KWD': {'name': 'Kuwaiti Dinar', 'symbol': 'د.ك', 'flag': '🇰🇼'},
    'OMR': {'name': 'Omani Rial', 'symbol': '﷼', 'flag': '🇴🇲'},
    'BHD': {'name': 'Bahraini Dinar', 'symbol': '.د.ب', 'flag': '🇧🇭'},
    'JOD': {'name': 'Jordanian Dinar', 'symbol': 'د.ا', 'flag': '🇯🇴'},
    'LKR': {'name': 'Sri Lankan Rupee', 'symbol': 'Rs', 'flag': '🇱🇰'},
    'DZD': {'name': 'Algerian Dinar', 'symbol': 'د.ج', 'flag': '🇩🇿'},
    'MAD': {'name': 'Moroccan Dirham', 'symbol': 'د.م.', 'flag': '🇲🇦'},
    'TWD': {'name': 'New Taiwan Dollar', 'symbol': 'NT\$', 'flag': '🇹🇼'},
    'CRC': {'name': 'Costa Rican Colón', 'symbol': '₡', 'flag': '🇨🇷'},
    'UYU': {'name': 'Uruguayan Peso', 'symbol': '\$', 'flag': '🇺🇾'},
    'PYG': {'name': 'Paraguayan Guarani', 'symbol': '₲', 'flag': '🇵🇾'},
    'BOB': {'name': 'Bolivian Boliviano', 'symbol': 'Bs.', 'flag': '🇧🇴'},
    'GTQ': {'name': 'Guatemalan Quetzal', 'symbol': 'Q', 'flag': '🇬🇹'},
    'DOP': {'name': 'Dominican Peso', 'symbol': 'RD\$', 'flag': '🇩🇴'},
    'HNL': {'name': 'Honduran Lempira', 'symbol': 'L', 'flag': '🇭🇳'},
    'NIO': {'name': 'Nicaraguan Córdoba', 'symbol': 'C\$', 'flag': '🇳🇮'},
    'ETB': {'name': 'Ethiopian Birr', 'symbol': 'Br', 'flag': '🇪🇹'},
    'GHS': {'name': 'Ghanaian Cedi', 'symbol': '₵', 'flag': '🇬🇭'},
    'KES': {'name': 'Kenyan Shilling', 'symbol': 'KSh', 'flag': '🇰🇪'},
    'UGX': {'name': 'Ugandan Shilling', 'symbol': 'USh', 'flag': '🇺🇬'},
    'TZS': {'name': 'Tanzanian Shilling', 'symbol': 'TSh', 'flag': '🇹🇿'},
    'XAF': {'name': 'CFA Franc BEAC', 'symbol': 'FCFA', 'flag': '🇨🇲'},
    'XOF': {'name': 'CFA Franc BCEAO', 'symbol': 'CFA', 'flag': '🇧🇯'},
    'NAD': {'name': 'Namibian Dollar', 'symbol': 'N\$', 'flag': '🇳🇦'},
    'MZN': {'name': 'Mozambican Metical', 'symbol': 'MT', 'flag': '🇲🇿'},
    'BWP': {'name': 'Botswana Pula', 'symbol': 'P', 'flag': '🇧🇼'},
    'MWK': {'name': 'Malawian Kwacha', 'symbol': 'MK', 'flag': '🇲🇼'},
    'ZMW': {'name': 'Zambian Kwacha', 'symbol': 'ZK', 'flag': '🇿🇲'},
    'ANG': {
      'name': 'Netherlands Antillean Guilder',
      'symbol': 'ƒ',
      'flag': '🇨🇼',
    },
    'TTD': {
      'name': 'Trinidad & Tobago Dollar',
      'symbol': 'TT\$',
      'flag': '🇹🇹',
    },
    'BBD': {'name': 'Barbadian Dollar', 'symbol': 'Bds\$', 'flag': '🇧🇧'},
    'JMD': {'name': 'Jamaican Dollar', 'symbol': 'J\$', 'flag': '🇯🇲'},
    'BND': {'name': 'Brunei Dollar', 'symbol': 'B\$', 'flag': '🇧🇳'},
    'FJD': {'name': 'Fijian Dollar', 'symbol': 'FJ\$', 'flag': '🇫🇯'},
    'PGK': {'name': 'Papua New Guinean Kina', 'symbol': 'K', 'flag': '🇵🇬'},
    'SBD': {'name': 'Solomon Islands Dollar', 'symbol': 'SI\$', 'flag': '🇸🇧'},
    'VUV': {'name': 'Vanuatu Vatu', 'symbol': 'VT', 'flag': '🇻🇺'},
    'WST': {'name': 'Samoan Tala', 'symbol': 'WS\$', 'flag': '🇼🇸'},
    'TOP': {'name': 'Tongan Paʻanga', 'symbol': 'T\$', 'flag': '🇹🇴'},
    'KHR': {'name': 'Cambodian Riel', 'symbol': '៛', 'flag': '🇰🇭'},
    'MMK': {'name': 'Myanmar Kyat', 'symbol': 'K', 'flag': '🇲🇲'},
    'LAK': {'name': 'Laotian Kip', 'symbol': '₭', 'flag': '🇱🇦'},
    'MVR': {'name': 'Maldivian Rufiyaa', 'symbol': 'Rf', 'flag': '🇲🇻'},
    'NPR': {'name': 'Nepalese Rupee', 'symbol': '₨', 'flag': '🇳🇵'},
    'BTN': {'name': 'Bhutanese Ngultrum', 'symbol': 'Nu.', 'flag': '🇧🇹'},
    'MNT': {'name': 'Mongolian Tögrög', 'symbol': '₮', 'flag': '🇲🇳'},
    'AFN': {'name': 'Afghan Afghani', 'symbol': '؋', 'flag': '🇦🇫'},
    'ALL': {'name': 'Albanian Lek', 'symbol': 'L', 'flag': '🇦🇱'},
    'AMD': {'name': 'Armenian Dram', 'symbol': '֏', 'flag': '🇦🇲'},
    'AZN': {'name': 'Azerbaijani Manat', 'symbol': '₼', 'flag': '🇦🇿'},
    'BAM': {
      'name': 'Bosnia-Herzegovina Convertible Mark',
      'symbol': 'KM',
      'flag': '🇧🇦',
    },
    'BGN': {'name': 'Bulgarian Lev', 'symbol': 'лв', 'flag': '🇧🇬'},
    'GEL': {'name': 'Georgian Lari', 'symbol': '₾', 'flag': '🇬🇪'},
    'ISK': {'name': 'Icelandic Króna', 'symbol': 'kr', 'flag': '🇮🇸'},
    'MDL': {'name': 'Moldovan Leu', 'symbol': 'L', 'flag': '🇲🇩'},
    'MKD': {'name': 'Macedonian Denar', 'symbol': 'ден', 'flag': '🇲🇰'},
    'RSD': {'name': 'Serbian Dinar', 'symbol': 'дин', 'flag': '🇷🇸'},
    'TJS': {'name': 'Tajikistani Somoni', 'symbol': 'ЅМ', 'flag': '🇹🇯'},
    'TMT': {'name': 'Turkmenistani Manat', 'symbol': 'm', 'flag': '🇹🇲'},
    'UZS': {'name': 'Uzbekistani Som', 'symbol': 'so\'m', 'flag': '🇺🇿'},
  };

  // Notification history
  List<Map<String, dynamic>> _notificationHistory = [];

  @override
  void initState() {
    super.initState();
    _initNotifications();
    // _initEmailJS();
    _getCurrentUser();
    _loadAlerts();
    _loadCurrenciesFromDatabase(); // Add this line
    _fetchExchangeRates();
    _loadNotificationHistory();

    // Initialize AlertService if not already initialized
    _alertService.initialize().then((_) {
      // After AlertService is initialized, check for missed alerts
      _checkForMissedAlerts();
    });
  }

  // Check for missed alerts when app reopens
  Future<void> _checkForMissedAlerts() async {
    try {
      // Trigger a manual check to catch any missed alerts
      await _alertService.manualCheckAlerts();

      // Refresh alerts list
      await _loadAlerts();

      print('Missed alerts check completed');
    } catch (e) {
      print('Error checking for missed alerts: $e');
    }
  }

  // Add method to load currencies from database
  Future<void> _loadCurrenciesFromDatabase() async {
    try {
      print('DEBUG: Starting to load currencies from database...');
      final currencies = await CurrencyService.loadCurrencies();
      print('DEBUG: CurrencyService returned ${currencies.length} currencies');

      setState(() {
        _currencies = currencies;
        // Update all currencies list with database currencies
        _allCurrencies = currencies.map((c) => c.code).toList();
      });
      print('DEBUG: Loaded ${currencies.length} currencies from database');
      print('DEBUG: Currency codes: ${_allCurrencies.take(5).toList()}...');
    } catch (e) {
      print('DEBUG: Error loading currencies from database: $e');
      // Fallback to hardcoded currencies if database fails
      setState(() {
        _allCurrencies = _currencyData.keys.toList();
      });
      print('DEBUG: Fallback to ${_allCurrencies.length} hardcoded currencies');
    }
  }

  Future<void> _loadNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('notification_history') ?? [];
    setState(() {
      _notificationHistory =
          history.map((e) => Map<String, dynamic>.from(jsonDecode(e))).toList();
    });
  }

  Future<void> _addNotificationToHistory(
    String title,
    String body,
    String soundName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final entry = {
      'title': title,
      'body': body,
      'soundName': soundName, // Add soundName to history
      'timestamp': now.toIso8601String(),
    };
    _notificationHistory.insert(0, entry);
    // Keep only last 50 notifications
    if (_notificationHistory.length > 50) {
      _notificationHistory = _notificationHistory.sublist(0, 50);
    }
    await prefs.setStringList(
      'notification_history',
      _notificationHistory.map((e) => jsonEncode(e)).toList(),
    );
    setState(() {});
  }

  // Future<void> _initEmailJS() async {
  //   try {
  //     await dotenv.load(fileName: ".env");
  //     // EmailJS doesn't need initialization in newer versions
  //     print('EmailJS ready with keys loaded');
  //   } catch (e) {
  //     print('EmailJS initialization error: $e');
  //   }
  // }

  void _getCurrentUser() {
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _initNotifications() async {
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
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
    );
  }

  // void _requestNotificationPermissions() async {
  //   final settings = await _notificationsPlugin.getNotificationSettings();
  //   if (settings.authorizationStatus != AuthorizationStatus.authorized) {
  //     await _notificationsPlugin
  //         .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
  //         ?.requestPermission();
  //   }
  // }

  Future<void> _loadAlerts() async {
    if (_currentUser == null) return;
    try {
      // Load alerts from AlertService
      _alerts = _alertService.getActiveAlerts();
      setState(() {
        _showAlertSection = _alerts.isNotEmpty;
      });
    } catch (e) {
      print("Error loading alerts: $e");
    }
  }

  Future<void> _saveAlert(CurrencyAlert alert) async {
    if (_currentUser == null) return;
    try {
      // Always get the current user's email at save time
      final userEmail = _currentUser!.email;
      final alertWithEmail = CurrencyAlert(
        id: alert.id,
        baseCurrency: alert.baseCurrency,
        targetCurrency: alert.targetCurrency,
        targetRate: alert.targetRate,
        triggerType: alert.triggerType, // Use triggerType
        createdAt: alert.createdAt,
        userId: alert.userId,
        userEmail: userEmail, // Always set userEmail
      );

      // Use AlertService to add alert
      await _alertService.addAlert(alertWithEmail);

      // Refresh alerts from service
      _alerts = _alertService.getActiveAlerts();
      setState(() {
        _showAlertSection = _alerts.isNotEmpty;
      });
    } catch (e) {
      print("Error saving alert: $e");
    }
  }

  Future<void> _removeAlert(String alertId) async {
    try {
      final alert = _alerts.firstWhere((a) => a.id == alertId);

      // Send removal email ONLY to alert.userEmail
      // final emailToSend = alert.userEmail;
      // if (emailToSend != null && emailToSend.isNotEmpty) {
      //   await _sendEmail(
      //     toEmail: emailToSend,
      //     subject: 'Currency Alert Removed',
      //     template: _alertRemovedTemplate,
      //     params: {
      //       'baseCurrency': alert.baseCurrency,
      //       'targetCurrency': alert.targetCurrency,
      //       'targetRate': alert.targetRate.toStringAsFixed(4),
      //       'date': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      //       'year': DateTime.now().year.toString(),
      //     },
      //   );
      // }

      // Remove from Firestore directly (AlertService will sync)
      await _firestore.collection('alerts').doc(alertId).delete();

      // Refresh alerts from service
      _alerts = _alertService.getActiveAlerts();
      setState(() {
        _showAlertSection = _alerts.isNotEmpty;
      });
    } catch (e) {
      print("Error removing alert: $e");
    }
  }

  void _showSetAlertDialog(String targetCurrency) {
    // Check if currency is active
    final currency =
        _getCurrencyFromDatabase(targetCurrency) ??
        _getCurrencyFromHardcoded(targetCurrency);
    if (currency != null && currency['status'] == 'inactive') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot set alerts for ${currency['name']} - Currency is temporarily blocked by team',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final currentRate = _exchangeRates[targetCurrency] ?? 0.0;
    TextEditingController rateController = TextEditingController();
    String triggerType = 'above';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Set Alert for $targetCurrency'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Current rate: 1 $_baseCurrency = ${currentRate.toStringAsFixed(4)} $targetCurrency',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: rateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target rate',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'above',
                        groupValue: triggerType,
                        onChanged:
                            (value) => setState(() => triggerType = value!),
                      ),
                      const Text('Alert when rate is above'),
                    ],
                  ),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'below',
                        groupValue: triggerType,
                        onChanged:
                            (value) => setState(() => triggerType = value!),
                      ),
                      const Text('Alert when rate is below'),
                    ],
                  ),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'equal',
                        groupValue: triggerType,
                        onChanged:
                            (value) => setState(() => triggerType = value!),
                      ),
                      const Text('Alert when rate is equal to'),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final rate = double.tryParse(rateController.text);
                    if (rate != null) {
                      _addAlert(
                        targetCurrency: targetCurrency,
                        targetRate: rate,
                        triggerType: triggerType,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Set Alert'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addAlert({
    required String targetCurrency,
    required double targetRate,
    required String triggerType,
  }) {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be signed in to set alerts')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text('Setting alert for $targetCurrency...'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    final newAlert = CurrencyAlert(
      baseCurrency: _baseCurrency,
      targetCurrency: targetCurrency,
      targetRate: targetRate,
      triggerType: triggerType,
      createdAt: DateTime.now(),
      userId: _currentUser!.uid,
      userEmail: _currentUser!.email,
    );

    _saveAlert(newAlert)
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Alert set for $targetCurrency when rate is $triggerType ${targetRate.toStringAsFixed(4)}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to set alert: $error'),
              backgroundColor: Colors.red,
            ),
          );
        });
  }

  Future<void> _fetchExchangeRates() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/$_baseCurrency'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == 'success') {
          setState(() {
            _exchangeRates = data['rates'];
            _lastUpdated = _formatDate(data['time_last_update_utc']);
            _isLoading = false;

            // Only initialize all currencies list if we don't have database currencies
            if (_currencies.isEmpty) {
              _allCurrencies = _exchangeRates.keys.toList();
              _allCurrencies.sort();
            }
          });
        } else {
          throw Exception(data['error'] ?? 'API returned error');
        }
      } else {
        throw Exception('Failed to load: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String utcDate) {
    try {
      return utcDate.replaceFirst('UTC', '').trim();
    } catch (e) {
      return utcDate;
    }
  }

  void _navigateAndClose(BuildContext context, Widget page) {
    Navigator.pop(context); // Close drawer
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
  }

  void _changeBaseCurrency(String currency) {
    setState(() {
      _baseCurrency = currency;
    });
    _fetchExchangeRates();

    // Update AlertService base currency
    _alertService.updateBaseCurrency(currency);
  }

  // Manual check alerts
  void _manualCheckAlerts() async {
    if (_alerts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active alerts to check')),
      );
      return;
    }

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Checking alerts...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Trigger manual check in AlertService
      await _alertService.manualCheckAlerts();

      // Refresh alerts list
      await _loadAlerts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alerts checked successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking alerts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sortBy(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  List<Map<String, dynamic>> _getFilteredRates() {
    List<Map<String, dynamic>> rates = [];

    // Use database currencies as the primary source, fallback to API currencies
    final availableCurrencies =
        _currencies.isNotEmpty
            ? _currencies.map((c) => c.code).toList()
            : _allCurrencies;

    // Create a list of currencies to display
    final displayCurrencies =
        _searchQuery.isEmpty
            ? availableCurrencies
            : availableCurrencies
                .where(
                  (code) =>
                      code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      (_getCurrencyName(code)?.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ??
                          false),
                )
                .toList();

    for (final code in displayCurrencies) {
      final rate = _exchangeRates[code] ?? 0.0; // Use 0.0 if no rate available

      // Get currency info from database or fallback to hardcoded data
      final currency =
          _getCurrencyFromDatabase(code) ?? _getCurrencyFromHardcoded(code);
      if (currency != null) {
        rates.add({
          'code': code,
          'rate': rate,
          'name': currency['name']!,
          'symbol': currency['symbol']!,
          'flag': currency['flag']!,
          'status': currency['status'] ?? 'active', // Add status
        });
      }
    }

    // Sorting logic
    rates.sort((a, b) {
      int comparison = 0;
      switch (_sortColumn) {
        case 'name':
          comparison = a['name'].compareTo(b['name']);
          break;
        case 'rate':
          comparison = a['rate'].compareTo(b['rate']);
          break;
        case 'code':
        default:
          comparison = a['code'].compareTo(b['code']);
      }
      return _sortAscending ? comparison : -comparison;
    });

    return rates;
  }

  // Helper method to get currency from database
  Map<String, String>? _getCurrencyFromDatabase(String code) {
    try {
      final currency = _currencies.firstWhere((c) => c.code == code);

      return {
        'name': currency.name,
        'symbol': currency.symbol,
        'flag': currency.flag,
        'status': currency.status,
      };
    } catch (e) {
      // Currency not found in database
      return null;
    }
  }

  // Helper method to get currency from hardcoded data
  Map<String, String>? _getCurrencyFromHardcoded(String code) {
    final data = _currencyData[code];
    if (data != null) {
      return {
        'name': data['name']!,
        'symbol': data['symbol']!,
        'flag': data['flag']!,
        'status': 'active', // Default to active for hardcoded data
      };
    }
    return null;
  }

  // Helper method to get currency name
  String? _getCurrencyName(String code) {
    return _getCurrencyFromDatabase(code)?['name'] ??
        _getCurrencyFromHardcoded(code)?['name'];
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  // FIX: Build dropdown items without duplicates
  List<DropdownMenuItem<String>> _buildDropdownItems() {
    final items = <DropdownMenuItem<String>>[];
    final addedCurrencies = <String>{};

    // Use database currencies if available, otherwise fallback to API currencies
    final availableCurrencies =
        _currencies.isNotEmpty
            ? _currencies.map((c) => c.code).toList()
            : _allCurrencies;

    // Add popular currencies
    for (final currency in _popularCurrencies) {
      if (availableCurrencies.contains(currency)) {
        items.add(_buildDropdownItem(currency));
        addedCurrencies.add(currency);
      }
    }

    // Add divider only if we have both popular and other currencies
    if (items.isNotEmpty &&
        availableCurrencies.length > _popularCurrencies.length) {
      items.add(
        const DropdownMenuItem<String>(
          value: 'divider',
          enabled: false,
          child: Divider(height: 1),
        ),
      );
    }

    // Add remaining currencies
    for (final currency in availableCurrencies) {
      if (!addedCurrencies.contains(currency)) {
        items.add(_buildDropdownItem(currency));
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final filteredRates = _getFilteredRates();
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        title: 'Rate List',
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Professional Drawer Header
              Container(
                height: 180,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Icon with subtle animation
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Lottie.asset(
                          'assets/Menu Icon.json', // Your app icon animation
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // App Name
                    const Text(
                      'CurrenSee Pro',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                    // Version text with fade-in animation
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: const Text(
                            'Version 2.0.0',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Menu Items
              _buildDrawerItem(
                context,
                icon: Icons.currency_exchange,
                title: 'Currency Converter',
                onTap: () => _navigateAndClose(context, const MainScreen()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.newspaper,
                title: 'Market News',
                onTap: () => _navigateAndClose(context, const NewsScreen()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.calculate,
                title: 'Multi-Currency',
                onTap:
                    () => _navigateAndClose(
                      context,
                      const multi_currency.MultiCurrencyConverter(),
                    ),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.trending_up,
                title: 'Trend Analysis',
                onTap:
                    () => _navigateAndClose(context, const CurrencyChartPage()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.timer,
                title: 'World Clock',
                onTap: () => _navigateAndClose(context, const WorldClockPage()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.list_alt,
                title: 'Rate List',
                onTap: () => _navigateAndClose(context, const RateListPage()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.calculate_outlined,
                title: 'Calculator',
                onTap:
                    () => _navigateAndClose(context, const CalculatorsScreen()),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 16),
              // Settings Section
              _buildDrawerItem(
                context,
                icon: Icons.settings,
                title: 'Settings',
                onTap:
                    () => _navigateAndClose(
                      context,
                      SettingsPage(
                        onThemeChanged: (isDark) {
                          Provider.of<AppSettings>(
                            context,
                            listen: false,
                          ).setDarkMode(isDark);
                        },
                        onDecimalChanged: (decimalPlaces) {
                          Provider.of<AppSettings>(
                            context,
                            listen: false,
                          ).setDecimalPlaces(decimalPlaces);
                        },
                        onBaseCurrencyChanged: (currency) {
                          Provider.of<AppSettings>(
                            context,
                            listen: false,
                          ).setBaseCurrency(currency);
                        },
                        onAutoUpdateChanged: (autoUpdate) {
                          Provider.of<AppSettings>(
                            context,
                            listen: false,
                          ).setAutoUpdateRates(autoUpdate);
                        },
                        onBiometricChanged: (useBiometric) {
                          Provider.of<AppSettings>(
                            context,
                            listen: false,
                          ).setBiometricAuth(useBiometric);
                        },
                        onVibrationChanged: (vibration) {
                          Provider.of<AppSettings>(
                            context,
                            listen: false,
                          ).setHapticFeedback(vibration);
                        },
                        onCalculatorChanged: (showCalculator) {
                          Provider.of<AppSettings>(
                            context,
                            listen: false,
                          ).setShowCalculator(showCalculator);
                        },
                      ),
                    ),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.help_center,
                title: 'Help & Support',
                onTap:
                    () => _navigateAndClose(context, const SupportHelpScreen()),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 16),
              _buildDrawerItem(
                context,
                icon: Icons.logout,
                title: 'Logout',
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),

      body: Column(
        children: [
          // Base currency selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: theme.colorScheme.primary.withOpacity(0.1),
            child: Row(
              children: [
                Text('Base Currency:', style: theme.textTheme.titleMedium),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: DropdownButton<String>(
                      value: _baseCurrency,
                      isExpanded: true,
                      underline: const SizedBox(),
                      dropdownColor: theme.colorScheme.surface,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: theme.colorScheme.primary,
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      // FIX: Use the deduplicated items list
                      items: _buildDropdownItems(),
                      onChanged: (value) {
                        if (value != null && value != 'divider') {
                          _changeBaseCurrency(value);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search and info bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText:
                        'Search ${_currencies.isNotEmpty ? _currencies.length : _allCurrencies.length} currencies...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed:
                                  () => setState(() => _searchQuery = ''),
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                if (_lastUpdated.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Last updated: $_lastUpdated',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Sorting header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () => _sortBy('code'),
                    child: Row(
                      children: [
                        Text('Code', style: theme.textTheme.titleSmall),
                        if (_sortColumn == 'code')
                          Icon(
                            _sortAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () => _sortBy('name'),
                    child: Row(
                      children: [
                        Text('Currency', style: theme.textTheme.titleSmall),
                        if (_sortColumn == 'name')
                          Icon(
                            _sortAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () => _sortBy('rate'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Rate', style: theme.textTheme.titleSmall),
                        if (_sortColumn == 'rate')
                          Icon(
                            _sortAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Alerts Section
          if (_showAlertSection && _alerts.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Active Alerts',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      // Manual check button
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => _manualCheckAlerts(),
                        tooltip: 'Check alerts manually',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._alerts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final alert = entry.value;
                    final currencyInfo =
                        _getCurrencyFromDatabase(alert.targetCurrency) ??
                        _getCurrencyFromHardcoded(alert.targetCurrency);
                    final isInactive = currencyInfo?['status'] == 'inactive';

                    return Opacity(
                      opacity: isInactive ? 0.6 : 1.0,
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color:
                            isInactive
                                ? theme.colorScheme.error.withOpacity(0.1)
                                : null,
                        child: ListTile(
                          leading: Text(
                            currencyInfo?['flag'] ?? '🏳',
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            '1 ${alert.baseCurrency} ${alert.triggerType == 'above'
                                ? '≥'
                                : alert.triggerType == 'below'
                                ? '≤'
                                : '='} ${alert.targetRate.toStringAsFixed(4)} ${alert.targetCurrency}',
                            style: TextStyle(
                              color:
                                  isInactive ? theme.colorScheme.error : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Created: ${DateFormat('MMM dd, HH:mm').format(alert.createdAt)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (isInactive)
                                Text(
                                  'Currency is currently blocked',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeAlert(alert.id!),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

          // Rates list
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error.isNotEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        onPressed: _fetchExchangeRates,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchExchangeRates,
                child: ListView.separated(
                  controller: _scrollController,
                  itemCount: filteredRates.length,
                  separatorBuilder:
                      (context, index) => Divider(
                        height: 1,
                        color: theme.dividerColor.withOpacity(0.2),
                      ),
                  itemBuilder: (context, index) {
                    final currency = filteredRates[index];
                    final isInactive = currency['status'] == 'inactive';

                    return Opacity(
                      opacity: isInactive ? 0.6 : 1.0,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                isInactive
                                    ? theme.colorScheme.error.withOpacity(0.1)
                                    : theme.colorScheme.primary.withOpacity(
                                      0.1,
                                    ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              currency['flag'],
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              currency['code'],
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    isInactive
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.onSurface,
                              ),
                            ),
                            if (isInactive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.error,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'BLOCKED',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currency['name'],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                            if (isInactive)
                              Text(
                                'Temporarily blocked by team',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isInactive) // Only show alert button for active currencies
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined),
                                onPressed:
                                    () => _showSetAlertDialog(currency['code']),
                                tooltip: 'Set Alert',
                              ),
                            RichText(
                              textAlign: TextAlign.end,
                              text: TextSpan(
                                style: theme.textTheme.titleMedium,
                                children: [
                                  TextSpan(
                                    text: currency['symbol'],
                                    style: TextStyle(
                                      color:
                                          isInactive
                                              ? theme.colorScheme.error
                                              : theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(text: ' '),
                                  TextSpan(
                                    text: currency['rate'].toStringAsFixed(4),
                                    style: TextStyle(
                                      color:
                                          isInactive
                                              ? theme.colorScheme.error
                                              : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap:
                            isInactive
                                ? () {
                                  // Show message when user taps on inactive currency
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${currency['name']} is temporarily blocked by the team',
                                      ),
                                      backgroundColor: Colors.orange,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                                : null, // No action for active currencies
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // FloatingActionButton(
          //   onPressed: _debugEmailJS,
          //   mini: true,
          //   backgroundColor: Colors.blue,
          //   tooltip: 'Debug EmailJS',
          //   child: const Icon(Icons.bug_report, color: Colors.white),
          // ),
          // const SizedBox(height: 8),
          // FloatingActionButton(
          //   onPressed: _testEmail,
          //   mini: true,
          //   backgroundColor: Colors.orange,
          //   tooltip: 'Test Email',
          //   child: const Icon(Icons.email, color: Colors.white),
          // ),
          // const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: _scrollToTop,
            mini: true,
            backgroundColor: theme.colorScheme.secondary,
            child: Icon(
              Icons.arrow_upward,
              color: theme.colorScheme.onSecondary,
            ),
          ),
        ],
      ),
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(String currency) {
    final theme = Theme.of(context);
    final currencyInfo =
        _getCurrencyFromDatabase(currency) ??
        _getCurrencyFromHardcoded(currency);
    final isInactive = currencyInfo?['status'] == 'inactive';

    return DropdownMenuItem<String>(
      value: currency,
      enabled: !isInactive, // Disable inactive currencies in dropdown
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(
              currencyInfo?['flag'] ?? '🏳',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 12),
            Text(
              currency,
              style: theme.textTheme.bodyLarge?.copyWith(
                color:
                    isInactive
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                currencyInfo?['name'] ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      isInactive
                          ? theme.colorScheme.error.withOpacity(0.7)
                          : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isInactive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'BLOCKED',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Future<void> _sendEmail({
  //   required String toEmail,
  //   required String subject,
  //   required String template,
  //   required Map<String, String> params,
  // }) async {
  //   try {
  //     // Simple email validation (regex)
  //     final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}");
  //     if (!emailRegex.hasMatch(toEmail)) {
  //       throw Exception('Invalid email address');
  //     }
  //     String htmlBody = template;
  //     params.forEach((key, value) {
  //       htmlBody = htmlBody.replaceAll('{$key}', value);
  //     });

  //     // Proper EmailJS API request with Authorization header
  //     const serviceId = 'service_ih5ns2r';
  //     const templateId = 'template_dxxjw09';
  //     const userId = 'AvgkUbQFSsE27b003';
  //     const apiKey = 'MI_orvD-Qi96ykAmp3zIF';

  //     final response = await http.post(
  //       Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer $apiKey',
  //       },
  //       body: json.encode({
  //         'service_id': serviceId,
  //         'template_id': templateId,
  //         'user_id': userId,
  //         'template_params': {
  //           'subject': subject,
  //           'html_body': htmlBody,
  //           'to_email': toEmail,
  //         },
  //       }),
  //     );

  //     if (response.statusCode != 200) {
  //       throw Exception(
  //         'EmailJS Error ${response.statusCode}: ${response.body}',
  //       );
  //     }
  //     print('Email sent successfully to $toEmail');
  //   } catch (error) {
  //     print('Failed to send email: $error');
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Email error: ${error.toString()}'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }

  // Debug function to check EmailJS config
  // void _debugEmailJS() {
  //   print('=== EmailJS Configuration ===');
  //   print('Service ID: $_serviceId');
  //   print('Template ID: $_templateId');
  //   print('User ID: $_userId');
  //   print('Access Token: $_accessToken');
  //   print('Current User Email: ${_currentUser?.email}');
  //   print('============================');

  //   if (mounted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Config: $_serviceId, $_templateId'),
  //         backgroundColor: Colors.blue,
  //       ),
  //     );
  //   }
  // }

  // Test function - Add this for testing emails
  // Future<void> _testEmail() async {
  //   if (_currentUser?.email != null) {
  //     try {
  //       await _sendEmail(
  //         toEmail: _currentUser!.email!,
  //         subject: 'Test Email - CurrenSee Pro',
  //         template:
  //             '<p>This is a <strong>test email</strong> from CurrenSee Pro!</p>',
  //         params: {'year': DateTime.now().year.toString()},
  //       );
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('✅ Test email sent! Check your inbox'),
  //             backgroundColor: Colors.green,
  //           ),
  //         );
  //       }
  //     } catch (error) {
  //       print('Test email failed: $error');
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text('❌ Email failed: ${error.toString()}'),
  //             backgroundColor: Colors.red,
  //           ),
  //         );
  //       }
  //     }
  //   } else {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('❌ Please login with email first'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }
}

Widget _buildDrawerItem(
  BuildContext context, {
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Material(
      borderRadius: BorderRadius.circular(12),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withOpacity(0.1),
        highlightColor: Colors.white.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
            ],
          ),
        ),
      ),
    ),
  );
}
