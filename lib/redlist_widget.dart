import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const platform = MethodChannel('currensee_widget_channel');

/// Update RedList widget with new data
Future<void> updateRedListWidget({
  List<Map<String, dynamic>>? currencyData,
}) async {
  try {
    await platform.invokeMethod('updateRedListWidget');
    print('RedList widget update requested');
  } catch (e) {
    print('Error updating RedList widget: $e');
  }
}

/// Initialize RedList widget with default values
Future<void> initializeRedListWidget() async {
  try {
    // Set default currency data
    final defaultCurrencies = [
      {'code': 'EUR', 'name': 'Eurozone', 'rate': 0.8500},
      {'code': 'JPY', 'name': 'Japan', 'rate': 150.25},
      {'code': 'GBP', 'name': 'United Kingdom', 'rate': 0.7500},
      {'code': 'PKR', 'name': 'Pakistan', 'rate': 280.50},
      {'code': 'INR', 'name': 'India', 'rate': 83.25},
      {'code': 'CNY', 'name': 'China', 'rate': 7.2000},
    ];

    // Save default data to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < defaultCurrencies.length; i++) {
      final currency = defaultCurrencies[i];
      await prefs.setString(
        'redlist_country_${i + 1}',
        currency['name'] as String,
      );
      await prefs.setString(
        'redlist_rate_${i + 1}',
        currency['rate'].toString(),
      );
    }

    // Update widget
    await updateRedListWidget(currencyData: defaultCurrencies);
    print('RedList widget initialized successfully');
  } catch (e) {
    print('Error initializing RedList widget: $e');
  }
}

/// Get current RedList data
Future<List<Map<String, dynamic>>> getRedListData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final currencies = ['EUR', 'JPY', 'GBP', 'PKR', 'INR', 'CNY'];

    List<Map<String, dynamic>> data = [];
    for (int i = 0; i < currencies.length; i++) {
      final country = prefs.getString('redlist_country_${i + 1}') ?? '';
      final rate = prefs.getString('redlist_rate_${i + 1}') ?? '0.0000';

      data.add({
        'code': currencies[i],
        'name': country,
        'rate': double.tryParse(rate) ?? 0.0,
      });
    }

    return data;
  } catch (e) {
    print('Error getting RedList data: $e');
    return [];
  }
}

/// Set RedList currency data
Future<void> setRedListData(List<Map<String, dynamic>> currencyData) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    for (int i = 0; i < currencyData.length && i < 6; i++) {
      final currency = currencyData[i];
      await prefs.setString(
        'redlist_country_${i + 1}',
        currency['name'] as String,
      );
      await prefs.setString(
        'redlist_rate_${i + 1}',
        currency['rate'].toString(),
      );
    }

    // Update widget
    await updateRedListWidget(currencyData: currencyData);
  } catch (e) {
    print('Error setting RedList data: $e');
  }
}
