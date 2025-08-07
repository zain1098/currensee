import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

/// Extended currency codes and names
const List<Map<String, String>> currencies = [
  {'code': 'USD', 'name': 'US Dollar'},
  {'code': 'EUR', 'name': 'Euro'},
  {'code': 'GBP', 'name': 'British Pound'},
  {'code': 'JPY', 'name': 'Japanese Yen'},
  {'code': 'INR', 'name': 'Indian Rupee'},
  {'code': 'PKR', 'name': 'Pakistani Rupee'},
  {'code': 'CNY', 'name': 'Chinese Yuan'},
  {'code': 'AUD', 'name': 'Australian Dollar'},
  {'code': 'CAD', 'name': 'Canadian Dollar'},
  {'code': 'CHF', 'name': 'Swiss Franc'},
  {'code': 'SGD', 'name': 'Singapore Dollar'},
  {'code': 'NZD', 'name': 'New Zealand Dollar'},
  {'code': 'MXN', 'name': 'Mexican Peso'},
  {'code': 'BRL', 'name': 'Brazilian Real'},
  {'code': 'RUB', 'name': 'Russian Ruble'},
  {'code': 'KRW', 'name': 'South Korean Won'},
  {'code': 'TRY', 'name': 'Turkish Lira'},
  {'code': 'ZAR', 'name': 'South African Rand'},
  {'code': 'SEK', 'name': 'Swedish Krona'},
  {'code': 'NOK', 'name': 'Norwegian Krone'},
  {'code': 'DKK', 'name': 'Danish Krone'},
  {'code': 'PLN', 'name': 'Polish Złoty'},
  {'code': 'CZK', 'name': 'Czech Koruna'},
  {'code': 'HUF', 'name': 'Hungarian Forint'},
  {'code': 'RON', 'name': 'Romanian Leu'},
  {'code': 'BGN', 'name': 'Bulgarian Lev'},
  {'code': 'HRK', 'name': 'Croatian Kuna'},
  {'code': 'RSD', 'name': 'Serbian Dinar'},
  {'code': 'UAH', 'name': 'Ukrainian Hryvnia'},
  {'code': 'THB', 'name': 'Thai Baht'},
  {'code': 'MYR', 'name': 'Malaysian Ringgit'},
  {'code': 'IDR', 'name': 'Indonesian Rupiah'},
  {'code': 'PHP', 'name': 'Philippine Peso'},
  {'code': 'VND', 'name': 'Vietnamese Dong'},
  {'code': 'BDT', 'name': 'Bangladeshi Taka'},
  {'code': 'LKR', 'name': 'Sri Lankan Rupee'},
  {'code': 'NPR', 'name': 'Nepalese Rupee'},
  {'code': 'MMK', 'name': 'Myanmar Kyat'},
  {'code': 'KHR', 'name': 'Cambodian Riel'},
  {'code': 'LAK', 'name': 'Lao Kip'},
  {'code': 'MNT', 'name': 'Mongolian Tögrög'},
  {'code': 'KZT', 'name': 'Kazakhstani Tenge'},
  {'code': 'UZS', 'name': 'Uzbekistani Som'},
  {'code': 'TJS', 'name': 'Tajikistani Somoni'},
  {'code': 'TMT', 'name': 'Turkmenistan Manat'},
  {'code': 'GEL', 'name': 'Georgian Lari'},
  {'code': 'AMD', 'name': 'Armenian Dram'},
  {'code': 'AZN', 'name': 'Azerbaijani Manat'},
  {'code': 'BYN', 'name': 'Belarusian Ruble'},
  {'code': 'MDL', 'name': 'Moldovan Leu'},
  {'code': 'ALL', 'name': 'Albanian Lek'},
  {'code': 'MKD', 'name': 'Macedonian Denar'},
  {'code': 'BAM', 'name': 'Bosnia-Herzegovina Convertible Mark'},
  {'code': 'MNE', 'name': 'Montenegrin Euro'},
  {'code': 'XCD', 'name': 'East Caribbean Dollar'},
  {'code': 'BBD', 'name': 'Barbadian Dollar'},
  {'code': 'JMD', 'name': 'Jamaican Dollar'},
  {'code': 'TTD', 'name': 'Trinidad & Tobago Dollar'},
  {'code': 'BZD', 'name': 'Belize Dollar'},
  {'code': 'GTQ', 'name': 'Guatemalan Quetzal'},
  {'code': 'HNL', 'name': 'Honduran Lempira'},
  {'code': 'NIO', 'name': 'Nicaraguan Córdoba'},
  {'code': 'CRC', 'name': 'Costa Rican Colón'},
  {'code': 'PAB', 'name': 'Panamanian Balboa'},
  {'code': 'COP', 'name': 'Colombian Peso'},
  {'code': 'VES', 'name': 'Venezuelan Bolívar'},
  {'code': 'PEN', 'name': 'Peruvian Sol'},
  {'code': 'CLP', 'name': 'Chilean Peso'},
  {'code': 'ARS', 'name': 'Argentine Peso'},
  {'code': 'UYU', 'name': 'Uruguayan Peso'},
  {'code': 'PYG', 'name': 'Paraguayan Guaraní'},
  {'code': 'BOB', 'name': 'Bolivian Boliviano'},
  {'code': 'GYD', 'name': 'Guyanese Dollar'},
  {'code': 'SRD', 'name': 'Surinamese Dollar'},
  {'code': 'FJD', 'name': 'Fijian Dollar'},
  {'code': 'WST', 'name': 'Samoan Tālā'},
  {'code': 'TOP', 'name': 'Tongan Paʻanga'},
  {'code': 'VUV', 'name': 'Vanuatu Vatu'},
  {'code': 'SBD', 'name': 'Solomon Islands Dollar'},
  {'code': 'PGK', 'name': 'Papua New Guinean Kina'},
  {'code': 'KID', 'name': 'Kiribati Dollar'},
  {'code': 'TVD', 'name': 'Tuvaluan Dollar'},
  {'code': 'XPF', 'name': 'CFP Franc'},
  {'code': 'XAF', 'name': 'Central African CFA Franc'},
  {'code': 'XOF', 'name': 'West African CFA Franc'},
  {'code': 'CDF', 'name': 'Congolese Franc'},
  {'code': 'GHS', 'name': 'Ghanaian Cedi'},
  {'code': 'NGN', 'name': 'Nigerian Naira'},
  {'code': 'KES', 'name': 'Kenyan Shilling'},
  {'code': 'TZS', 'name': 'Tanzanian Shilling'},
  {'code': 'UGX', 'name': 'Ugandan Shilling'},
  {'code': 'MWK', 'name': 'Malawian Kwacha'},
  {'code': 'ZMW', 'name': 'Zambian Kwacha'},
  {'code': 'BWP', 'name': 'Botswana Pula'},
  {'code': 'NAD', 'name': 'Namibian Dollar'},
  {'code': 'LSL', 'name': 'Lesotho Loti'},
  {'code': 'SZL', 'name': 'Eswatini Lilangeni'},
  {'code': 'MUR', 'name': 'Mauritian Rupee'},
  {'code': 'SCR', 'name': 'Seychellois Rupee'},
  {'code': 'MVR', 'name': 'Maldivian Rufiyaa'},
];

/// Save widget data and trigger update
Future<void> updateCurrencyWidget({
  required double amount,
  required String fromCode,
  required String toCode,
}) async {
  try {
    // Fetch conversion result first
    final result = await fetchConversion(amount, fromCode, toCode);

    // Also fetch the rate for display
    String rateInfo = "1 $fromCode = 1.0000 $toCode";
    try {
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/$fromCode'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = Map<String, dynamic>.from(data['rates']);
        final rate = (rates[toCode] as num?)?.toDouble() ?? 1.0;
        rateInfo = "1 $fromCode = ${rate.toStringAsFixed(4)} $toCode";
      }
    } catch (e) {
      print('Error fetching rate info: $e');
    }

    // Save to SharedPreferences for Android widget - FIXED: Use same SharedPreferences name
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(
      'widget_amount',
      amount,
    ); // Keep double for Flutter compatibility
    await prefs.setString('widget_fromCode', fromCode);
    await prefs.setString('widget_toCode', toCode);
    await prefs.setString('widget_result', result);
    await prefs.setString('widget_rate_info', rateInfo);

    // Save to HomeWidget for Flutter widget
    await HomeWidget.saveWidgetData('amount', amount.toString());
    await HomeWidget.saveWidgetData('fromCode', fromCode);
    await HomeWidget.saveWidgetData('toCode', toCode);
    await HomeWidget.saveWidgetData('result', result);
    await HomeWidget.saveWidgetData('rate_info', rateInfo);

    // Trigger widget update
    try {
      await HomeWidget.updateWidget(
        androidName: 'Curren.See.HomeWidgetProvider',
        iOSName: 'HomeWidgetProvider',
      );

      // Also call native method to ensure widget updates
      try {
        const platform = MethodChannel('currensee_widget_channel');
        await platform.invokeMethod('updateWidget');
      } catch (methodChannelError) {
        print('MethodChannel update error: $methodChannelError');
        // Continue without MethodChannel if it fails
      }
    } catch (e) {
      print('HomeWidget update error: $e');
      // Widget update failed but don't throw - app should continue working
    }

    print('Widget updated successfully: $amount $fromCode = $result $toCode');
  } catch (e) {
    print('Error updating widget: $e');
  }
}

/// Fetch conversion using the same API as the Android widget
Future<String> fetchConversion(double amount, String from, String to) async {
  try {
    // Use the same API as the Android widget (exchangerate-api.com)
    final response = await http.get(
      Uri.parse('https://api.exchangerate-api.com/v4/latest/$from'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final rates = Map<String, dynamic>.from(data['rates']);
      final rate = (rates[to] as num?)?.toDouble() ?? 1.0;
      final converted = amount * rate;
      return converted.toStringAsFixed(2);
    } else {
      return 'Error';
    }
  } catch (e) {
    print('Error fetching conversion: $e');
    return 'Error';
  }
}

/// Get widget data from storage
Future<Map<String, dynamic>> getWidgetData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return {
      'amount': prefs.getDouble('widget_amount') ?? 1.0,
      'fromCode': prefs.getString('widget_fromCode') ?? 'USD',
      'toCode': prefs.getString('widget_toCode') ?? 'EUR',
      'result': prefs.getString('widget_result') ?? '0.00',
    };
  } catch (e) {
    print('Error getting widget data: $e');
    return {
      'amount': 1.0,
      'fromCode': 'USD',
      'toCode': 'EUR',
      'result': '0.00',
    };
  }
}

/// Initialize widget with default values
Future<void> initializeWidget() async {
  try {
    final data = await getWidgetData();
    await updateCurrencyWidget(
      amount: data['amount'],
      fromCode: data['fromCode'],
      toCode: data['toCode'],
    );
    print('Widget initialized successfully');

    // Force update the widget after initialization
    await Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        await HomeWidget.updateWidget(
          androidName: 'Curren.See.HomeWidgetProvider',
          iOSName: 'HomeWidgetProvider',
        );
        print('Widget force updated after initialization');
      } catch (e) {
        print('Error force updating widget: $e');
      }
    });
  } catch (e) {
    print('Error initializing widget: $e');
    // Set default values if initialization fails
    try {
      await updateCurrencyWidget(amount: 1.0, fromCode: 'USD', toCode: 'PKR');
    } catch (defaultError) {
      print('Error setting default widget values: $defaultError');
    }
  }
}

/// Force update widget with current app data
Future<void> forceUpdateWidget() async {
  try {
    await HomeWidget.updateWidget(
      androidName: 'Curren.See.HomeWidgetProvider',
      iOSName: 'HomeWidgetProvider',
    );
    print('Widget force updated successfully');
  } catch (e) {
    print('Error force updating widget: $e');
  }
}

/// Swap currencies in widget
Future<void> swapWidgetCurrencies() async {
  try {
    final data = await getWidgetData();
    await updateCurrencyWidget(
      amount: data['amount'],
      fromCode: data['toCode'],
      toCode: data['fromCode'],
    );
  } catch (e) {
    print('Error swapping widget currencies: $e');
  }
}

/// Update widget with new amount
Future<void> updateWidgetAmount(double amount) async {
  try {
    final data = await getWidgetData();
    await updateCurrencyWidget(
      amount: amount,
      fromCode: data['fromCode'],
      toCode: data['toCode'],
    );
  } catch (e) {
    print('Error updating widget amount: $e');
  }
}

/// Update widget with new currencies
Future<void> updateWidgetCurrencies(String fromCode, String toCode) async {
  try {
    final data = await getWidgetData();
    await updateCurrencyWidget(
      amount: data['amount'],
      fromCode: fromCode,
      toCode: toCode,
    );
  } catch (e) {
    print('Error updating widget currencies: $e');
  }
}

/// Test widget functionality
Future<void> testWidget() async {
  try {
    print('Testing widget functionality...');

    // Set test data
    await updateCurrencyWidget(amount: 100.0, fromCode: 'USD', toCode: 'PKR');

    // Force update
    await forceUpdateWidget();

    print('Widget test completed successfully');
  } catch (e) {
    print('Widget test failed: $e');
  }
}
