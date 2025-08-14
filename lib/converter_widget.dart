import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

/// Save converter widget data and trigger update
Future<void> updateConverterWidget({
  required String fromCurrency,
  required String toCurrency,
}) async {
  try {
    // Save to SharedPreferences for Android widget
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('converter_from_currency', fromCurrency);
    await prefs.setString('converter_to_currency', toCurrency);

    // Trigger widget update
    try {
      const platform = MethodChannel('currensee_widget_channel');
      await platform.invokeMethod('updateConverterWidget');
    } catch (methodChannelError) {
      print('MethodChannel update error: $methodChannelError');
    }

    print('Converter widget updated successfully: $fromCurrency to $toCurrency');
  } catch (e) {
    print('Error updating converter widget: $e');
  }
}

/// Get converter widget data from storage
Future<Map<String, dynamic>> getConverterWidgetData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return {
      'fromCurrency': prefs.getString('converter_from_currency') ?? 'USD',
      'toCurrency': prefs.getString('converter_to_currency') ?? 'PKR',
    };
  } catch (e) {
    print('Error getting converter widget data: $e');
    return {
      'fromCurrency': 'USD',
      'toCurrency': 'PKR',
    };
  }
}

/// Initialize converter widget with default values
Future<void> initializeConverterWidget() async {
  try {
    final data = await getConverterWidgetData();
    await updateConverterWidget(
      fromCurrency: data['fromCurrency'],
      toCurrency: data['toCurrency'],
    );
    print('Converter widget initialized successfully');
  } catch (e) {
    print('Error initializing converter widget: $e');
    // Set default values if initialization fails
    try {
      await updateConverterWidget(fromCurrency: 'USD', toCurrency: 'PKR');
    } catch (defaultError) {
      print('Error setting default converter widget values: $defaultError');
    }
  }
}

/// Update converter widget with new currencies
Future<void> updateConverterWidgetCurrencies(String fromCurrency, String toCurrency) async {
  try {
    await updateConverterWidget(
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
    );
  } catch (e) {
    print('Error updating converter widget currencies: $e');
  }
}

/// Swap currencies in converter widget
Future<void> swapConverterWidgetCurrencies() async {
  try {
    final data = await getConverterWidgetData();
    await updateConverterWidget(
      fromCurrency: data['toCurrency'],
      toCurrency: data['fromCurrency'],
    );
  } catch (e) {
    print('Error swapping converter widget currencies: $e');
  }
}
