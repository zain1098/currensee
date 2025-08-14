import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const platform = MethodChannel('currensee_widget_channel');

/// Update Mini Chart widget with new data
Future<void> updateMiniChartWidget({
  Map<String, dynamic>? chartData,
}) async {
  try {
    await platform.invokeMethod('updateMiniChartWidget');
    print('Mini Chart widget update requested');
  } catch (e) {
    print('Error updating Mini Chart widget: $e');
  }
}

/// Initialize Mini Chart widget with default values
Future<void> initializeMiniChartWidget() async {
  try {
    // Set default chart data
    final defaultData = {
      'currencyPair': 'USD → PKR',
      'currentRate': 276.50,
      'percentageChange': 0.42,
      'chartPoints': [275.0, 275.5, 274.0, 276.0, 277.0],
    };

    // Save default data to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('minichart_currency_pair', defaultData['currencyPair'] as String);
    await prefs.setDouble('minichart_current_rate', defaultData['currentRate'] as double);
    await prefs.setDouble('minichart_percentage_change', defaultData['percentageChange'] as double);
    
    // Save chart points
    final chartPoints = defaultData['chartPoints'] as List<double>;
    for (int i = 0; i < chartPoints.length; i++) {
      await prefs.setDouble('minichart_point_$i', chartPoints[i]);
    }
    
    // Update widget
    await updateMiniChartWidget(chartData: defaultData);
    print('Mini Chart widget initialized successfully');
  } catch (e) {
    print('Error initializing Mini Chart widget: $e');
  }
}

/// Get current Mini Chart data
Future<Map<String, dynamic>> getMiniChartData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    final currencyPair = prefs.getString('minichart_currency_pair') ?? 'USD → PKR';
    final currentRate = prefs.getDouble('minichart_current_rate') ?? 276.50;
    final percentageChange = prefs.getDouble('minichart_percentage_change') ?? 0.42;
    
    // Get chart points
    List<double> chartPoints = [];
    for (int i = 0; i < 5; i++) {
      final point = prefs.getDouble('minichart_point_$i') ?? 276.0;
      chartPoints.add(point);
    }
    
    return {
      'currencyPair': currencyPair,
      'currentRate': currentRate,
      'percentageChange': percentageChange,
      'chartPoints': chartPoints,
    };
  } catch (e) {
    print('Error getting Mini Chart data: $e');
    return {
      'currencyPair': 'USD → PKR',
      'currentRate': 276.50,
      'percentageChange': 0.42,
      'chartPoints': [275.0, 275.5, 274.0, 276.0, 277.0],
    };
  }
}

/// Set Mini Chart data
Future<void> setMiniChartData(Map<String, dynamic> chartData) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('minichart_currency_pair', chartData['currencyPair'] as String);
    await prefs.setDouble('minichart_current_rate', chartData['currentRate'] as double);
    await prefs.setDouble('minichart_percentage_change', chartData['percentageChange'] as double);
    
    // Save chart points
    final chartPoints = chartData['chartPoints'] as List<double>;
    for (int i = 0; i < chartPoints.length && i < 5; i++) {
      await prefs.setDouble('minichart_point_$i', chartPoints[i]);
    }
    
    // Update widget
    await updateMiniChartWidget(chartData: chartData);
  } catch (e) {
    print('Error setting Mini Chart data: $e');
  }
}
