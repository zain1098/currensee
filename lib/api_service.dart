import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'services/google_search_currency_service.dart';

class ApiService {
  // Real-time currency APIs
  static const String _primaryApi = 'https://api.exchangerate-api.com/v4/latest';
  static const String _fallbackApi = 'https://open.er-api.com/v6/latest';

  // Simple caching (5 minutes)
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Check internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Get real-time exchange rates
  static Future<Map<String, dynamic>> getExchangeRates(String baseCurrency) async {
    // Check cache first
    final cacheKey = 'rates_$baseCurrency';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey]!;
    }

    if (!await hasInternetConnection()) {
      throw Exception('No Internet Connection');
    }

    try {
      // Try Google Search first (most accurate)
      final googleRates = await _getGoogleRates(baseCurrency);
      if (googleRates['success']) {
        _cache[cacheKey] = googleRates;
        _cacheTime[cacheKey] = DateTime.now();
        return googleRates;
      }
    } catch (e) {
      print('Google rates failed: $e');
    }

    // Fallback to APIs
    return await _getApiRates(baseCurrency);
  }

  /// Get Google rates (primary source)
  static Future<Map<String, dynamic>> _getGoogleRates(String baseCurrency) async {
    final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'PKR', 'INR', 'CAD', 'AUD'];
    final rates = <String, double>{};
    
    for (final currency in currencies) {
      if (currency != baseCurrency) {
        try {
          final result = await GoogleSearchCurrencyService.getGoogleSearchRate(baseCurrency, currency);
          if (result['success']) {
            rates[currency] = result['rate'];
          }
          await Future.delayed(const Duration(milliseconds: 100)); // Rate limit
        } catch (e) {
          continue; // Skip failed currencies
        }
      }
    }
    
    if (rates.isNotEmpty) {
      return {
        'success': true,
        'rates': rates,
        'baseCurrency': baseCurrency,
        'source': 'Google Search',
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
    
    throw Exception('No Google rates available');
  }

  /// Get API rates (fallback)
  static Future<Map<String, dynamic>> _getApiRates(String baseCurrency) async {
    final apis = [_primaryApi, _fallbackApi];
    
    for (final apiUrl in apis) {
      try {
        final response = await http.get(
          Uri.parse('$apiUrl/$baseCurrency'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          Map<String, dynamic> result;
          if (apiUrl == _primaryApi) {
            // ExchangeRate-API format
            result = {
              'success': true,
              'rates': data['rates'],
              'baseCurrency': data['base'],
              'source': 'ExchangeRate-API',
              'lastUpdated': data['date'],
            };
          } else {
            // Open.er-api format
            if (data['result'] == 'success') {
              result = {
                'success': true,
                'rates': data['rates'],
                'baseCurrency': data['base_code'],
                'source': 'Open.er-api',
                'lastUpdated': data['time_last_update_utc'],
              };
            } else {
              continue;
            }
          }
          
          // Cache and return
          final cacheKey = 'rates_$baseCurrency';
          _cache[cacheKey] = result;
          _cacheTime[cacheKey] = DateTime.now();
          return result;
        }
      } catch (e) {
        continue; // Try next API
      }
    }
    
    throw Exception('All currency APIs failed');
  }

  /// Convert currency with real-time rates
  static Future<Map<String, dynamic>> convertCurrency({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
  }) async {
    try {
      // Try Google direct conversion first
      final googleResult = await GoogleSearchCurrencyService.convertWithGoogle(
        from: fromCurrency,
        to: toCurrency,
        amount: amount,
      );
      
      if (googleResult['success']) {
        return googleResult;
      }
    } catch (e) {
      print('Google conversion failed: $e');
    }

    // Fallback to API rates
    final ratesData = await getExchangeRates(fromCurrency);
    if (ratesData['success']) {
      final rates = ratesData['rates'] as Map<String, dynamic>;
      final rate = rates[toCurrency];

      if (rate != null) {
        return {
          'success': true,
          'fromCurrency': fromCurrency,
          'toCurrency': toCurrency,
          'amount': amount,
          'convertedAmount': amount * rate,
          'rate': rate,
          'source': ratesData['source'],
          'lastUpdated': ratesData['lastUpdated'],
        };
      }
    }
    
    return {'success': false, 'error': 'Conversion failed'};
  }

  /// Get available currencies
  static Future<List<String>> getAvailableCurrencies() async {
    try {
      final ratesData = await getExchangeRates('USD');
      if (ratesData['success']) {
        final currencies = (ratesData['rates'] as Map<String, dynamic>).keys.toList();
        currencies.add('USD');
        currencies.sort();
        return currencies;
      }
    } catch (e) {
      // Return common currencies if API fails
      return ['USD', 'EUR', 'GBP', 'JPY', 'PKR', 'INR', 'CAD', 'AUD', 'CNY', 'CHF'];
    }
    return [];
  }

  /// Check if cache is valid
  static bool _isCacheValid(String key) {
    if (!_cache.containsKey(key) || !_cacheTime.containsKey(key)) {
      return false;
    }
    return DateTime.now().difference(_cacheTime[key]!) < _cacheExpiry;
  }

  /// Clear cache
  static void clearCache() {
    _cache.clear();
    _cacheTime.clear();
  }
}