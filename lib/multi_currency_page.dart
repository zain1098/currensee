import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'main.dart'; // For CustomAppBar
import 'news_page.dart';
import 'trend_chart.dart';
import 'rate_list_page.dart';
import 'package:provider/provider.dart';
import 'calculator_page.dart';
import 'setting_page.dart';
import 'world_clock.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'support_help_screen.dart';

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
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    initializeCurrencies();
    amountController.text = amount.toStringAsFixed(2);
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
    if (searchQuery.isEmpty) return currencies;

    return currencies.where((currency) {
      return currency.code.toLowerCase().contains(searchQuery.toLowerCase()) ||
          currency.name.toLowerCase().contains(searchQuery.toLowerCase());
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Professional Drawer Header
              Container(
                height: 180,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
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
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
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
              const Divider(color: Colors.white24, height: 1),
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
                  style: const TextStyle(color: Colors.red),
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
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
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
                                        const Text(
                                          'Base Currency',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          baseCurrency?.name ?? '',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down, size: 24),
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
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.attach_money,
                                size: 28,
                                color: Color(0xFF4A6CD1),
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Color(0xFF4A6CD1),
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
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              hintText: 'Enter amount',
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
                              ? const Center(
                                child: Text(
                                  'Tap on currencies below to add them',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                              : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: selectedCurrencies.length,
                                itemBuilder: (context, index) {
                                  final code = selectedCurrencies[index];
                                  final currency = currencies.firstWhere(
                                    (c) => c.code == code,
                                    orElse:
                                        () => Currency(
                                          code: code,
                                          name: code,
                                          symbol: '',
                                          flag: '',
                                        ),
                                  );
                                  final value = conversionResults[code] ?? 0.0;
                                  final formatter = NumberFormat.currency(
                                    symbol: currency.symbol,
                                    decimalDigits: 2,
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Chip(
                                      backgroundColor: const Color(
                                        0xFF4A6CD1,
                                      ).withOpacity(0.1),
                                      label: Text(
                                        '${currency.flag} ${formatter.format(value)}',
                                      ),
                                      onDeleted: () => toggleCurrency(code),
                                      deleteIcon: const Icon(
                                        Icons.close,
                                        size: 16,
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
                          const Text(
                            'All Currencies',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.6,
                            child: TextField(
                              controller: _searchController,
                              onChanged:
                                  (value) =>
                                      setState(() => searchQuery = value),
                              decoration: InputDecoration(
                                hintText: 'Search currencies...',
                                prefixIcon: const Icon(Icons.search),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Currency List
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.35,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredCurrencies.length,
                        itemBuilder: (context, index) {
                          final currency = filteredCurrencies[index];
                          final isSelected = selectedCurrencies.contains(
                            currency.code,
                          );
                          return _buildCurrencyListItem(currency, isSelected);
                        },
                      ),
                    ),

                    // Conversion Results
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
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
                              const Text(
                                'Conversion Results',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
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

  Widget _buildCurrencyListItem(Currency currency, bool isSelected) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Text(currency.flag, style: const TextStyle(fontSize: 28)),
        title: Text(
          currency.code,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(currency.name, style: const TextStyle(fontSize: 12)),
        trailing: Switch(
          value: isSelected,
          onChanged: (_) => toggleCurrency(currency.code),
          activeColor: const Color(0xFF4A6CD1),
        ),
        onTap: () => toggleCurrency(currency.code),
        tileColor: isSelected ? const Color(0xFF4A6CD1).withOpacity(0.1) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildConversionRow(String currencyCode, double amount) {
    final currency = currencies.firstWhere(
      (c) => c.code == currencyCode,
      orElse:
          () => Currency(
            code: currencyCode,
            name: currencyCode,
            symbol: '',
            flag: '',
          ),
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
      final currency = currencies.firstWhere(
        (c) => c.code == code,
        orElse: () => Currency(code: code, name: code, symbol: '', flag: ''),
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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    'Select Base Currency',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    autofocus: true,
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search currencies...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: getFilteredCurrencies().length,
                      itemBuilder: (context, index) {
                        final currency = getFilteredCurrencies()[index];
                        final isSelected = currency.code == baseCurrency?.code;
                        return ListTile(
                          leading: Text(
                            currency.flag,
                            style: const TextStyle(fontSize: 28),
                          ),
                          title: Text(currency.code),
                          subtitle: Text(currency.name),
                          trailing:
                              isSelected
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : null,
                          onTap: () {
                            changeBaseCurrency(currency);
                            Navigator.pop(context);
                          },
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

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
  });
}

Widget _buildDrawerItem(
  BuildContext context, {
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Material(
      borderRadius: BorderRadius.circular(12),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withOpacity(0.1),
        highlightColor: Colors.white.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
            ],
          ),
        ),
      ),
    ),
  );
}
