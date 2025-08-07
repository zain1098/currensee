import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class ApiService {
  static const String _baseUrl = 'https://open.er-api.com/v6/latest';

  /// Check if device has internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Fetch exchange rates for a given base currency
  static Future<Map<String, dynamic>> getExchangeRates(
    String baseCurrency,
  ) async {
    // Check internet connectivity first
    if (!await hasInternetConnection()) {
      throw Exception('No Internet');
    }

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/$baseCurrency'), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == 'success') {
          return {
            'success': true,
            'rates': data['rates'],
            'lastUpdated': data['time_last_update_utc'],
            'baseCurrency': data['base_code'],
          };
        } else {
          throw Exception(data['error'] ?? 'API returned error');
        }
      } else {
        throw Exception('Failed to load: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('No Internet')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Convert amount from one currency to another
  static Future<Map<String, dynamic>> convertCurrency({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
  }) async {
    try {
      final ratesData = await getExchangeRates(fromCurrency);

      if (ratesData['success']) {
        final rates = ratesData['rates'] as Map<String, dynamic>;
        final rate = rates[toCurrency];

        if (rate != null) {
          final convertedAmount = amount * rate;
          return {
            'success': true,
            'fromCurrency': fromCurrency,
            'toCurrency': toCurrency,
            'amount': amount,
            'convertedAmount': convertedAmount,
            'rate': rate,
            'lastUpdated': ratesData['lastUpdated'],
          };
        } else {
          throw Exception('Currency not found: $toCurrency');
        }
      } else {
        throw Exception('Failed to fetch exchange rates');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get list of available currencies
  static Future<List<String>> getAvailableCurrencies() async {
    try {
      final ratesData = await getExchangeRates('USD');
      if (ratesData['success']) {
        final currencies =
            (ratesData['rates'] as Map<String, dynamic>).keys.toList();
        currencies.add('USD'); // Add USD since it's the base
        currencies.sort();
        return currencies;
      } else {
        throw Exception('Failed to fetch currencies');
      }
    } catch (e) {
      throw Exception('Error fetching currencies: ${e.toString()}');
    }
  }
}
