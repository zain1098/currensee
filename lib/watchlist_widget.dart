import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Update watchlist widget with new currency pairs
Future<void> updateWatchlistWidget({
  required List<String> currencyPairs,
}) async {
  try {
    // Save currency pairs to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('watchlist_pairs', currencyPairs);
    
    // Trigger widget update via platform channel
    const platform = MethodChannel('currensee_widget_channel');
    await platform.invokeMethod('updateWatchlistWidget');
    
    print('Watchlist widget updated with pairs: $currencyPairs');
  } catch (e) {
    print('Error updating watchlist widget: $e');
  }
}

/// Fetch current rates for watchlist pairs
Future<Map<String, dynamic>> fetchWatchlistRates(List<String> pairs) async {
  try {
    Map<String, dynamic> results = {};
    
    for (String pair in pairs.take(3)) { // Limit to 3 pairs
      final parts = pair.split('/');
      if (parts.length != 2) continue;
      
      final fromCurrency = parts[0];
      final toCurrency = parts[1];
      
      // Use better API for PKR rates
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/$fromCurrency'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'CurrenSee-Widget/1.0',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        final currentRate = (rates[toCurrency] as num?)?.toDouble() ?? 0.0;
        
        // Get previous rate for comparison
        final prefs = await SharedPreferences.getInstance();
        final previousRate = prefs.getDouble('${pair}_previous') ?? currentRate;
        
        // Calculate percentage change
        final change = previousRate > 0 ? ((currentRate - previousRate) / previousRate) * 100 : 0.0;
        
        results[pair] = {
          'current': currentRate,
          'previous': previousRate,
          'change': change,
          'lastUpdated': data['date'],
        };
        
        // Save current rate as previous for next comparison
        await prefs.setDouble('${pair}_previous', currentRate);
        
        print('Fetched rate for $pair: $currentRate (change: ${change.toStringAsFixed(2)}%)');
      }
    }
    
    return results;
  } catch (e) {
    print('Error fetching watchlist rates: $e');
    return {};
  }
}

/// Get stored watchlist pairs
Future<List<String>> getWatchlistPairs() async {
  try {
    // Return fixed pairs - no database complexity
    return ['USD/PKR', 'GBP/PKR', 'EUR/PKR'];
  } catch (e) {
    print('Error getting watchlist pairs: $e');
    return ['USD/PKR', 'GBP/PKR', 'EUR/PKR']; // Fallback
  }
}

/// Set watchlist pairs (simplified - always uses fixed pairs)
Future<void> setWatchlistPairs(List<String> pairs) async {
  try {
    // Always use fixed pairs regardless of input
    final fixedPairs = ['USD/PKR', 'GBP/PKR', 'EUR/PKR'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('watchlist_pairs', fixedPairs);
    
    // Update widget
    await updateWatchlistWidget(currencyPairs: fixedPairs);
  } catch (e) {
    print('Error setting watchlist pairs: $e');
  }
}

/// Initialize watchlist widget with default values
Future<void> initializeWatchlistWidget() async {
  try {
    // Clear any old default pairs before initializing
    await _clearOldDefaultPairsFromWidget();
    
    final pairs = await getWatchlistPairs();
    await updateWatchlistWidget(currencyPairs: pairs);
    print('Watchlist widget initialized successfully');
  } catch (e) {
    print('Error initializing watchlist widget: $e');
  }
}

/// Clear any old default pairs that might be cached in widget preferences
Future<void> _clearOldDefaultPairsFromWidget() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Check for old default pairs
    List<String> pairs = prefs.getStringList('watchlist_pairs') ?? [];
    String? flutterPairsString = prefs.getString('flutter.watchlist_pairs');
    
    final oldDefaults = ['USD/PKR', 'USD/INR', 'USD/AED'];
    final hasOldDefaults = pairs.any((pair) => oldDefaults.contains(pair));
    
    if (hasOldDefaults || (flutterPairsString != null && flutterPairsString.contains('USD/PKR'))) {
      print('Found old default pairs in widget initialization, clearing them');
      
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
      
      print('Cleared old default pairs during widget initialization');
    }
  } catch (e) {
    print('Error clearing old default pairs from widget: $e');
  }
}

/// Get available currency pairs for watchlist
List<String> getAvailableCurrencyPairs() {
  return [
    'EUR/USD', 'GBP/USD', 'USD/JPY', 'USD/CHF', 'AUD/USD', 'USD/CAD',
    'NZD/USD', 'USD/CNY', 'USD/INR', 'USD/PKR', 'EUR/GBP', 'EUR/JPY',
    'GBP/JPY', 'AUD/JPY', 'USD/SGD', 'USD/HKD', 'USD/KRW', 'USD/THB',
    'USD/MYR', 'USD/IDR', 'USD/PHP', 'USD/VND', 'USD/BDT', 'USD/LKR',
    'USD/NPR', 'USD/MMK', 'USD/KHR', 'USD/LAK', 'USD/MVR', 'USD/BTN',
    'USD/MNT', 'USD/AFN', 'USD/ALL', 'USD/AMD', 'USD/AZN', 'USD/BAM',
    'USD/BGN', 'USD/BHD', 'USD/BIF', 'USD/BMD', 'USD/BND', 'USD/BOB',
    'USD/BRL', 'USD/BSD', 'USD/BTN', 'USD/BWP', 'USD/BYN', 'USD/BZD',
    'USD/CDF', 'USD/CLP', 'USD/COP', 'USD/CRC', 'USD/CUP', 'USD/CVE',
    'USD/CZK', 'USD/DJF', 'USD/DKK', 'USD/DOP', 'USD/DZD', 'USD/EGP',
    'USD/ERN', 'USD/ETB', 'USD/FJD', 'USD/FKP', 'USD/GEL', 'USD/GHS',
    'USD/GIP', 'USD/GMD', 'USD/GNF', 'USD/GTQ', 'USD/GYD', 'USD/HNL',
    'USD/HRK', 'USD/HTG', 'USD/HUF', 'USD/ILS', 'USD/IQD', 'USD/IRR',
    'USD/ISK', 'USD/JMD', 'USD/JOD', 'USD/KES', 'USD/KGS', 'USD/KHR',
    'USD/KMF', 'USD/KPW', 'USD/KWD', 'USD/KYD', 'USD/KZT', 'USD/LAK',
    'USD/LBP', 'USD/LKR', 'USD/LRD', 'USD/LSL', 'USD/LYD', 'USD/MAD',
    'USD/MDL', 'USD/MGA', 'USD/MKD', 'USD/MMK', 'USD/MNT', 'USD/MOP',
    'USD/MRU', 'USD/MUR', 'USD/MVR', 'USD/MWK', 'USD/MXN', 'USD/MYR',
    'USD/MZN', 'USD/NAD', 'USD/NGN', 'USD/NIO', 'USD/NOK', 'USD/NPR',
    'USD/NZD', 'USD/OMR', 'USD/PAB', 'USD/PEN', 'USD/PGK', 'USD/PHP',
    'USD/PKR', 'USD/PLN', 'USD/PYG', 'USD/QAR', 'USD/RON', 'USD/RSD',
    'USD/RUB', 'USD/RWF', 'USD/SAR', 'USD/SBD', 'USD/SCR', 'USD/SDG',
    'USD/SEK', 'USD/SGD', 'USD/SHP', 'USD/SLL', 'USD/SOS', 'USD/SRD',
    'USD/SSP', 'USD/STD', 'USD/SYP', 'USD/SZL', 'USD/THB', 'USD/TJS',
    'USD/TMT', 'USD/TND', 'USD/TOP', 'USD/TRY', 'USD/TTD', 'USD/TWD',
    'USD/TZS', 'USD/UAH', 'USD/UGX', 'USD/UYU', 'USD/UZS', 'USD/VEF',
    'USD/VND', 'USD/VUV', 'USD/WST', 'USD/XAF', 'USD/XCD', 'USD/XOF',
    'USD/XPF', 'USD/YER', 'USD/ZAR', 'USD/ZMW', 'USD/ZWL',
  ];
}
