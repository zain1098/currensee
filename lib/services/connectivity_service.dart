import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../network_error_screen.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  bool _isConnected = true;
  bool _isChecking = false;
  final Connectivity _connectivity = Connectivity();

  bool get isConnected => _isConnected;
  bool get isChecking => _isChecking;

  // Initialize connectivity monitoring
  void initialize() {
    _checkInitialConnectivity();
    _setupConnectivityListener();
  }

  // Check initial connectivity status
  Future<void> _checkInitialConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      _isConnected =
          connectivityResult.isNotEmpty &&
          connectivityResult.first != ConnectivityResult.none;
    } catch (e) {
      print('Error checking initial connectivity: $e');
      _isConnected = false;
    }
  }

  // Setup connectivity listener
  void _setupConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final wasConnected = _isConnected;
      _isConnected =
          results.isNotEmpty && results.first != ConnectivityResult.none;

      // If connection was lost, notify the app
      if (wasConnected && !_isConnected) {
        print('Internet connection lost');
        _notifyConnectionLost();
      } else if (!wasConnected && _isConnected) {
        print('Internet connection restored');
        _notifyConnectionRestored();
      }
    });
  }

  // Check connectivity manually
  Future<bool> checkConnectivity() async {
    _isChecking = true;
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      _isConnected =
          connectivityResult.isNotEmpty &&
          connectivityResult.first != ConnectivityResult.none;
      return _isConnected;
    } catch (e) {
      print('Error checking connectivity: $e');
      _isConnected = false;
      return false;
    } finally {
      _isChecking = false;
    }
  }

  // Show network error screen
  void showNetworkErrorScreen(
    BuildContext context, {
    VoidCallback? onRetry,
    VoidCallback? onContinueOffline,
    bool showOfflineOption = true,
  }) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (context) => NetworkErrorScreen(
              onRetry: onRetry,
              onContinueOffline: onContinueOffline,
              isChecking: _isChecking,
              showOfflineOption: showOfflineOption,
            ),
      ),
    );
  }

  // Notify when connection is lost
  void _notifyConnectionLost() {
    // This can be used to show notifications or update UI
    print('Connection lost - app should handle this');
  }

  // Notify when connection is restored
  void _notifyConnectionRestored() {
    // This can be used to automatically retry failed operations
    print('Connection restored - app can retry operations');
  }

  // Check if should show network error screen
  bool shouldShowNetworkError() {
    return !_isConnected && !_isChecking;
  }

  // Get connectivity status as string
  String getConnectivityStatus() {
    if (_isChecking) return 'Checking...';
    return _isConnected ? 'Connected' : 'Disconnected';
  }
}
