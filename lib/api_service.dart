import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ApiService {
  static const String _baseUrl = 'https://open.er-api.com/v6/latest';

  // Enhanced caching system
  static final Map<String, dynamic> _rateCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(
    minutes: 15,
  ); // 15 minutes cache
  static const int _maxCacheSize = 50;

  // Request batching and debouncing
  static Timer? _batchTimer;
  static final Map<String, Completer<Map<String, dynamic>>> _pendingRequests =
      {};
  static final List<String> _batchQueue = [];
  static bool _isProcessingBatch = false;

  // Performance monitoring
  static final List<Map<String, dynamic>> _performanceLog = [];
  static const int _maxLogEntries = 100;

  /// Check if device has internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Enhanced fetch exchange rates with caching and batching
  static Future<Map<String, dynamic>> getExchangeRates(
    String baseCurrency,
  ) async {
    final startTime = DateTime.now();

    // Check cache first
    final cacheKey = 'rates_$baseCurrency';
    if (_isCacheValid(cacheKey)) {
      print('✅ Cache hit for: $baseCurrency');
      _logPerformance('cache_hit', startTime, baseCurrency);
      return _rateCache[cacheKey]!;
    }

    // Check if there's already a pending request for this currency
    if (_pendingRequests.containsKey(baseCurrency)) {
      _logPerformance('pending_request', startTime, baseCurrency);
      return await _pendingRequests[baseCurrency]!.future;
    }

    // Check internet connectivity first
    if (!await hasInternetConnection()) {
      throw Exception('No Internet');
    }

    // Create completer for this request
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[baseCurrency] = completer;

    try {
      // Add to batch queue
      if (!_batchQueue.contains(baseCurrency)) {
        _batchQueue.add(baseCurrency);
      }

      // Start batch processing if not already running
      if (!_isProcessingBatch) {
        _processBatchRequests();
      }

      final result = await completer.future;
      _logPerformance('api_success', startTime, baseCurrency);
      return result;
    } catch (e) {
      _logPerformance(
        'api_error',
        startTime,
        baseCurrency,
        error: e.toString(),
      );
      _pendingRequests.remove(baseCurrency);
      if (e.toString().contains('No Internet')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Process batch requests efficiently
  static Future<void> _processBatchRequests() async {
    if (_isProcessingBatch || _batchQueue.isEmpty) return;

    _isProcessingBatch = true;

    try {
      // Process requests in batches of 3 to avoid overwhelming the API
      const batchSize = 3;
      final currentBatch = _batchQueue.take(batchSize).toList();

      // Remove processed currencies from queue
      for (final currency in currentBatch) {
        _batchQueue.remove(currency);
      }

      // Process batch requests with better error handling and rate limiting
      for (final currency in currentBatch) {
        try {
          await _fetchSingleRate(currency);
          // Add delay between requests to prevent overwhelming
          await Future.delayed(const Duration(milliseconds: 150));
        } catch (e) {
          print('Error fetching rate for $currency: $e');
          // Continue with other requests even if one fails
        }
      }

      // Process remaining requests if any with longer delay
      if (_batchQueue.isNotEmpty) {
        await Future.delayed(
          const Duration(milliseconds: 500),
        ); // Increased rate limiting
        _processBatchRequests();
      }
    } finally {
      _isProcessingBatch = false;
    }
  }

  /// Fetch single exchange rate
  static Future<void> _fetchSingleRate(String baseCurrency) async {
    try {
      print('🌐 Making API request for: $baseCurrency');
      final response = await http
          .get(
            Uri.parse('$_baseUrl/$baseCurrency'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == 'success') {
          final result = {
            'success': true,
            'rates': data['rates'],
            'lastUpdated': data['time_last_update_utc'],
            'baseCurrency': data['base_code'],
          };

          // Cache the result
          _cacheResult('rates_$baseCurrency', result);

          // Complete the pending request
          final completer = _pendingRequests[baseCurrency];
          if (completer != null && !completer.isCompleted) {
            completer.complete(result);
          }
        } else {
          _handleRequestError(
            baseCurrency,
            data['error'] ?? 'API returned error',
          );
        }
      } else {
        _handleRequestError(
          baseCurrency,
          'Failed to load: ${response.statusCode}',
        );
      }
    } catch (e) {
      _handleRequestError(baseCurrency, 'Network error: ${e.toString()}');
    }
  }

  /// Handle request errors
  static void _handleRequestError(String baseCurrency, String error) {
    final completer = _pendingRequests[baseCurrency];
    if (completer != null && !completer.isCompleted) {
      completer.completeError(Exception(error));
    }
    _pendingRequests.remove(baseCurrency);
  }

  /// Check if cache is valid
  static bool _isCacheValid(String key) {
    if (!_rateCache.containsKey(key)) return false;

    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;

    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  /// Cache result with memory management
  static void _cacheResult(String key, dynamic result) {
    // Evict old cache entries if cache is full
    if (_rateCache.length >= _maxCacheSize) {
      _evictOldCacheEntries();
    }

    _rateCache[key] = result;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Evict old cache entries
  static void _evictOldCacheEntries() {
    if (_cacheTimestamps.isEmpty) return;

    // Find oldest entries
    final sortedEntries =
        _cacheTimestamps.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));

    // Remove oldest 20% of entries
    final entriesToRemove = (sortedEntries.length * 0.2).ceil();
    for (int i = 0; i < entriesToRemove && i < sortedEntries.length; i++) {
      final key = sortedEntries[i].key;
      _rateCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Log performance metrics
  static void _logPerformance(
    String type,
    DateTime startTime,
    String currency, {
    String? error,
  }) {
    final duration = DateTime.now().difference(startTime).inMilliseconds;

    _performanceLog.add({
      'type': type,
      'currency': currency,
      'duration': duration,
      'timestamp': DateTime.now().toIso8601String(),
      if (error != null) 'error': error,
    });

    // Keep only recent log entries
    if (_performanceLog.length > _maxLogEntries) {
      _performanceLog.removeRange(0, _performanceLog.length - _maxLogEntries);
    }
  }

  /// Convert amount from one currency to another with enhanced caching
  static Future<Map<String, dynamic>> convertCurrency({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
  }) async {
    final startTime = DateTime.now();

    try {
      final ratesData = await getExchangeRates(fromCurrency);

      if (ratesData['success']) {
        final rates = ratesData['rates'] as Map<String, dynamic>;
        final rate = rates[toCurrency];

        if (rate != null) {
          final convertedAmount = amount * rate;
          final result = {
            'success': true,
            'fromCurrency': fromCurrency,
            'toCurrency': toCurrency,
            'amount': amount,
            'convertedAmount': convertedAmount,
            'rate': rate,
            'lastUpdated': ratesData['lastUpdated'],
          };

          _logPerformance(
            'conversion_success',
            startTime,
            '$fromCurrency->$toCurrency',
          );
          return result;
        } else {
          _logPerformance(
            'conversion_error',
            startTime,
            '$fromCurrency->$toCurrency',
            error: 'Currency not found: $toCurrency',
          );
          throw Exception('Currency not found: $toCurrency');
        }
      } else {
        _logPerformance(
          'conversion_error',
          startTime,
          '$fromCurrency->$toCurrency',
          error: 'Failed to fetch exchange rates',
        );
        throw Exception('Failed to fetch exchange rates');
      }
    } catch (e) {
      _logPerformance(
        'conversion_error',
        startTime,
        '$fromCurrency->$toCurrency',
        error: e.toString(),
      );
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get list of available currencies with caching
  static Future<List<String>> getAvailableCurrencies() async {
    const cacheKey = 'available_currencies';

    // Check cache first
    if (_isCacheValid(cacheKey)) {
      return _rateCache[cacheKey]!;
    }

    try {
      final ratesData = await getExchangeRates('USD');
      if (ratesData['success']) {
        final currencies =
            (ratesData['rates'] as Map<String, dynamic>).keys.toList();
        currencies.add('USD'); // Add USD since it's the base
        currencies.sort();

        // Cache the result
        _cacheResult(cacheKey, currencies);

        return currencies;
      } else {
        throw Exception('Failed to fetch currencies');
      }
    } catch (e) {
      throw Exception('Error fetching currencies: ${e.toString()}');
    }
  }

  /// Get cache statistics for monitoring
  static Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _rateCache.length,
      'maxCacheSize': _maxCacheSize,
      'pendingRequests': _pendingRequests.length,
      'batchQueueSize': _batchQueue.length,
      'isProcessingBatch': _isProcessingBatch,
      'performanceLogSize': _performanceLog.length,
    };
  }

  /// Get performance metrics
  static List<Map<String, dynamic>> getPerformanceMetrics() {
    return List.from(_performanceLog);
  }

  /// Clear cache and reset state
  static void clearCache() {
    _rateCache.clear();
    _cacheTimestamps.clear();
    _performanceLog.clear();

    // Cancel pending requests
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Cache cleared'));
      }
    }
    _pendingRequests.clear();
    _batchQueue.clear();
  }

  /// Preload common currencies for better performance
  static Future<void> preloadCommonCurrencies() async {
    const commonCurrencies = ['USD', 'EUR', 'GBP', 'JPY', 'PKR', 'INR'];

    try {
      await Future.wait(
        commonCurrencies.map((currency) => getExchangeRates(currency)),
      );
    } catch (e) {
      // Ignore preload errors
      print('Preload error: $e');
    }
  }
}
