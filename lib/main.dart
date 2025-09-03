import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'home_page.dart';
import 'news_page.dart';
import 'multi_currency_page.dart';
import 'trend_chart.dart';
import 'world_clock.dart';
import 'rate_list_page.dart';
import 'voice_service.dart';
import 'package:provider/provider.dart';
import 'calculator_page.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'contact_form_screen.dart';
import 'welcome_page.dart';
import 'login.dart';
import 'signup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'setting_page.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'forget_password.dart';
import 'chat_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'network_error_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'currency_chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'currency_widget.dart';
import 'watchlist_widget.dart';
import 'converter_widget.dart';
import 'alert_service.dart';
import 'messaging_service.dart';
import 'services/user_status_service.dart';
import 'services/maintenance_service.dart';
import 'services/connectivity_service.dart';
import 'app_theme.dart';
import 'task_screen.dart';
import 'services/notification_manager.dart';
import 'services/task_service.dart';
import 'services/app_version_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  // Set Firebase Auth persistence for all platforms
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }

  // Initialize notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await FlutterLocalNotificationsPlugin().initialize(initializationSettings);

  // Listen to auth state changes for email verification
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null && user.emailVerified) {
      FirebaseFirestore.instance.collection('currentUser').doc(user.uid).update(
        {
          'isEmailVerified': true,
          'emailVerifiedAt': FieldValue.serverTimestamp(),
        },
      );
    }
  });

  // Initialize AlertService for background monitoring
  try {
    await AlertService().initialize();
    print('AlertService initialized successfully');
  } catch (e) {
    print('Error initializing AlertService: $e');
  }

  // Initialize MessagingService for push notifications
  try {
    await MessagingService().initialize();
    print('MessagingService initialized successfully');
  } catch (e) {
    print('Error initializing MessagingService: $e');
  }

  // Initialize NotificationManager for task notifications
  try {
    await NotificationManager.initialize();
    // Request notification permissions
    final permissionGranted = await NotificationManager.requestPermissions();
    print(
      'NotificationManager initialized successfully. Permissions granted: $permissionGranted',
    );
  } catch (e) {
    print('Error initializing NotificationManager: $e');
  }

  // Initialize ConnectivityService
  try {
    ConnectivityService().initialize();
    print('ConnectivityService initialized successfully');
  } catch (e) {
    print('Error initializing ConnectivityService: $e');
  }

  // Setup platform channel for widget communication
  const platform = MethodChannel('currensee_widget_channel');
  platform.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'openConverterSettings':
        // This will be handled by the widget click
        return 'success';
      default:
        return 'unknown_method';
    }
  });

  // Initialize AppVersionService
  try {
    await AppVersionService.initialize();
    print('AppVersionService initialized successfully');
  } catch (e) {
    print('Error initializing AppVersionService: $e');
  }

  runApp(
    FeatureDiscovery(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<VoiceService>(create: (_) => VoiceService()),
          Provider<ChatService>(create: (_) => ChatService()),
          ChangeNotifierProvider(create: (_) => AppSettings()),
          ChangeNotifierProvider<TaskService>(create: (_) => TaskService()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class AppSettings extends ChangeNotifier {
  bool _darkMode = false;
  int _decimalPlaces = 2;
  String _baseCurrency = 'USD';
  bool _autoUpdateRates = true;
  bool _biometricAuth = false;
  bool _hapticFeedback = true;
  bool _showCalculator = true;
  bool _historicalData = false;
  bool _offlineMode = false;
  String _selectedLanguage = 'English';
  String _selectedAppearance = 'System';
  List<String> _favoriteCurrencies = [];

  // Getters
  bool get darkMode => _darkMode;
  int get decimalPlaces => _decimalPlaces;
  String get baseCurrency => _baseCurrency;
  bool get autoUpdateRates => _autoUpdateRates;
  bool get biometricAuth => _biometricAuth;
  bool get hapticFeedback => _hapticFeedback;
  bool get showCalculator => _showCalculator;
  bool get historicalData => _historicalData;
  bool get offlineMode => _offlineMode;
  String get selectedLanguage => _selectedLanguage;
  String get selectedAppearance => _selectedAppearance;
  List<String> get favoriteCurrencies => _favoriteCurrencies;

  // Get effective dark mode based on appearance setting
  bool get effectiveDarkMode {
    if (_selectedAppearance == 'System') {
      // Use system theme
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    } else if (_selectedAppearance == 'Dark') {
      return true;
    } else {
      return false;
    }
  }

  // Load settings from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('darkMode') ?? false;
    _decimalPlaces = prefs.getInt('decimalPlaces') ?? 2;
    _baseCurrency = prefs.getString('baseCurrency') ?? 'USD';
    _autoUpdateRates = prefs.getBool('autoUpdateRates') ?? true;
    _biometricAuth = prefs.getBool('biometricAuth') ?? false;
    _hapticFeedback = prefs.getBool('hapticFeedback') ?? true;
    _showCalculator = prefs.getBool('showCalculator') ?? true;
    _historicalData = prefs.getBool('historicalData') ?? false;
    _offlineMode = prefs.getBool('offlineMode') ?? false;
    _selectedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    _selectedAppearance = prefs.getString('selectedAppearance') ?? 'System';
    _favoriteCurrencies = prefs.getStringList('favoriteCurrencies') ?? [];

    // Update dark mode based on appearance setting
    _updateDarkModeFromAppearance();
    notifyListeners();
  }

  // Update dark mode based on appearance setting
  void _updateDarkModeFromAppearance() {
    if (_selectedAppearance == 'System') {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _darkMode = brightness == Brightness.dark;
    } else if (_selectedAppearance == 'Dark') {
      _darkMode = true;
    } else {
      _darkMode = false;
    }
  }

  // Save settings to SharedPreferences
  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    }
    notifyListeners();
  }

  // Setters with save functionality
  void setDarkMode(bool value) {
    _darkMode = value;
    // Update appearance setting based on dark mode
    if (value) {
      _selectedAppearance = 'Dark';
    } else {
      _selectedAppearance = 'Light';
    }
    _saveSetting('darkMode', value);
    _saveSetting('selectedAppearance', _selectedAppearance);
  }

  void setDecimalPlaces(int value) {
    _decimalPlaces = value;
    _saveSetting('decimalPlaces', value);
  }

  void setBaseCurrency(String value) {
    _baseCurrency = value;
    _saveSetting('baseCurrency', value);
  }

  void setAutoUpdateRates(bool value) {
    _autoUpdateRates = value;
    _saveSetting('autoUpdateRates', value);
  }

  void setBiometricAuth(bool value) {
    _biometricAuth = value;
    _saveSetting('biometricAuth', value);
  }

  void setHapticFeedback(bool value) {
    _hapticFeedback = value;
    _saveSetting('hapticFeedback', value);
  }

  void setShowCalculator(bool value) {
    _showCalculator = value;
    _saveSetting('showCalculator', value);
  }

  void setHistoricalData(bool value) {
    _historicalData = value;
    _saveSetting('historicalData', value);
  }

  void setOfflineMode(bool value) {
    _offlineMode = value;
    _saveSetting('offlineMode', value);
  }

  void setSelectedLanguage(String value) {
    _selectedLanguage = value;
    _saveSetting('selectedLanguage', value);
  }

  void setSelectedAppearance(String value) {
    _selectedAppearance = value;
    _updateDarkModeFromAppearance();
    _saveSetting('selectedAppearance', value);
    _saveSetting('darkMode', _darkMode);
  }

  // Favorite currencies methods
  void setFavoriteCurrencies(List<String> currencies) {
    _favoriteCurrencies = currencies;
    _saveSetting('favoriteCurrencies', currencies);
  }

  void addFavoriteCurrency(String currencyCode) {
    if (!_favoriteCurrencies.contains(currencyCode) &&
        _favoriteCurrencies.length < 3) {
      _favoriteCurrencies.add(currencyCode);
      _saveSetting('favoriteCurrencies', _favoriteCurrencies);
    }
  }

  void removeFavoriteCurrency(String currencyCode) {
    _favoriteCurrencies.remove(currencyCode);
    _saveSetting('favoriteCurrencies', _favoriteCurrencies);
  }

  bool isFavoriteCurrency(String currencyCode) {
    return _favoriteCurrencies.contains(currencyCode);
  }
}

// AuthGate widget for auth-based routing
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showSplash = true;
  User? _user;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  void _checkAuthState() {
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _user = user;
        _showSplash = false;
      });
    });

    // Show splash for at least 2 seconds for smoothness
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

    if (_user != null) {
      return const MainScreen();
    }

    return const SignInScreen();
  }
} // CHANGES START HERE: Convert MyApp to StatefulWidget

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Key to restart the entire app
  Key _appKey = UniqueKey();

  // Function to restart the app (needed for ConnectivityWrapper)
  void _restartApp() {
    setState(() {
      _appKey = UniqueKey();
    });
  }

  // Biometric lock state
  bool _showLockScreen = false;
  bool _biometricAvailable = false;
  String _lockError = '';
  bool _isAuthenticating = false; // Track if authentication is in progress
  bool _hasAuthenticatedInSession =
      false; // Track if user has authenticated in current session
  bool _appInitialized = false; // Track if app has been properly initialized

  // Network connectivity state
  bool _isConnected = true;
  bool _isCheckingConnection = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Load settings when app starts
    Provider.of<AppSettings>(context, listen: false).loadSettings();

    // Reset authentication flag when app starts fresh
    _hasAuthenticatedInSession = false;
    _appInitialized = false;

    // Initialize network connectivity monitoring
    _initializeNetworkMonitoring();

    // Initialize widgets with default values
    Future.delayed(const Duration(milliseconds: 1000), () async {
      // Clear any old default pairs that might be cached
      await _clearOldDefaultPairs();

      initializeWidget();
      initializeWatchlistWidget();
      initializeConverterWidget();
    });

    // Initialize app and check biometric authentication after a delay
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _appInitialized = true;
        });
        // Check maintenance mode first, then biometric authentication
        _checkMaintenanceMode();

        // Start periodic maintenance check
        _startPeriodicMaintenanceCheck();
      }
    });
  }

  // Initialize network connectivity monitoring
  void _initializeNetworkMonitoring() {
    // Check initial connectivity immediately
    _checkConnectivity();

    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.isNotEmpty) {
        _handleConnectivityChange(results.first);
      }
    });
  }

  // Check current connectivity status
  Future<void> _checkConnectivity() async {
    setState(() {
      _isCheckingConnection = true;
    });

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.isNotEmpty) {
        _handleConnectivityChange(connectivityResult.first);
      } else {
        setState(() {
          _isConnected = false;
          _isCheckingConnection = false;
        });
      }
    } catch (e) {
      print('Error checking connectivity: $e');
      setState(() {
        _isConnected = false;
        _isCheckingConnection = false;
      });
    }
  }

  // Handle connectivity changes
  void _handleConnectivityChange(ConnectivityResult result) {
    setState(() {
      _isConnected = result != ConnectivityResult.none;
      _isCheckingConnection = false;
    });
    print('Connectivity changed: $result, isConnected: $_isConnected');
  }

  // Retry connection
  Future<void> _retryConnection() async {
    setState(() {
      _isCheckingConnection = true;
    });

    try {
      await _checkConnectivity();
      // If connection is restored, restart the app to show normal flow
      if (_isConnected) {
        _restartApp();
      }
    } finally {
      setState(() {
        _isCheckingConnection = false;
      });
    }
  }

  // Continue in offline mode
  void _continueOffline() {
    final appSettings = Provider.of<AppSettings>(context, listen: false);
    appSettings.setOfflineMode(true);

    // Force immediate state change to bypass all internet checks
    setState(() {
      // This will trigger a rebuild and show the normal app flow
      // since settings.offlineMode will now be true
    });

    // Also restart the app to ensure all components are updated
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _restartApp();
      }
    });
  }

  // Clear any old default pairs that might be cached
  Future<void> _clearOldDefaultPairs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check for old default pairs in both preference keys
      List<String> pairs = prefs.getStringList('watchlist_pairs') ?? [];
      String? flutterPairsString = prefs.getString('flutter.watchlist_pairs');

      final oldDefaults = ['USD/PKR', 'USD/INR', 'USD/AED'];
      final hasOldDefaults = pairs.any((pair) => oldDefaults.contains(pair));

      if (hasOldDefaults ||
          (flutterPairsString != null &&
              flutterPairsString.contains('USD/PKR'))) {
        print('Found old default pairs during app startup, clearing them');

        // Clear all pairs
        await prefs.remove('watchlist_pairs');
        await prefs.remove('flutter.watchlist_pairs');

        // Clear any cached rates for these pairs
        for (String defaultPair in oldDefaults) {
          await prefs.remove('${defaultPair}_previous');
          await prefs.remove('${defaultPair}_current');
          await prefs.remove('${defaultPair}_base');
          await prefs.remove('${defaultPair}_change');
        }

        print('Cleared old default pairs during app startup');
      }
    } catch (e) {
      print('Error clearing old default pairs: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check for missed alerts when app is resumed
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('App resumed, checking for missed alerts...');
        Future.delayed(const Duration(milliseconds: 1000), () {
          AlertService().checkForMissedAlerts();
        });
      }

      // Check maintenance mode first, then biometric lock if needed
      if (_appInitialized) {
        print('App resumed, checking maintenance mode...');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _checkMaintenanceMode();
          }
        });
      }
    } else if (state == AppLifecycleState.paused) {
      // When app goes to background, reset the lock screen state but keep authentication flag
      print('App paused, resetting lock screen state');
      setState(() {
        _showLockScreen = false;
        _isAuthenticating = false;
        _lockError = '';
        // Don't reset _hasAuthenticatedInSession here - keep it for the session
      });
    } else if (state == AppLifecycleState.detached) {
      // When app is completely closed, reset all authentication state
      print('App detached, resetting all authentication state');
      setState(() {
        _showLockScreen = false;
        _isAuthenticating = false;
        _lockError = '';
        _hasAuthenticatedInSession = false;
        _appInitialized = false; // Reset app initialization flag
      });
    }
    // Removed the inactive state handler to prevent unnecessary resets
  }

  // Check maintenance mode and show modal if needed
  Future<void> _checkMaintenanceMode() async {
    // Skip maintenance check if offline mode is enabled
    final settings = Provider.of<AppSettings>(context, listen: false);
    if (settings.offlineMode) {
      print('Offline mode enabled, skipping maintenance check');
      _checkBiometricLock();
      return;
    }

    // Skip maintenance check if not connected
    if (!_isConnected) {
      print('No internet connection, skipping maintenance check');
      _checkBiometricLock();
      return;
    }

    try {
      print('Checking maintenance mode...');
      final isMaintenanceActive =
          await MaintenanceService.checkAndShowMaintenanceModal(context);

      if (isMaintenanceActive) {
        print('Maintenance mode is active - app access blocked');
        // Don't proceed with biometric check if maintenance is active
        return;
      } else {
        print('No maintenance mode - proceeding with normal app flow');
        // Continue with biometric authentication
        _checkBiometricLock();
      }
    } catch (e) {
      print('Error checking maintenance mode: $e');
      // If maintenance check fails, continue with normal flow
      _checkBiometricLock();
    }
  }

  // Periodic maintenance check
  void _startPeriodicMaintenanceCheck() {
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Skip periodic check if offline mode is enabled
      final settings = Provider.of<AppSettings>(context, listen: false);
      if (settings.offlineMode) {
        print('Offline mode enabled, skipping periodic maintenance check');
        return;
      }

      // Skip periodic check if not connected
      if (!_isConnected) {
        print('No internet connection, skipping periodic maintenance check');
        return;
      }

      try {
        final maintenanceData =
            await MaintenanceService.checkMaintenanceStatus();
        if (maintenanceData != null && maintenanceData['isEnabled'] == true) {
          print('Maintenance mode detected during periodic check');
          // Force show maintenance modal and block app
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(); // Close any open dialogs
          }
          MaintenanceService.showMaintenanceModal(context, maintenanceData);
        }
      } catch (e) {
        print('Error in periodic maintenance check: $e');
      }
    });
  }

  Future<void> _checkBiometricLock() async {
    // Prevent multiple simultaneous checks
    if (_isAuthenticating) {
      print('Biometric check already in progress, skipping...');
      return;
    }

    // Check if user has already authenticated in this session
    if (_hasAuthenticatedInSession) {
      print(
        'User already authenticated in this session, skipping biometric check',
      );
      return;
    }

    print('Starting biometric lock check...');

    try {
      // Only check biometric lock if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in, skipping biometric check');
        setState(() {
          _showLockScreen = false;
          _isAuthenticating = false;
        });
        return;
      }

      print('User logged in: ${user.email}');

      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('biometricAuth') ?? false;
      print('Biometric auth enabled: $isEnabled');

      if (!isEnabled) {
        print('Biometric authentication is disabled in settings');
        setState(() {
          _showLockScreen = false;
          _isAuthenticating = false;
        });
        return;
      }

      final localAuth = LocalAuthentication();
      final canCheck = await localAuth.canCheckBiometrics;
      final isDeviceSupported = await localAuth.isDeviceSupported();

      print(
        'Can check biometrics: $canCheck, Device supported: $isDeviceSupported',
      );

      if (canCheck && isDeviceSupported) {
        print('Showing biometric lock screen');
        setState(() {
          _biometricAvailable = true;
          _showLockScreen = true;
          _lockError = '';
          _isAuthenticating =
              false; // Reset here to allow immediate authentication
        });

        // Auto-trigger authentication after a short delay
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          _authenticate();
        }
      } else {
        print('Biometric authentication not available on this device');
        setState(() {
          _biometricAvailable = false;
          _showLockScreen = false;
          _lockError =
              'Biometric authentication not available on this device. Please enable it in settings.';
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      print('Biometric check error: $e');
      setState(() {
        _showLockScreen = false;
        _lockError = 'Error checking biometric availability. Please try again.';
        _isAuthenticating = false;
      });
    }
  }

  Future<void> _authenticate() async {
    // Prevent multiple authentication attempts
    if (_isAuthenticating) {
      print('Authentication already in progress, skipping...');
      return;
    }

    print('Starting biometric authentication process...');

    setState(() {
      _isAuthenticating = true;
      _lockError = ''; // Clear any previous errors
    });

    final localAuth = LocalAuthentication();
    try {
      print('Requesting biometric authentication...');

      // Get available biometrics for better user experience
      final availableBiometrics = await localAuth.getAvailableBiometrics();
      print('Available biometrics: $availableBiometrics');

      final didAuthenticate = await localAuth.authenticate(
        localizedReason:
            'Unlock CurrenSee Pro - Use your fingerprint or face to access the app',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false, // Allow retries
        ),
      );

      print('Authentication result: $didAuthenticate');

      if (didAuthenticate) {
        print('Biometric authentication successful');
        setState(() {
          _showLockScreen = false;
          _lockError = '';
          _isAuthenticating = false;
          _hasAuthenticatedInSession =
              true; // Mark as authenticated for this session
        });

        // Add a small delay to ensure state is properly updated before navigation
        await Future.delayed(const Duration(milliseconds: 100));
      } else {
        print('Biometric authentication failed or cancelled');
        // If authentication failed or cancelled, show error and let user try again
        setState(() {
          _lockError =
              'Authentication failed. Please try again or tap the fingerprint icon below.';
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      print('Authentication error: $e');
      setState(() {
        _lockError =
            'Authentication error. Please try again or check your device settings.';
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettings>(
      builder: (context, settings, child) {
        return MaterialApp(
          key: _appKey, // Use the restart key here
          // In main.dart, modify the MaterialApp routes:
          home:
              _isConnected && !settings.offlineMode
                  ? FutureBuilder<Map<String, dynamic>?>(
                    future: MaintenanceService.checkMaintenanceStatus(),
                    builder: (context, snapshot) {
                      // Show loading while checking maintenance
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }

                      // Check if maintenance mode is active
                      if (snapshot.hasData &&
                          snapshot.data != null &&
                          snapshot.data!['isEnabled'] == true) {
                        // Show maintenance screen
                        return Scaffold(
                          body: Builder(
                            builder: (context) {
                              // Show maintenance modal
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                MaintenanceService.showMaintenanceModal(
                                  context,
                                  snapshot.data!,
                                );
                              });
                              return const Center(
                                child: Text('App is under maintenance'),
                              );
                            },
                          ),
                        );
                      }

                      // Normal app flow
                      return _showLockScreen
                          ? BiometricLockScreen(
                            onUnlock: _authenticate,
                            error: _lockError,
                            biometricAvailable: _biometricAvailable,
                            isAuthenticating: _isAuthenticating,
                          )
                          : const AuthGate();
                    },
                  )
                  : !_isConnected && !settings.offlineMode
                  ? NetworkErrorScreen(
                    onRetry: _retryConnection,
                    isChecking: _isCheckingConnection,
                  )
                  : _showLockScreen
                  ? BiometricLockScreen(
                    onUnlock: _authenticate,
                    error: _lockError,
                    biometricAvailable: _biometricAvailable,
                    isAuthenticating: _isAuthenticating,
                  )
                  : const AuthGate(),

          builder: (context, child) {
            return ConnectivityWrapper(
              onRestart: _restartApp,
              child: child ?? const SizedBox(), // ADDED THIS LINE
            );
          },
          routes: {
            '/auth': (context) => const AuthGate(),
            '/splash': (context) => const SplashScreen(),
            '/signin': (context) => const SignInScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/forgot': (context) => const ForgotPasswordScreen(),
            '/home': (context) => const MainScreen(),

            '/rate-list': (context) => const RateListPage(),
          },

          title: 'CurrenSee Pro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode:
              settings.effectiveDarkMode ? ThemeMode.dark : ThemeMode.light,
        );
      },
    );
  }
}

// Add ShineText widget for animated gradient text
class ShineText extends StatefulWidget {
  final String text;
  final TextStyle textStyle;
  const ShineText({super.key, required this.text, required this.textStyle});

  @override
  State<ShineText> createState() => _ShineTextState();
}

class _ShineTextState extends State<ShineText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _alignAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _alignAnimation = Tween<Alignment>(
      begin: const Alignment(-1.5, 0),
      end: const Alignment(1.5, 0),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.white,
                const Color(0xFFD4AF37),
                Colors.white,
                const Color(0xFFD4AF37),
                Colors.white,
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
              begin: _alignAnimation.value,
              end: _alignAnimation.value + const Alignment(0.3, 0),
            ).createShader(bounds);
          },
          child: Text(widget.text, style: widget.textStyle),
        );
      },
    );
  }
}

// Convert CustomAppBar to StatefulWidget
class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onMenuTap;
  const CustomAppBar({super.key, required this.title, this.onMenuTap});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      leadingWidth: 60,
      leading: Center(
        child: DescribedFeatureOverlay(
          featureId: 'hamburger_feature',
          tapTarget: Icon(Icons.menu),
          title: const Text('Navigation Menu'),
          description: const Text(
            'Tap here to access all app features, settings, and navigation options.',
          ),
          backgroundColor: Colors.teal,
          contentLocation: ContentLocation.below,
          child: GestureDetector(
            onTap: widget.onMenuTap,
            child: Container(
              width: 180,
              height: 180,
              padding: const EdgeInsets.all(10),
              child: Lottie.asset(
                'assets/Menu.json', // Your menu animation
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
      title: ShineText(
        text: widget.title,
        textStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
      centerTitle: true,
      actions: [const UserProfileMenu()],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }
}

// MainScreen: Remove animation controller, use CustomAppBar
class MainScreen extends StatefulWidget {
  final bool showSuccess;
  const MainScreen({super.key, this.showSuccess = false});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    // Navigate to auth gate which will handle routing
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _showSuccess = widget.showSuccess;
    print(
      'MainScreen initState: showSuccess = $_showSuccess, widget.showSuccess = ${widget.showSuccess}',
    );
    if (_showSuccess) {
      print('Showing success animation for 2 seconds');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _showSuccess = false);
          print('Success animation hidden');
        }
      });
    }

    // Initialize user status monitoring
    UserStatusService.initializeStatusMonitoring(context);
  }

  @override
  void dispose() {
    UserStatusService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CurrencyConverterScreen(showSuccess: _showSuccess),
          const BotFAB(),
        ],
      ),
    );
  }
}

// MODIFIED: Added onRestart parameter
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRestart; // ADDED THIS PARAMETER

  const ConnectivityWrapper({
    super.key,
    required this.child,
    this.onRestart,
  }); // UPDATED

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  bool _isOnline = true;
  bool _showOfflineMode = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.isNotEmpty) {
        _updateConnectionStatus(results.first);
      }
    });
  }

  Future<void> _initConnectivity() async {
    setState(() => _isChecking = true);
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = connectivityResult != ConnectivityResult.none;
      _isChecking = false;
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      _isOnline = result != ConnectivityResult.none;
      if (_isOnline) {
        _showOfflineMode = false; // Reset offline mode when back online
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to AppSettings changes to get the current offline mode setting
    return Consumer<AppSettings>(
      builder: (context, appSettings, child) {
        final isOfflineModeEnabled = appSettings.offlineMode;

        // Show network error screen if:
        // 1. We're offline AND
        // 2. User hasn't chosen offline mode (either through settings or continue offline button) AND
        // 3. Not currently checking connection AND
        // 4. Offline mode is not enabled in settings
        if (!_isOnline &&
            !_showOfflineMode &&
            !_isChecking &&
            !isOfflineModeEnabled) {
          return NetworkErrorScreen(
            onRetry: () {
              _initConnectivity();
            },
          );
        }

        return widget.child;
      },
    );
  }
}

// --- BotFAB Widget ---
class BotFAB extends StatelessWidget {
  const BotFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 12,
      right: 12,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CurrencyChatScreen(),
              fullscreenDialog: true,
            ),
          );
        },
        child: SizedBox(
          width: 150,
          height: 150,
          child: Lottie.asset(
            'assets/Chat Bot.json',
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error, color: Colors.red);
            },
            frameRate: FrameRate.max,
          ),
        ),
      ),
    );
  }
}

// Updated UserProfileMenu widget
class UserProfileMenu extends StatefulWidget {
  const UserProfileMenu({super.key});

  @override
  State<UserProfileMenu> createState() => _UserProfileMenuState();
}

class _UserProfileMenuState extends State<UserProfileMenu> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      onPressed: () {
        // Navigate directly to settings page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => SettingsPage(
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
        );
      },
      icon: CircleAvatar(
        radius: 18,
        backgroundImage:
            user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
        backgroundColor: theme.colorScheme.secondary,
        child:
            user?.photoURL == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
      ),
    );
  }
}

// Professional biometric lock screen widget
class BiometricLockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  final String error;
  final bool biometricAvailable;
  final bool isAuthenticating;

  const BiometricLockScreen({
    super.key,
    required this.onUnlock,
    required this.error,
    required this.biometricAvailable,
    required this.isAuthenticating,
  });

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    // Start animations
    _fadeController.forward();
    _pulseController.repeat(reverse: true);

    // Auto-trigger biometric authentication after a short delay
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && widget.biometricAvailable && !widget.isAuthenticating) {
        print('Auto-triggering biometric authentication');
        _triggerAuthentication();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _triggerAuthentication() {
    if (widget.isAuthenticating) {
      print('Authentication already in progress, cannot trigger again');
      return;
    }

    // Add haptic feedback
    HapticFeedback.lightImpact();

    print('Manual authentication triggered by user');
    widget.onUnlock();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF3B82F6),
              Color(0xFF60A5FA),
              Color(0xFFD4AF37),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Top section with app branding
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App logo with pulse animation
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: isSmallScreen ? 80 : 100,
                              height: isSmallScreen ? 80 : 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.2),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Lottie.asset(
                                  'assets/user-profile.json',
                                  width: isSmallScreen ? 60 : 80,
                                  height: isSmallScreen ? 60 : 80,
                                  repeat: true,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // App title
                      Text(
                        'CurrenSee Pro',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 28 : 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'Secure Currency Converter',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Middle section with biometric interface
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Lock icon
                        Container(
                          width: isSmallScreen ? 60 : 80,
                          height: isSmallScreen ? 60 : 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Unlock text
                        Text(
                          'Unlock App',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Biometric icon with pulse animation
                        if (widget.biometricAvailable)
                          GestureDetector(
                            onTap: _triggerAuthentication,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  isSmallScreen ? 40 : 50,
                                ),
                                onTap: _triggerAuthentication,
                                child: AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _pulseAnimation.value,
                                      child: Container(
                                        width: isSmallScreen ? 80 : 100,
                                        height: isSmallScreen ? 80 : 100,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withOpacity(0.2),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.4,
                                            ),
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.white.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 15,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.fingerprint,
                                          size: 48,
                                          color:
                                              widget.isAuthenticating
                                                  ? Colors.white.withOpacity(
                                                    0.6,
                                                  )
                                                  : Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Authentication status
                        if (widget.isAuthenticating)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Scanning...',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                        // Error message
                        if (widget.error.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.error,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Bottom section with action buttons
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Manual unlock button
                      if (widget.biometricAvailable)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          child: ElevatedButton.icon(
                            onPressed:
                                widget.isAuthenticating
                                    ? null
                                    : _triggerAuthentication,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1E3A8A),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 4,
                              shadowColor: Colors.black.withOpacity(0.2),
                            ),
                            icon: const Icon(Icons.fingerprint, size: 24),
                            label: Text(
                              widget.isAuthenticating
                                  ? 'Scanning...'
                                  : 'Unlock with Biometrics',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Help text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          widget.biometricAvailable
                              ? widget.isAuthenticating
                                  ? 'Scanning... Please wait'
                                  : 'Tap the fingerprint icon above to unlock'
                              : 'Biometric authentication is not available on this device',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // App version
                      Text(
                        'Version 2.0.0',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
