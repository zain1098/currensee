import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'main.dart'; // For CustomAppBar
import 'news_page.dart';
import 'trend_chart.dart';
import 'rate_list_page.dart';
import 'task_page.dart';
import 'package:provider/provider.dart';
import 'calculator_page.dart';
import 'setting_page.dart';
import 'world_clock.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'support_help_screen.dart';
import 'services/currency_service.dart';

class MultiCurrencyConverter extends StatefulWidget {
  const MultiCurrencyConverter({super.key});

  @override
  _MultiCurrencyConverterState createState() => _MultiCurrencyConverterState();
}

class _MultiCurrencyConverterState extends State<MultiCurrencyConverter> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Currency> currencies = [];
  Currency? baseCurrency;
  double amount = 1.0;
  TextEditingController amountController = TextEditingController();
  Map<String, double> rates = {};
  bool isLoading = true;
  String? errorMessage;
  List<String> selectedCurrencies = [];
  Map<String, double> conversionResults = {};
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _baseCurrencySearchController =
      TextEditingController();
  String searchQuery = '';
  String baseCurrencySearchQuery = '';

  // Database-driven currency data
  List<dynamic> _databaseCurrencies = [];

  // Fallback currency data (used if database fails)
  final Map<String, String> currencyFlags = {
    'USD': '🇺🇸',
    'EUR': '🇪🇺',
    'GBP': '🇬🇧',
    'JPY': '🇯🇵',
    'INR': '🇮🇳',
    'AUD': '🇦🇺',
    'CAD': '🇨🇦',
    'CHF': '🇨🇭',
    'CNY': '🇨🇳',
    'NZD': '🇳🇿',
    'SEK': '🇸🇪',
    'SGD': '🇸🇬',
    'NOK': '🇳🇴',
    'KRW': '🇰🇷',
    'TRY': '🇹🇷',
    'BRL': '🇧🇷',
    'RUB': '🇷🇺',
    'ZAR': '🇿🇦',
    'MXN': '🇲🇽',
    'IDR': '🇮🇩',
    'THB': '🇹🇭',
    'HKD': '🇭🇰',
    'SAR': '🇸🇦',
    'AED': '🇦🇪',
    'PLN': '🇵🇱',
    'HUF': '🇭🇺',
    'CZK': '🇨🇿',
    'ILS': '🇮🇱',
    'CLP': '🇨🇱',
    'PHP': '🇵🇭',
    'MYR': '🇲🇾',
    'RON': '🇷🇴',
    'COP': '🇨🇴',
    'VND': '🇻🇳',
    'EGP': '🇪🇬',
    'PKR': '🇵🇰',
    'BDT': '🇧🇩',
    'DKK': '🇩🇰',
    'ARS': '🇦🇷',
    'NGN': '🇳🇬',
    'UAH': '🇺🇦',
    'KZT': '🇰🇿',
    'QAR': '🇶🇦',
    'PEN': '🇵🇪',
    'KWD': '🇰🇼',
    'OMR': '🇴🇲',
    'BHD': '🇧🇭',
    'LKR': '🇱🇰',
    'DZD': '🇩🇿',
    'MAD': '🇲🇦',
    'TWD': '🇹🇼',
    'JOD': '🇯🇴',
    'HNL': '🇭🇳',
    'GTQ': '🇬🇹',
    'CRC': '🇨🇷',
    'UYU': '🇺🇾',
    'BOB': '🇧🇴',
    'PYG': '🇵🇾',
    'DOP': '🇩🇴',
    'JMD': '🇯🇲',
    'BGN': '🇧🇬',
    'HRK': '🇭🇷',
    'RSD': '🇷🇸',
    'ISK': '🇮🇸',
    'FJD': '🇫🇯',
    'BWP': '🇧🇼',
    'NAD': '🇳🇦',
    'ZMW': '🇿🇲',
    'ETB': '🇪🇹',
    'KES': '🇰🇪',
    'TZS': '🇹🇿',
    'UGX': '🇺🇬',
    'GHS': '🇬🇭',
    'XOF': '🇧🇯',
    'XAF': '🇨🇲',
  };

  final Map<String, String> currencyNames = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'INR': 'Indian Rupee',
    'AUD': 'Australian Dollar',
    'CAD': 'Canadian Dollar',
    'CHF': 'Swiss Franc',
    'CNY': 'Chinese Yuan',
    'NZD': 'New Zealand Dollar',
    'SEK': 'Swedish Krona',
    'SGD': 'Singapore Dollar',
    'NOK': 'Norwegian Krone',
    'KRW': 'South Korean Won',
    'TRY': 'Turkish Lira',
    'BRL': 'Brazilian Real',
    'RUB': 'Russian Ruble',
    'ZAR': 'South African Rand',
    'MXN': 'Mexican Peso',
    'IDR': 'Indonesian Rupiah',
    'THB': 'Thai Baht',
    'HKD': 'Hong Kong Dollar',
    'SAR': 'Saudi Riyal',
    'AED': 'UAE Dirham',
    'PLN': 'Polish Złoty',
    'HUF': 'Hungarian Forint',
    'CZK': 'Czech Koruna',
    'ILS': 'Israeli Shekel',
    'CLP': 'Chilean Peso',
    'PHP': 'Philippine Peso',
    'MYR': 'Malaysian Ringgit',
    'RON': 'Romanian Leu',
    'COP': 'Colombian Peso',
    'VND': 'Vietnamese Dong',
    'EGP': 'Egyptian Pound',
    'PKR': 'Pakistani Rupee',
    'BDT': 'Bangladeshi Taka',
    'DKK': 'Danish Krone',
    'ARS': 'Argentine Peso',
    'NGN': 'Nigerian Naira',
    'UAH': 'Ukrainian Hryvnia',
    'KZT': 'Kazakhstani Tenge',
    'QAR': 'Qatari Riyal',
    'PEN': 'Peruvian Sol',
    'KWD': 'Kuwaiti Dinar',
    'OMR': 'Omani Rial',
    'BHD': 'Bahraini Dinar',
    'LKR': 'Sri Lankan Rupee',
    'DZD': 'Algerian Dinar',
    'MAD': 'Moroccan Dirham',
    'TWD': 'New Taiwan Dollar',
    'JOD': 'Jordanian Dinar',
    'HNL': 'Honduran Lempira',
    'GTQ': 'Guatemalan Quetzal',
    'CRC': 'Costa Rican Colón',
    'UYU': 'Uruguayan Peso',
    'BOB': 'Bolivian Boliviano',
    'PYG': 'Paraguayan Guarani',
    'DOP': 'Dominican Peso',
    'JMD': 'Jamaican Dollar',
    'BGN': 'Bulgarian Lev',
    'HRK': 'Croatian Kuna',
    'RSD': 'Serbian Dinar',
    'ISK': 'Icelandic Króna',
    'FJD': 'Fijian Dollar',
    'BWP': 'Botswana Pula',
    'NAD': 'Namibian Dollar',
    'ZMW': 'Zambian Kwacha',
    'ETB': 'Ethiopian Birr',
    'KES': 'Kenyan Shilling',
    'TZS': 'Tanzanian Shilling',
    'UGX': 'Ugandan Shilling',
    'GHS': 'Ghanaian Cedi',
    'XOF': 'West African CFA Franc',
    'XAF': 'Central African CFA Franc',
  };

  @override
  void initState() {
    super.initState();
    _loadCurrenciesFromDatabase();
    amountController.text = amount.toStringAsFixed(2);
  }

  Future<void> _loadCurrenciesFromDatabase() async {
    try {
      final loadedCurrencies = await CurrencyService.loadCurrencies();
      setState(() {
        _databaseCurrencies = loadedCurrencies;
      });

      // Set default currencies with fallback logic
      if (_databaseCurrencies.isNotEmpty) {
        // Get preferred base currency (USD) with fallback
        final preferredBase = _databaseCurrencies.firstWhere(
          (c) => c.code == 'USD',
          orElse: () => _databaseCurrencies.first,
        );

        // Convert service Currency to local Currency
        final localCurrency = Currency(
          code: preferredBase.code,
          name: preferredBase.name,
          symbol: preferredBase.symbol,
          flag: preferredBase.flag,
          status: preferredBase.status,
        );

        setState(() {
          baseCurrency = localCurrency;
          selectedCurrencies = ['EUR', 'GBP', 'JPY', 'INR', 'CAD', 'AUD'];
        });
      }

      fetchExchangeRates();
    } catch (e) {
      print('Error loading currencies from database: $e');
      // Fallback to hardcoded currencies
      initializeCurrencies();
    }
  }

  // Get currency information from database or fallback
  Map<String, dynamic> _getCurrencyInfo(String code) {
    try {
      final currency = _databaseCurrencies.firstWhere((c) => c.code == code);
      return {
        'code': currency.code,
        'name': currency.name,
        'flag': currency.flag,
        'symbol': currency.symbol,
        'status': currency.status,
      };
    } catch (e) {
      // Fallback to hardcoded data
      return {
        'code': code,
        'name': currencyNames[code] ?? code,
        'flag': currencyFlags[code] ?? '💱',
        'symbol': _getCurrencySymbol(code),
        'status': 'active', // Assume active for fallback
      };
    }
  }

  // Get available currencies for display (all currencies from database)
  List<Currency> get availableCurrencies {
    if (_databaseCurrencies.isNotEmpty) {
      // Convert service Currency objects to local Currency objects
      return _databaseCurrencies
          .map(
            (serviceCurrency) => Currency(
              code: serviceCurrency.code,
              name: serviceCurrency.name,
              symbol: serviceCurrency.symbol,
              flag: serviceCurrency.flag,
              status: serviceCurrency.status,
            ),
          )
          .toList();
    }
    return currencies;
  }

  String _getCurrencySymbol(String code) {
    const symbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'AUD': 'A\$',
      'CAD': 'C\$',
      'CHF': 'Fr',
      'CNY': '¥',
      'INR': '₹',
      'SGD': 'S\$',
      'KRW': '₩',
      'RUB': '₽',
      'TRY': '₺',
      'THB': '฿',
      'PLN': 'zł',
      'HUF': 'Ft',
      'CZK': 'Kč',
      'DKK': 'kr',
      'SEK': 'kr',
      'NOK': 'kr',
    };
    return symbols[code] ?? code;
  }

  void initializeCurrencies() {
    currencies = [
      Currency(code: 'USD', name: 'US Dollar', symbol: '\$', flag: '🇺🇸'),
      Currency(code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺'),
      Currency(code: 'GBP', name: 'British Pound', symbol: '£', flag: '🇬🇧'),
      Currency(code: 'JPY', name: 'Japanese Yen', symbol: '¥', flag: '🇯🇵'),
      Currency(code: 'INR', name: 'Indian Rupee', symbol: '₹', flag: '🇮🇳'),
      Currency(
        code: 'AUD',
        name: 'Australian Dollar',
        symbol: 'A\$',
        flag: '🇦🇺',
      ),
      Currency(
        code: 'CAD',
        name: 'Canadian Dollar',
        symbol: 'C\$',
        flag: '🇨🇦',
      ),
      Currency(code: 'CHF', name: 'Swiss Franc', symbol: 'Fr', flag: '🇨🇭'),
      Currency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', flag: '🇨🇳'),
      Currency(
        code: 'NZD',
        name: 'New Zealand Dollar',
        symbol: 'NZ\$',
        flag: '🇳🇿',
      ),
      Currency(code: 'SEK', name: 'Swedish Krona', symbol: 'kr', flag: '🇸🇪'),
      Currency(
        code: 'SGD',
        name: 'Singapore Dollar',
        symbol: 'S\$',
        flag: '🇸🇬',
      ),
      Currency(
        code: 'NOK',
        name: 'Norwegian Krone',
        symbol: 'kr',
        flag: '🇳🇴',
      ),
      Currency(
        code: 'KRW',
        name: 'South Korean Won',
        symbol: '₩',
        flag: '🇰🇷',
      ),
      Currency(code: 'TRY', name: 'Turkish Lira', symbol: '₺', flag: '🇹🇷'),
      Currency(
        code: 'BRL',
        name: 'Brazilian Real',
        symbol: 'R\$',
        flag: '🇧🇷',
      ),
      Currency(code: 'RUB', name: 'Russian Ruble', symbol: '₽', flag: '🇷🇺'),
      Currency(
        code: 'ZAR',
        name: 'South African Rand',
        symbol: 'R',
        flag: '🇿🇦',
      ),
      Currency(code: 'MXN', name: 'Mexican Peso', symbol: '\$', flag: '🇲🇽'),
      Currency(
        code: 'IDR',
        name: 'Indonesian Rupiah',
        symbol: 'Rp',
        flag: '🇮🇩',
      ),
      Currency(code: 'THB', name: 'Thai Baht', symbol: '฿', flag: '🇹🇭'),
      Currency(
        code: 'HKD',
        name: 'Hong Kong Dollar',
        symbol: 'HK\$',
        flag: '🇭🇰',
      ),
      Currency(code: 'SAR', name: 'Saudi Riyal', symbol: '﷼', flag: '🇸🇦'),
      Currency(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ', flag: '🇦🇪'),
      Currency(code: 'PLN', name: 'Polish Złoty', symbol: 'zł', flag: '🇵🇱'),
      Currency(
        code: 'HUF',
        name: 'Hungarian Forint',
        symbol: 'Ft',
        flag: '🇭🇺',
      ),
      Currency(code: 'CZK', name: 'Czech Koruna', symbol: 'Kč', flag: '🇨🇿'),
      Currency(code: 'ILS', name: 'Israeli Shekel', symbol: '₪', flag: '🇮🇱'),
      Currency(code: 'CLP', name: 'Chilean Peso', symbol: '\$', flag: '🇨🇱'),
      Currency(code: 'PHP', name: 'Philippine Peso', symbol: '₱', flag: '🇵🇭'),
      Currency(
        code: 'MYR',
        name: 'Malaysian Ringgit',
        symbol: 'RM',
        flag: '🇲🇾',
      ),
      Currency(code: 'RON', name: 'Romanian Leu', symbol: 'lei', flag: '🇷🇴'),
      Currency(code: 'COP', name: 'Colombian Peso', symbol: '\$', flag: '🇨🇴'),
      Currency(code: 'VND', name: 'Vietnamese Dong', symbol: '₫', flag: '🇻🇳'),
      Currency(code: 'EGP', name: 'Egyptian Pound', symbol: 'E£', flag: '🇪🇬'),
      Currency(code: 'PKR', name: 'Pakistani Rupee', symbol: '₨', flag: '🇵🇰'),
      Currency(
        code: 'BDT',
        name: 'Bangladeshi Taka',
        symbol: '৳',
        flag: '🇧🇩',
      ),
      Currency(code: 'DKK', name: 'Danish Krone', symbol: 'kr', flag: '🇩🇰'),
      Currency(code: 'ARS', name: 'Argentine Peso', symbol: '\$', flag: '🇦🇷'),
      Currency(code: 'NGN', name: 'Nigerian Naira', symbol: '₦', flag: '🇳🇬'),
      Currency(
        code: 'UAH',
        name: 'Ukrainian Hryvnia',
        symbol: '₴',
        flag: '🇺🇦',
      ),
      Currency(
        code: 'KZT',
        name: 'Kazakhstani Tenge',
        symbol: '₸',
        flag: '🇰🇿',
      ),
      Currency(code: 'QAR', name: 'Qatari Riyal', symbol: '﷼', flag: '🇶🇦'),
      Currency(code: 'PEN', name: 'Peruvian Sol', symbol: 'S/', flag: '🇵🇪'),
      Currency(code: 'KWD', name: 'Kuwaiti Dinar', symbol: 'د.ك', flag: '🇰🇼'),
      Currency(code: 'OMR', name: 'Omani Rial', symbol: '﷼', flag: '🇴🇲'),
      Currency(
        code: 'BHD',
        name: 'Bahraini Dinar',
        symbol: '.د.ب',
        flag: '🇧🇭',
      ),
      Currency(
        code: 'LKR',
        name: 'Sri Lankan Rupee',
        symbol: 'Rs',
        flag: '🇱🇰',
      ),
      Currency(
        code: 'DZD',
        name: 'Algerian Dinar',
        symbol: 'د.ج',
        flag: '🇩🇿',
      ),
      Currency(
        code: 'MAD',
        name: 'Moroccan Dirham',
        symbol: 'د.م.',
        flag: '🇲🇦',
      ),
      Currency(
        code: 'TWD',
        name: 'New Taiwan Dollar',
        symbol: 'NT\$',
        flag: '🇹🇼',
      ),
      Currency(
        code: 'JOD',
        name: 'Jordanian Dinar',
        symbol: 'د.ا',
        flag: '🇯🇴',
      ),
      Currency(
        code: 'HNL',
        name: 'Honduran Lempira',
        symbol: 'L',
        flag: '🇭🇳',
      ),
      Currency(
        code: 'GTQ',
        name: 'Guatemalan Quetzal',
        symbol: 'Q',
        flag: '🇬🇹',
      ),
      Currency(
        code: 'CRC',
        name: 'Costa Rican Colón',
        symbol: '₡',
        flag: '🇨🇷',
      ),
      Currency(
        code: 'UYU',
        name: 'Uruguayan Peso',
        symbol: '\$U',
        flag: '🇺🇾',
      ),
      Currency(
        code: 'BOB',
        name: 'Bolivian Boliviano',
        symbol: 'Bs.',
        flag: '🇧🇴',
      ),
      Currency(
        code: 'PYG',
        name: 'Paraguayan Guarani',
        symbol: '₲',
        flag: '🇵🇾',
      ),
      Currency(
        code: 'DOP',
        name: 'Dominican Peso',
        symbol: 'RD\$',
        flag: '🇩🇴',
      ),
      Currency(
        code: 'JMD',
        name: 'Jamaican Dollar',
        symbol: 'J\$',
        flag: '🇯🇲',
      ),
      Currency(code: 'BGN', name: 'Bulgarian Lev', symbol: 'лв', flag: '🇧🇬'),
      Currency(code: 'HRK', name: 'Croatian Kuna', symbol: 'kn', flag: '🇭🇷'),
      Currency(code: 'RSD', name: 'Serbian Dinar', symbol: 'дин', flag: '🇷🇸'),
      Currency(
        code: 'ISK',
        name: 'Icelandic Króna',
        symbol: 'kr',
        flag: '🇮🇸',
      ),
      Currency(
        code: 'FJD',
        name: 'Fijian Dollar',
        symbol: 'FJ\$',
        flag: '🇫🇯',
      ),
      Currency(code: 'BWP', name: 'Botswana Pula', symbol: 'P', flag: '🇧🇼'),
      Currency(
        code: 'NAD',
        name: 'Namibian Dollar',
        symbol: 'N\$',
        flag: '🇳🇦',
      ),
      Currency(code: 'ZMW', name: 'Zambian Kwacha', symbol: 'ZK', flag: '🇿🇲'),
      Currency(code: 'ETB', name: 'Ethiopian Birr', symbol: 'Br', flag: '🇪🇹'),
      Currency(
        code: 'KES',
        name: 'Kenyan Shilling',
        symbol: 'KSh',
        flag: '🇰🇪',
      ),
      Currency(
        code: 'TZS',
        name: 'Tanzanian Shilling',
        symbol: 'TSh',
        flag: '🇹🇿',
      ),
      Currency(
        code: 'UGX',
        name: 'Ugandan Shilling',
        symbol: 'USh',
        flag: '🇺🇬',
      ),
      Currency(code: 'GHS', name: 'Ghanaian Cedi', symbol: 'GH₵', flag: '🇬🇭'),
      Currency(
        code: 'XOF',
        name: 'West African CFA Franc',
        symbol: 'CFA',
        flag: '🇧🇯',
      ),
      Currency(
        code: 'XAF',
        name: 'Central African CFA Franc',
        symbol: 'FCFA',
        flag: '🇨🇲',
      ),
    ];

    setState(() {
      baseCurrency = currencies.firstWhere((c) => c.code == 'USD');
      selectedCurrencies = ['EUR', 'GBP', 'JPY', 'INR', 'CAD', 'AUD'];
    });

    fetchExchangeRates();
  }

  void _navigateAndClose(BuildContext context, Widget page) {
    Navigator.pop(context); // Close drawer
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
  }

  Future<void> fetchExchangeRates() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://open.er-api.com/v6/latest/${baseCurrency?.code ?? 'USD'}',
        ),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success') {
          setState(() {
            rates = (data['rates'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
            );
            isLoading = false;
          });
          calculateConversions();
        } else {
          setState(() {
            errorMessage = data['error-type'] ?? 'Unknown error';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load data. Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  void calculateConversions() {
    if (baseCurrency == null || selectedCurrencies.isEmpty) return;

    setState(() {
      conversionResults = {};
      for (var currencyCode in selectedCurrencies) {
        double rate = rates[currencyCode] ?? 1.0;
        conversionResults[currencyCode] = amount * rate;
      }
    });
  }

  void toggleCurrency(String currencyCode) {
    // Check if currency is inactive
    final currencyInfo = _getCurrencyInfo(currencyCode);
    if (currencyInfo['status'] == 'inactive') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${currencyInfo['name']} is temporarily blocked by the team',
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      if (selectedCurrencies.contains(currencyCode)) {
        selectedCurrencies.remove(currencyCode);
        conversionResults.remove(currencyCode);
      } else {
        selectedCurrencies.add(currencyCode);
        if (rates.isNotEmpty) {
          double rate = rates[currencyCode] ?? 1.0;
          conversionResults[currencyCode] = amount * rate;
        }
      }
    });
  }

  void copyToClipboard(String text) {
    if (!mounted) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void changeBaseCurrency(Currency newCurrency) {
    setState(() {
      baseCurrency = newCurrency;
      isLoading = true;
    });
    fetchExchangeRates();
  }

  List<Currency> getFilteredCurrencies() {
    if (searchQuery.isEmpty) return availableCurrencies;

    return availableCurrencies.where((currency) {
      final codeMatch = currency.code.toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
      final nameMatch = currency.name.toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
      return codeMatch || nameMatch;
    }).toList();
  }

  List<Currency> getFilteredBaseCurrencies() {
    if (baseCurrencySearchQuery.isEmpty) return availableCurrencies;

    return availableCurrencies.where((currency) {
      final codeMatch = currency.code.toLowerCase().contains(
        baseCurrencySearchQuery.toLowerCase(),
      );
      final nameMatch = currency.name.toLowerCase().contains(
        baseCurrencySearchQuery.toLowerCase(),
      );
      return codeMatch || nameMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCurrencies = getFilteredCurrencies();

    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        title: 'Multi Currency',
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors:
                  Theme.of(context).brightness == Brightness.dark
                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                      : [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Professional Drawer Header
              Container(
                height: 180,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        Theme.of(context).brightness == Brightness.dark
                            ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                            : [
                              const Color(0xFF1E3A8A),
                              const Color(0xFF2563EB),
                            ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Icon with subtle animation
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Lottie.asset(
                          'assets/Menu Icon.json', // Your app icon animation
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // App Name
                    const Text(
                      'CurrenSee Pro',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                    // Version text with fade-in animation
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: const Text(
                            'Version 2.0.0',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Menu Items
              _buildDrawerItem(
                context,
                icon: Icons.currency_exchange,
                title: 'Currency Converter',
                onTap: () => _navigateAndClose(context, const MainScreen()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.newspaper,
                title: 'Market News',
                onTap: () => _navigateAndClose(context, const NewsScreen()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.calculate,
                title: 'Multi-Currency',
                onTap:
                    () => _navigateAndClose(
                      context,
                      const MultiCurrencyConverter(),
                    ),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.trending_up,
                title: 'Trend Analysis',
                onTap:
                    () => _navigateAndClose(context, const CurrencyChartPage()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.timer,
                title: 'World Clock',
                onTap: () => _navigateAndClose(context, const WorldClockPage()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.list_alt,
                title: 'Rate List',
                onTap: () => _navigateAndClose(context, const RateListPage()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.calculate_outlined,
                title: 'Calculator',
                onTap:
                    () => _navigateAndClose(context, const CalculatorsScreen()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.task_alt,
                title: 'Currency Tasks',
                onTap: () => _navigateAndClose(context, const TaskPage()),
              ),
              const SizedBox(height: 16),
              Divider(color: Theme.of(context).dividerColor, height: 1),
              const SizedBox(height: 16),
              // Settings Section
              _buildDrawerItem(
                context,
                icon: Icons.settings,
                title: 'Settings',
                onTap:
                    () => _navigateAndClose(
                      context,
                      SettingsPage(
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
              ),
              _buildDrawerItem(
                context,
                icon: Icons.help_center,
                title: 'Help & Support',
                onTap:
                    () => _navigateAndClose(context, const SupportHelpScreen()),
              ),
              const SizedBox(height: 16),
              Divider(color: Theme.of(context).dividerColor, height: 1),
              const SizedBox(height: 16),
              _buildDrawerItem(
                context,
                icon: Icons.logout,
                title: 'Logout',
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? Center(
                child: Text(
                  'Error: $errorMessage',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // Input Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.05),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Base Currency Selector
                          InkWell(
                            onTap: () => _showBaseCurrencySelector(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(
                                      context,
                                    ).shadowColor.withOpacity(0.2),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    baseCurrency?.flag ?? '',
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Base Currency',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).hintColor,
                                          ),
                                        ),
                                        Text(
                                          baseCurrency?.name ?? '',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).textTheme.titleMedium?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    size: 24,
                                    color: Theme.of(context).iconTheme.color,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Amount Input
                          TextField(
                            controller: amountController,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).textTheme.titleLarge?.color,
                            ),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.attach_money,
                                size: 28,
                                color: Theme.of(context).primaryColor,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  Icons.refresh,
                                  color: Theme.of(context).primaryColor,
                                ),
                                onPressed: () {
                                  amountController.text = '1.0';
                                  amount = 1.0;
                                  calculateConversions();
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              hintText: 'Enter amount',
                              hintStyle: TextStyle(
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                            onChanged: (value) {
                              amount = double.tryParse(value) ?? 0.0;
                              calculateConversions();
                            },
                          ),
                        ],
                      ),
                    ),

                    // Selected Currencies Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        children: [
                          const Text(
                            'Selected Currencies',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (selectedCurrencies.isNotEmpty)
                            TextButton.icon(
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Copy All'),
                              onPressed: _copyAllResultsToClipboard,
                            ),
                        ],
                      ),
                    ),

                    // Selected Currencies Chips
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      height: 60,
                      child:
                          selectedCurrencies.isEmpty
                              ? Center(
                                child: Text(
                                  'Tap on currencies below to add them',
                                  style: TextStyle(
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: selectedCurrencies.length,
                                itemBuilder: (context, index) {
                                  final code = selectedCurrencies[index];
                                  final currencyInfo = _getCurrencyInfo(code);
                                  final isInactive =
                                      currencyInfo['status'] == 'inactive';
                                  final value = conversionResults[code] ?? 0.0;
                                  final formatter = NumberFormat.currency(
                                    symbol:
                                        currencyInfo['symbol'] ??
                                        _getCurrencySymbol(code),
                                    decimalDigits: 2,
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Chip(
                                      backgroundColor:
                                          isInactive
                                              ? Theme.of(
                                                context,
                                              ).disabledColor.withOpacity(0.2)
                                              : Theme.of(
                                                context,
                                              ).primaryColor.withOpacity(0.1),
                                      label: Text(
                                        '${currencyInfo['flag']} ${formatter.format(value)}',
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyMedium?.color,
                                        ),
                                      ),
                                      onDeleted: () => toggleCurrency(code),
                                      deleteIcon: Icon(
                                        Icons.close,
                                        size: 16,
                                        color:
                                            Theme.of(context).iconTheme.color,
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),

                    // Currency Search Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            searchQuery.isEmpty
                                ? 'All Currencies (${availableCurrencies.length})'
                                : 'Search Results (${filteredCurrencies.length})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.color,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.6,
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Search currencies...',
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                                suffixIcon:
                                    searchQuery.isNotEmpty
                                        ? IconButton(
                                          icon: Icon(
                                            Icons.clear,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).iconTheme.color,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              searchQuery = '';
                                            });
                                          },
                                        )
                                        : null,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Theme.of(context).cardColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Currency List
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.35,
                      child:
                          filteredCurrencies.isEmpty && searchQuery.isNotEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Theme.of(context).disabledColor,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No currencies found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleMedium?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try searching with different keywords',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).hintColor,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: filteredCurrencies.length,
                                itemBuilder: (context, index) {
                                  final currency = filteredCurrencies[index];
                                  final isSelected = selectedCurrencies
                                      .contains(currency.code);
                                  final currencyInfo = _getCurrencyInfo(
                                    currency.code,
                                  );
                                  final isInactive =
                                      currencyInfo['status'] == 'inactive';
                                  return _buildCurrencyListItem(
                                    currency,
                                    isSelected,
                                    isInactive,
                                  );
                                },
                              ),
                    ),

                    // Conversion Results
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).shadowColor.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Conversion Results',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.color,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: _copyAllResultsToClipboard,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.3,
                            child: ListView.builder(
                              itemCount: conversionResults.entries.length,
                              itemBuilder: (context, index) {
                                final entry = conversionResults.entries
                                    .elementAt(index);
                                return _buildConversionRow(
                                  entry.key,
                                  entry.value,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildCurrencyListItem(
    Currency currency,
    bool isSelected,
    bool isInactive,
  ) {
    return Opacity(
      opacity: isInactive ? 0.6 : 1.0,
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  isInactive
                      ? Theme.of(context).colorScheme.error.withOpacity(0.1)
                      : const Color(0xFF4A6CD1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(currency.flag, style: const TextStyle(fontSize: 24)),
            ),
          ),
          title: Row(
            children: [
              Text(
                currency.code,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      isInactive ? Theme.of(context).colorScheme.error : null,
                ),
              ),
              if (isInactive) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'BLOCKED',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(currency.name, style: const TextStyle(fontSize: 12)),
              if (isInactive)
                Text(
                  'Temporarily blocked by team',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          trailing:
              isInactive
                  ? null
                  : Switch(
                    value: isSelected,
                    onChanged: (_) => toggleCurrency(currency.code),
                    activeColor: const Color(0xFF4A6CD1),
                  ),
          onTap:
              isInactive
                  ? () {
                    // Show message when user taps on inactive currency
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${currency.name} is temporarily blocked by the team',
                        ),
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                  : () => toggleCurrency(currency.code),
          tileColor:
              isSelected ? const Color(0xFF4A6CD1).withOpacity(0.1) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildConversionRow(String currencyCode, double amount) {
    final currencyInfo = _getCurrencyInfo(currencyCode);
    final currency = Currency(
      code: currencyCode,
      name: currencyInfo['name'] ?? currencyCode,
      symbol: currencyInfo['symbol'] ?? _getCurrencySymbol(currencyCode),
      flag: currencyInfo['flag'] ?? '💱',
    );
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 2,
    );

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Text(currency.flag, style: const TextStyle(fontSize: 28)),
        title: Text(currency.name),
        subtitle: Text(currency.code),
        trailing: Text(
          formatter.format(amount),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        onTap: () => copyToClipboard(formatter.format(amount)),
        onLongPress: () => toggleCurrency(currencyCode),
      ),
    );
  }

  void _copyAllResultsToClipboard() {
    final buffer = StringBuffer();
    buffer.writeln('${baseCurrency?.name} ($amount):');
    conversionResults.forEach((code, value) {
      final currencyInfo = _getCurrencyInfo(code);
      final currency = Currency(
        code: code,
        name: currencyInfo['name'] ?? code,
        symbol: currencyInfo['symbol'] ?? _getCurrencySymbol(code),
        flag: currencyInfo['flag'] ?? '💱',
      );
      final formatter = NumberFormat.currency(
        symbol: currency.symbol,
        decimalDigits: 2,
      );
      buffer.writeln(
        '${currency.flag} ${currency.code}: ${formatter.format(value)}',
      );
    });
    copyToClipboard(buffer.toString());
  }

  void _showBaseCurrencySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    baseCurrencySearchQuery.isEmpty
                        ? 'Select Base Currency (${availableCurrencies.length})'
                        : 'Search Results (${getFilteredBaseCurrencies().length})',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _baseCurrencySearchController,
                    autofocus: true,
                    onChanged:
                        (value) =>
                            setState(() => baseCurrencySearchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search currencies...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      suffixIcon:
                          baseCurrencySearchQuery.isNotEmpty
                              ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                                onPressed: () {
                                  _baseCurrencySearchController.clear();
                                  setState(() {
                                    baseCurrencySearchQuery = '';
                                  });
                                },
                              )
                              : null,
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      hintStyle: TextStyle(color: Theme.of(context).hintColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child:
                        getFilteredBaseCurrencies().isEmpty &&
                                baseCurrencySearchQuery.isNotEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Theme.of(context).disabledColor,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No currencies found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try searching with different keywords',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              itemCount: getFilteredBaseCurrencies().length,
                              itemBuilder: (context, index) {
                                final currency =
                                    getFilteredBaseCurrencies()[index];
                                final isSelected =
                                    currency.code == baseCurrency?.code;
                                final currencyInfo = _getCurrencyInfo(
                                  currency.code,
                                );
                                final isInactive =
                                    currencyInfo['status'] == 'inactive';
                                return Opacity(
                                  opacity: isInactive ? 0.6 : 1.0,
                                  child: ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color:
                                            isInactive
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .error
                                                    .withOpacity(0.1)
                                                : const Color(
                                                  0xFF4A6CD1,
                                                ).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          currency.flag,
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(
                                          currency.code,
                                          style: TextStyle(
                                            color:
                                                isInactive
                                                    ? Theme.of(
                                                      context,
                                                    ).colorScheme.error
                                                    : null,
                                          ),
                                        ),
                                        if (isInactive) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.error,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'BLOCKED',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 8,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(currency.name),
                                        if (isInactive)
                                          Text(
                                            'Temporarily blocked by team',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.copyWith(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.error,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing:
                                        isSelected
                                            ? Icon(
                                              Icons.check,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                            )
                                            : null,
                                    onTap:
                                        isInactive
                                            ? () {
                                              // Show message when user taps on inactive currency
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '${currency.name} is temporarily blocked by the team',
                                                  ),
                                                  backgroundColor:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.secondary,
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                            }
                                            : () {
                                              changeBaseCurrency(currency);
                                              Navigator.pop(context);
                                            },
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class Currency {
  final String code;
  final String name;
  final String symbol;
  final String flag;
  final String status; // 'active' or 'inactive'

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    this.status = 'active', // Default to active
  });
}

Widget _buildDrawerItem(
  BuildContext context, {
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? Colors.white : Colors.white;
  final iconColor = isDark ? Colors.white : Colors.white;
  final chevronColor = isDark ? Colors.white70 : Colors.white70;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Material(
      borderRadius: BorderRadius.circular(12),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor:
            isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
        highlightColor:
            isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: chevronColor, size: 20),
            ],
          ),
        ),
      ),
    ),
  );
}
