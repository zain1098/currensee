import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'main.dart'; // For CustomAppBar
import 'news_page.dart';
import 'world_clock.dart';
import 'rate_list_page.dart';
import 'package:provider/provider.dart';
import 'calculator_page.dart';
import 'setting_page.dart';
import 'multi_currency_page.dart' as multi_currency;
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'support_help_screen.dart';
import 'services/currency_service.dart';
import 'app_theme.dart';

class CurrencyChartPage extends StatefulWidget {
  const CurrencyChartPage({super.key});

  @override
  _CurrencyChartPageState createState() => _CurrencyChartPageState();
}

class _CurrencyChartPageState extends State<CurrencyChartPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String fromCurrency = 'USD';
  String toCurrency = 'EUR';
  String selectedTimeframe = '1W';
  double _currentRate = 1.0;
  double _previousRate = 1.0;
  double _conversionAmount = 1.0;
  double _convertedAmount = 1.0;
  late TabController _tabController;
  bool isLoading = true;
  String apiKey =
      'demo'; // Using demo key for testing, replace with actual API key

  final List<String> timeframes = ['1D', '1W', '1M', '3M', '6M', '1Y', 'All'];
  final List<String> chartTypes = ['Line', 'Area', 'Candle', 'Heikin Ashi'];
  String selectedChartType = 'Line';
  Color bullColor = const Color(0xFF00C853);
  Color bearColor = const Color(0xFFD50000);

  // Database-driven currency data
  List<Currency> _currencies = [];

  // Fallback currency data (used if database fails)
  final Map<String, String> currencyFlags = {
    'USD': '🇺🇸',
    'EUR': '🇪🇺',
    'GBP': '🇬🇧',
    'JPY': '🇯🇵',
    'AUD': '🇦🇺',
    'CAD': '🇨🇦',
    'CHF': '🇨🇭',
    'CNY': '🇨🇳',
    'INR': '🇮🇳',
    'SGD': '🇸🇬',
    'NZD': '🇳🇿',
    'MXN': '🇲🇽',
    'BRL': '🇧🇷',
    'ZAR': '🇿🇦',
    'KRW': '🇰🇷',
    'RUB': '🇷🇺',
    'TRY': '🇹🇷',
    'THB': '🇹🇭',
    'IDR': '🇮🇩',
    'MYR': '🇲🇾',
    'PHP': '🇵🇭',
    'VND': '🇻🇳',
    'BDT': '🇧🇩',
    'PKR': '🇵🇰',
    'EGP': '🇪🇬',
    'SAR': '🇸🇦',
    'AED': '🇦🇪',
    'PLN': '🇵🇱',
    'HUF': '🇭🇺',
    'CZK': '🇨🇿',
    'DKK': '🇩🇰',
    'SEK': '🇸🇪',
    'NOK': '🇳🇴',
    'ILS': '🇮🇱',
    'CLP': '🇨🇱',
  };

  final Map<String, String> currencyNames = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'AUD': 'Australian Dollar',
    'CAD': 'Canadian Dollar',
    'CHF': 'Swiss Franc',
    'CNY': 'Chinese Yuan',
    'INR': 'Indian Rupee',
    'SGD': 'Singapore Dollar',
    'NZD': 'New Zealand Dollar',
    'MXN': 'Mexican Peso',
    'BRL': 'Brazilian Real',
    'ZAR': 'South African Rand',
    'KRW': 'South Korean Won',
    'RUB': 'Russian Ruble',
    'TRY': 'Turkish Lira',
    'THB': 'Thai Baht',
    'IDR': 'Indonesian Rupiah',
    'MYR': 'Malaysian Ringgit',
    'PHP': 'Philippine Peso',
    'VND': 'Vietnamese Dong',
    'BDT': 'Bangladeshi Taka',
    'PKR': 'Pakistani Rupee',
    'EGP': 'Egyptian Pound',
    'SAR': 'Saudi Riyal',
    'AED': 'UAE Dirham',
    'PLN': 'Polish Złoty',
    'HUF': 'Hungarian Forint',
    'CZK': 'Czech Koruna',
    'DKK': 'Danish Krone',
    'SEK': 'Swedish Krona',
    'NOK': 'Norwegian Krone',
    'ILS': 'Israeli Shekel',
    'CLP': 'Chilean Peso',
  };

  List<ExchangeRate> exchangeData = [];
  List<CandleData> candleData = [];
  List<HeikinAshiData> heikinAshiData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPreferences();
    _loadCurrenciesFromDatabase();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      bullColor = Color(prefs.getInt('bullColor') ?? 0xFF00C853);
      bearColor = Color(prefs.getInt('bearColor') ?? 0xFFD50000);
    });
  }

  void _navigateAndClose(BuildContext context, Widget page) {
    Navigator.pop(context); // Close drawer
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bullColor', bullColor.value);
    await prefs.setInt('bearColor', bearColor.value);
  }

  Future<void> _loadCurrenciesFromDatabase() async {
    try {
      final loadedCurrencies = await CurrencyService.loadCurrencies();
      setState(() {
        _currencies = loadedCurrencies;
      });

      // Set default currencies with fallback logic
      if (_currencies.isNotEmpty) {
        // Get preferred from currency (USD) with fallback
        Currency preferredFrom = _currencies.firstWhere(
          (c) => c.code == 'USD',
          orElse: () => _currencies.first,
        );

        // Get preferred to currency (EUR) with fallback
        Currency preferredTo = _currencies.firstWhere(
          (c) => c.code == 'EUR',
          orElse:
              () => _currencies.length > 1 ? _currencies[1] : _currencies.first,
        );

        // Ensure from and to currencies are different
        if (preferredFrom.code == preferredTo.code && _currencies.length > 1) {
          final currentIndex = _currencies.indexWhere(
            (c) => c.code == preferredFrom.code,
          );
          final nextIndex = (currentIndex + 1) % _currencies.length;
          preferredTo = _currencies[nextIndex];
        }

        setState(() {
          fromCurrency = preferredFrom.code;
          toCurrency = preferredTo.code;
        });
      }

      _fetchExchangeRates();
    } catch (e) {
      print('Error loading currencies from database: $e');
      // Fallback to default behavior
      _fetchExchangeRates();
    }
  }

  // Get currency information from database or fallback
  Map<String, dynamic> _getCurrencyInfo(String code) {
    try {
      final currency = _currencies.firstWhere((c) => c.code == code);
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

  // Get available currencies for dropdowns (all currencies from database)
  List<String> get availableCurrencies {
    List<String> currencies;
    if (_currencies.isNotEmpty) {
      currencies = _currencies.map((c) => c.code).toList();
    } else {
      currencies = currencyFlags.keys.toList();
    }

    // Sort with favorites first
    return _sortCurrenciesWithFavorites(currencies);
  }

  List<String> _sortCurrenciesWithFavorites(List<String> currencies) {
    final settings = Provider.of<AppSettings>(context, listen: false);
    final favoriteCurrencies = settings.favoriteCurrencies;

    // Separate favorite and non-favorite currencies
    final favorites =
        currencies
            .where((currency) => favoriteCurrencies.contains(currency))
            .toList();
    final nonFavorites =
        currencies
            .where((currency) => !favoriteCurrencies.contains(currency))
            .toList();

    // Return favorites first, then non-favorites
    return [...favorites, ...nonFavorites];
  }

  bool _isFavoriteCurrency(String currencyCode) {
    final settings = Provider.of<AppSettings>(context, listen: false);
    return settings.isFavoriteCurrency(currencyCode);
  }

  Future<void> _fetchExchangeRates() async {
    setState(() => isLoading = true);
    try {
      // Use a free API for current rates
      final currentRateResponse = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/$fromCurrency'),
      );

      if (currentRateResponse.statusCode == 200) {
        final currentData = json.decode(currentRateResponse.body);
        if (currentData['result'] == 'success') {
          final rates = currentData['rates'] as Map<String, dynamic>;
          final rate = rates[toCurrency]?.toDouble() ?? 1.0;
          setState(() => _currentRate = rate);
        }
      }

      // Generate historical data based on current rate and timeframe
      _generateHistoricalData();
    } catch (e) {
      print('Error fetching rates: $e');
      // Fallback to dummy data if API fails
      _generateDummyData();
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _generateHistoricalData() {
    final now = DateTime.now();
    List<ExchangeRate> data = [];
    int pointCount = 100;

    switch (selectedTimeframe) {
      case '1D':
        pointCount = 24;
        break;
      case '1W':
        pointCount = 7;
        break;
      case '1M':
        pointCount = 30;
        break;
      case '3M':
        pointCount = 90;
        break;
      case '6M':
        pointCount = 180;
        break;
      case '1Y':
        pointCount = 365;
        break;
      case 'All':
        pointCount = 730;
        break;
    }

    double currentRate = _currentRate;
    for (int i = pointCount; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      // Add realistic market fluctuations
      double fluctuation =
          (i % 5 == 0) ? 0.02 * (i.isOdd ? 1 : -1) : 0.005 * (i.isOdd ? 1 : -1);
      if (selectedTimeframe == '1D') fluctuation *= 3;
      currentRate = currentRate * (1 + fluctuation);
      data.add(ExchangeRate(date, currentRate));
    }

    setState(() {
      exchangeData = data;
      if (data.length > 1) {
        _previousRate = data[data.length - 2].rate;
      }
      // Update converted amount when rate changes
      _convertedAmount = _conversionAmount * _currentRate;
    });

    // Generate candle data
    candleData = _generateCandleDataFromExchangeRates(data);
    heikinAshiData = _generateHeikinAshiData();
  }

  List<CandleData> _generateCandleDataFromExchangeRates(
    List<ExchangeRate> rates,
  ) {
    List<CandleData> candles = [];

    for (int i = 0; i < rates.length; i++) {
      final rate = rates[i];
      final open = rate.rate;
      final close = rate.rate * (1 + (Random().nextDouble() - 0.5) * 0.01);
      final high = max(open, close) * (1 + Random().nextDouble() * 0.005);
      final low = min(open, close) * (1 - Random().nextDouble() * 0.005);

      candles.add(CandleData(rate.date, open, high, low, close));
    }

    return candles;
  }

  List<CandleData> _generateCandleData(
    Map<String, dynamic> rates,
    bool isIntraday,
  ) {
    List<CandleData> candles = [];

    rates.forEach((date, values) {
      final dateTime = DateTime.parse(date);
      final open = double.parse(values['1. open']);
      final high = double.parse(values['2. high']);
      final low = double.parse(values['3. low']);
      final close = double.parse(values['4. close']);

      candles.add(CandleData(dateTime, open, high, low, close));
    });

    // Sort by date ascending
    candles.sort((a, b) => a.date.compareTo(b.date));

    return candles;
  }

  List<HeikinAshiData> _generateHeikinAshiData() {
    List<HeikinAshiData> haData = [];
    for (int i = 0; i < candleData.length; i++) {
      final prev = i == 0 ? null : haData[i - 1];
      final curr = candleData[i];
      final haClose = (curr.open + curr.high + curr.low + curr.close) / 4;
      final haOpen =
          prev == null
              ? (curr.open + curr.close) / 2
              : (prev.open + prev.close) / 2;
      final haHigh = [
        curr.high,
        haOpen,
        haClose,
      ].reduce((a, b) => a > b ? a : b);
      final haLow = [curr.low, haOpen, haClose].reduce((a, b) => a < b ? a : b);
      haData.add(HeikinAshiData(curr.date, haOpen, haHigh, haLow, haClose));
    }
    return haData;
  }

  // Fallback method if API fails
  void _generateDummyData() {
    final now = DateTime.now();
    List<ExchangeRate> data = [];
    int pointCount = 100;

    switch (selectedTimeframe) {
      case '1D':
        pointCount = 24;
        break;
      case '1W':
        pointCount = 7;
        break;
      case '1M':
        pointCount = 30;
        break;
      case '3M':
        pointCount = 90;
        break;
      case '6M':
        pointCount = 180;
        break;
      case '1Y':
        pointCount = 365;
        break;
      case 'All':
        pointCount = 730;
        break;
    }

    double currentRate = _currentRate;
    for (int i = pointCount; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      double fluctuation =
          (i % 5 == 0) ? 0.02 * (i.isOdd ? 1 : -1) : 0.005 * (i.isOdd ? 1 : -1);
      if (selectedTimeframe == '1D') fluctuation *= 3;
      currentRate = currentRate * (1 + fluctuation);
      data.add(ExchangeRate(date, currentRate));
    }

    setState(() {
      exchangeData = data;
      if (data.length > 1) {
        _previousRate = data[data.length - 2].rate;
      }
      // Update converted amount when rate changes
      _convertedAmount = _conversionAmount * _currentRate;
    });

    // Generate dummy candle data
    final dateMap = <DateTime, List<ExchangeRate>>{};
    for (var rate in exchangeData) {
      final date = DateTime(rate.date.year, rate.date.month, rate.date.day);
      dateMap.putIfAbsent(date, () => []).add(rate);
    }

    candleData =
        dateMap.entries.map((entry) {
          final rates = entry.value;
          if (rates.isEmpty) return CandleData(entry.key, 0, 0, 0, 0);
          final open = rates.first.rate;
          final close = rates.last.rate;
          final high = rates.map((r) => r.rate).reduce((a, b) => a > b ? a : b);
          final low = rates.map((r) => r.rate).reduce((a, b) => a < b ? a : b);
          return CandleData(entry.key, open, high, low, close);
        }).toList();

    heikinAshiData = _generateHeikinAshiData();
  }

  double get changePercent =>
      ((_currentRate - _previousRate) / _previousRate) * 100;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chartColor = changePercent >= 0 ? bullColor : bearColor;

    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        title: 'Trend Analysis',
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
                      const multi_currency.MultiCurrencyConverter(),
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
      body: Column(
        children: [
          // TabBar moved to body
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [theme.primaryColor, theme.primaryColorDark],
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  text: 'Chart',
                  icon: Icon(Icons.show_chart, color: Colors.white),
                ),
                Tab(
                  text: 'Analysis',
                  icon: Icon(Icons.insights, color: Colors.white),
                ),
              ],
              indicatorColor: Colors.white,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              unselectedLabelColor: Colors.white70,
            ),
          ),
          // Rest of the body content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChartTab(chartColor, theme),
                _buildAnalysisTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTab(Color chartColor, ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCurrencyHeader(chartColor),
          _buildTimeframeSelector(),
          _buildChartTypeSelector(),
          _buildChartSettings(),
          const SizedBox(height: 16),
          _buildChart(chartColor, theme),
          const SizedBox(height: 20),
          _buildConversionCard(),
        ],
      ),
    );
  }

  Widget _buildCurrencyHeader(Color chartColor) {
    final fromCurrencyInfo = _getCurrencyInfo(fromCurrency);
    final toCurrencyInfo = _getCurrencyInfo(toCurrency);
    final fromIsInactive = fromCurrencyInfo['status'] == 'inactive';
    final toIsInactive = toCurrencyInfo['status'] == 'inactive';
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(fromCurrencyInfo['flag']),
                  const SizedBox(width: 8),
                  Text(
                    '$fromCurrency/$toCurrency',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color:
                          (fromIsInactive || toIsInactive)
                              ? Theme.of(context).colorScheme.error
                              : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(toCurrencyInfo['flag']),
                  if (fromIsInactive || toIsInactive) ...[
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: chartColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      changePercent >= 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 16,
                      color: chartColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${changePercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: chartColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '1 $fromCurrency = ',
                style: TextStyle(
                  fontSize: 16,
                  color:
                      fromIsInactive
                          ? Theme.of(context).colorScheme.error
                          : Colors.grey,
                ),
              ),
              Text(
                _currentRate.toStringAsFixed(4),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color:
                      (fromIsInactive || toIsInactive)
                          ? Theme.of(context).colorScheme.error
                          : null,
                ),
              ),
              Text(
                ' $toCurrency',
                style: TextStyle(
                  fontSize: 16,
                  color:
                      toIsInactive
                          ? Theme.of(context).colorScheme.error
                          : Colors.grey,
                ),
              ),
            ],
          ),
          if (fromIsInactive || toIsInactive) ...[
            const SizedBox(height: 8),
            Text(
              'One or more currencies are temporarily blocked by the team',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Last updated: ${DateFormat.yMMMd().add_jm().format(DateTime.now())}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: timeframes.length,
        itemBuilder: (context, index) {
          final timeframe = timeframes[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(timeframe),
              selected: selectedTimeframe == timeframe,
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color:
                    selectedTimeframe == timeframe
                        ? Colors.white
                        : Theme.of(context).primaryColor,
              ),
              onSelected: (selected) {
                setState(() {
                  selectedTimeframe = timeframe;
                  _fetchExchangeRates();
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChartTypeSelector() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: chartTypes.length,
        itemBuilder: (context, index) {
          final type = chartTypes[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor:
                    selectedChartType == type
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                side: BorderSide(
                  color:
                      selectedChartType == type
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300]!,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => setState(() => selectedChartType = type),
              child: Text(
                type,
                style: TextStyle(
                  color:
                      selectedChartType == type
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChartSettings() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Chart Colors',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Column(
                children: [
                  const Text('Bull'),
                  ElevatedButton(
                    onPressed: () async {
                      final color = await _pickColor(bullColor);
                      if (color != null) setState(() => bullColor = color);
                      _savePreferences();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bullColor,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text(''),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  const Text('Bear'),
                  ElevatedButton(
                    onPressed: () async {
                      final color = await _pickColor(bearColor);
                      if (color != null) setState(() => bearColor = color);
                      _savePreferences();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bearColor,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text(''),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<Color?> _pickColor(Color initialColor) async {
    Color? pickedColor;
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Pick a Color'),
            content: SingleChildScrollView(
              child: BlockPicker(
                pickerColor: initialColor,
                onColorChanged: (color) => pickedColor = color,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
    );
    return pickedColor;
  }

  Widget _buildChart(Color chartColor, ThemeData theme) {
    if (selectedChartType == 'Candle' && candleData.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 400,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          'No candle data available for selected range.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 400,
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            zoomPanBehavior: ZoomPanBehavior(
              enablePinching: true,
              enableDoubleTapZooming: true,
              enablePanning: true,
              zoomMode: ZoomMode.xy,
            ),
            crosshairBehavior: CrosshairBehavior(
              enable: true,
              lineType: CrosshairLineType.both,
              lineColor: Colors.black54,
            ),
            tooltipBehavior: TooltipBehavior(
              enable: true,
              builder: (data, point, series, pointIndex, seriesIndex) {
                if (data is ExchangeRate) {
                  final change =
                      ((data.rate - _previousRate) / _previousRate) * 100;
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(DateFormat.yMMMd().format(data.date)),
                        Text('Rate: ${data.rate.toStringAsFixed(4)}'),
                        Text('Change: ${change.toStringAsFixed(2)}%'),
                      ],
                    ),
                  );
                } else if (data is CandleData) {
                  final change = ((data.close - data.open) / data.open) * 100;
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat.yMMMd().format(data.date)),
                        const SizedBox(height: 4),
                        Text('Open: ${data.open.toStringAsFixed(4)}'),
                        Text('High: ${data.high.toStringAsFixed(4)}'),
                        Text('Low: ${data.low.toStringAsFixed(4)}'),
                        Text('Close: ${data.close.toStringAsFixed(4)}'),
                        const SizedBox(height: 4),
                        Text(
                          'Change: ${change.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: change >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
            legend: Legend(isVisible: true, position: LegendPosition.bottom),
            title: ChartTitle(text: '$fromCurrency/$toCurrency Exchange Rate'),
            primaryXAxis: DateTimeAxis(
              dateFormat:
                  selectedTimeframe == '1D'
                      ? DateFormat.Hm()
                      : DateFormat.MMMd(),
              majorGridLines: const MajorGridLines(width: 0),
              axisLine: const AxisLine(width: 0),
            ),
            primaryYAxis: NumericAxis(
              numberFormat: NumberFormat.compactCurrency(symbol: ''),
              opposedPosition: true,
              majorGridLines: const MajorGridLines(
                width: 1,
                color: Color(0xFFF0F0F0),
              ),
              axisLine: const AxisLine(width: 0),
            ),
            series: _getChartSeries(chartColor),
          ),
        ),
      ),
    );
  }

  List<CartesianSeries<dynamic, dynamic>> _getChartSeries(Color chartColor) {
    List<CartesianSeries<dynamic, dynamic>> series = [];
    switch (selectedChartType) {
      case 'Heikin Ashi':
        if (heikinAshiData.isNotEmpty) {
          series.add(
            CandleSeries<HeikinAshiData, DateTime>(
              dataSource: heikinAshiData,
              xValueMapper: (data, _) => data.date,
              lowValueMapper: (data, _) => data.low,
              highValueMapper: (data, _) => data.high,
              openValueMapper: (data, _) => data.open,
              closeValueMapper: (data, _) => data.close,
              name: '$fromCurrency/$toCurrency (HA)',
              bearColor: bearColor,
              bullColor: bullColor,
            ),
          );
        }
        break;
      case 'Area':
        series.add(
          AreaSeries<ExchangeRate, DateTime>(
            dataSource: exchangeData,
            xValueMapper: (rate, _) => rate.date,
            yValueMapper: (rate, _) => rate.rate,
            name: '$fromCurrency/$toCurrency',
            gradient: LinearGradient(
              colors: [
                chartColor.withOpacity(0.5),
                chartColor.withOpacity(0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderColor: chartColor,
            borderWidth: 2,
          ),
        );
        break;
      case 'Candle':
        if (candleData.isNotEmpty) {
          series.add(
            CandleSeries<CandleData, DateTime>(
              dataSource: candleData,
              xValueMapper: (data, _) => data.date,
              lowValueMapper: (data, _) => data.low,
              highValueMapper: (data, _) => data.high,
              openValueMapper: (data, _) => data.open,
              closeValueMapper: (data, _) => data.close,
              name: '$fromCurrency/$toCurrency',
              bearColor: bearColor,
              bullColor: bullColor,
            ),
          );
        }
        break;
      default: // Line
        series.add(
          LineSeries<ExchangeRate, DateTime>(
            dataSource: exchangeData,
            xValueMapper: (rate, _) => rate.date,
            yValueMapper: (rate, _) => rate.rate,
            name: '$fromCurrency/$toCurrency',
            color: chartColor,
            width: 3,
            markerSettings: const MarkerSettings(
              isVisible: true,
              shape: DataMarkerType.circle,
              borderWidth: 2,
              borderColor: Colors.white,
            ),
          ),
        );
    }

    // Add moving averages
    series.add(_createMovingAverageSeries(20, const Color(0xFFFF9800)));
    series.add(_createMovingAverageSeries(50, const Color(0xFF9C27B0)));

    // Add trend line
    if (exchangeData.length > 1) {
      final first = exchangeData.first;
      final last = exchangeData.last;
      series.add(
        LineSeries<ExchangeRate, DateTime>(
          dataSource: [first, last],
          xValueMapper: (rate, _) => rate.date,
          yValueMapper: (rate, _) => rate.rate,
          name: 'Trend Line',
          color: Colors.blue,
          width: 1.5,
          dashArray: const [5, 5],
        ),
      );
    }

    return series;
  }

  LineSeries<ExchangeRate, DateTime> _createMovingAverageSeries(
    int period,
    Color color,
  ) {
    if (exchangeData.length < period) {
      return LineSeries<ExchangeRate, DateTime>(
        dataSource: [],
        xValueMapper: (rate, _) => rate.date,
        yValueMapper: (rate, _) => rate.rate,
      );
    }
    List<ExchangeRate> maData = [];
    for (int i = period - 1; i < exchangeData.length; i++) {
      double sum = 0;
      for (int j = 0; j < period; j++) {
        sum += exchangeData[i - j].rate;
      }
      maData.add(ExchangeRate(exchangeData[i].date, sum / period));
    }
    return LineSeries<ExchangeRate, DateTime>(
      dataSource: maData,
      xValueMapper: (rate, _) => rate.date,
      yValueMapper: (rate, _) => rate.rate,
      name: 'MA$period',
      color: color,
      width: 1.5,
      dashArray: const [5, 5],
    );
  }

  Widget _buildConversionCard() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Currency Converter',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(
                  Icons.swap_horiz,
                  color:
                      (_getCurrencyInfo(fromCurrency)['status'] == 'inactive' ||
                              _getCurrencyInfo(toCurrency)['status'] ==
                                  'inactive')
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  final fromIsInactive =
                      _getCurrencyInfo(fromCurrency)['status'] == 'inactive';
                  final toIsInactive =
                      _getCurrencyInfo(toCurrency)['status'] == 'inactive';

                  if (fromIsInactive || toIsInactive) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Cannot swap currencies when one or more are blocked',
                        ),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  setState(() {
                    final temp = fromCurrency;
                    fromCurrency = toCurrency;
                    toCurrency = temp;
                    // Update converted amount when currencies are swapped
                    _convertedAmount = _conversionAmount * _currentRate;
                    _fetchExchangeRates();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCurrencyDropdowns(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'From $fromCurrency',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixText: '${_getCurrencyInfo(fromCurrency)['symbol']} ',
                    prefixStyle: const TextStyle(fontSize: 18),
                  ),
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 18,
                    color:
                        _getCurrencyInfo(fromCurrency)['status'] == 'inactive'
                            ? Theme.of(context).colorScheme.error
                            : null,
                  ),
                  controller: TextEditingController(
                    text: _conversionAmount.toStringAsFixed(2),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final amount = double.tryParse(value) ?? 0;
                      setState(() {
                        _conversionAmount = amount;
                        _convertedAmount = amount * _currentRate;
                      });
                    } else {
                      setState(() {
                        _conversionAmount = 0;
                        _convertedAmount = 0;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'To $toCurrency',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixText: '${_getCurrencyInfo(toCurrency)['symbol']} ',
                    prefixStyle: const TextStyle(fontSize: 18),
                  ),
                  readOnly: true,
                  controller: TextEditingController(
                    text: _convertedAmount.toStringAsFixed(4),
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    color:
                        _getCurrencyInfo(toCurrency)['status'] == 'inactive'
                            ? Theme.of(context).colorScheme.error
                            : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final fromIsInactive =
                  _getCurrencyInfo(fromCurrency)['status'] == 'inactive';
              final toIsInactive =
                  _getCurrencyInfo(toCurrency)['status'] == 'inactive';

              if (fromIsInactive || toIsInactive) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Cannot refresh rates when currencies are blocked',
                    ),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 2),
                  ),
                );
                return;
              }

              _fetchExchangeRates();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  (_getCurrencyInfo(fromCurrency)['status'] == 'inactive' ||
                          _getCurrencyInfo(toCurrency)['status'] == 'inactive')
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Refresh Rates',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyDropdowns() {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          Expanded(
            child: _buildCurrencyDropdown(
              value: fromCurrency,
              onChanged: (value) {
                setState(() => fromCurrency = value!);
                _fetchExchangeRates();
              },
              label: 'From',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildCurrencyDropdown(
              value: toCurrency,
              onChanged: (value) {
                setState(() => toCurrency = value!);
                _fetchExchangeRates();
              },
              label: 'To',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
    required String label,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),
      items:
          availableCurrencies.map((currency) {
            final currencyInfo = _getCurrencyInfo(currency);
            final isInactive = currencyInfo['status'] == 'inactive';

            return DropdownMenuItem<String>(
              value: currency,
              enabled: !isInactive, // Disable inactive currencies
              child: Opacity(
                opacity: isInactive ? 0.6 : 1.0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(currencyInfo['flag']),
                    const SizedBox(width: 8),
                    if (_isFavoriteCurrency(currency)) ...[
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      currency,
                      style: TextStyle(
                        color:
                            isInactive
                                ? Theme.of(context).colorScheme.error
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
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(4),
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
              ),
            );
          }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          final currencyInfo = _getCurrencyInfo(newValue);
          if (currencyInfo['status'] == 'inactive') {
            // Show message when user tries to select inactive currency
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${currencyInfo['name']} is temporarily blocked by the team',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
            return; // Don't change the selection
          }
        }
        onChanged(newValue);
      },
      icon: const Icon(Icons.arrow_drop_down),
      isExpanded: true,
    );
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

  // Technical Analysis Methods
  double _calculateRSI() {
    if (exchangeData.length < 14) return 50.0;

    List<double> gains = [];
    List<double> losses = [];

    for (int i = 1; i < exchangeData.length; i++) {
      double change = exchangeData[i].rate - exchangeData[i - 1].rate;
      gains.add(change > 0 ? change : 0);
      losses.add(change < 0 ? -change : 0);
    }

    if (gains.length < 14) return 50.0;

    double avgGain = gains.take(14).reduce((a, b) => a + b) / 14;
    double avgLoss = losses.take(14).reduce((a, b) => a + b) / 14;

    if (avgLoss == 0) return 100.0;

    double rs = avgGain / avgLoss;
    return 100 - (100 / (1 + rs));
  }

  String _getRSIStatus(double rsi) {
    if (rsi > 70) return 'Overbought';
    if (rsi < 30) return 'Oversold';
    return 'Neutral';
  }

  Color _getRSIColor(double rsi) {
    if (rsi > 70) return Colors.red;
    if (rsi < 30) return Colors.green;
    return Colors.blue;
  }

  double _calculateVolatility() {
    if (exchangeData.length < 2) return 0.0;

    List<double> returns = [];
    for (int i = 1; i < exchangeData.length; i++) {
      double return_ =
          (exchangeData[i].rate - exchangeData[i - 1].rate) /
          exchangeData[i - 1].rate;
      returns.add(return_);
    }

    double mean = returns.reduce((a, b) => a + b) / returns.length;
    double variance =
        returns.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) /
        returns.length;
    double stdDev = sqrt(variance);

    return stdDev * 100; // Convert to percentage
  }

  String _getVolatilityStatus(double volatility) {
    if (volatility > 2.0) return 'High';
    if (volatility > 1.0) return 'Medium';
    return 'Low';
  }

  Color _getVolatilityColor(double volatility) {
    if (volatility > 2.0) return Colors.red;
    if (volatility > 1.0) return Colors.orange;
    return Colors.green;
  }

  String _getTrendStrength() {
    if (exchangeData.length < 2) return 'Weak';

    double firstRate = exchangeData.first.rate;
    double lastRate = exchangeData.last.rate;
    double change = ((lastRate - firstRate) / firstRate) * 100;

    if (change.abs() > 5) return 'Strong';
    if (change.abs() > 2) return 'Medium';
    return 'Weak';
  }

  String _getTrendStatus() {
    if (exchangeData.length < 2) return 'Neutral';

    double firstRate = exchangeData.first.rate;
    double lastRate = exchangeData.last.rate;
    double change = ((lastRate - firstRate) / firstRate) * 100;

    if (change > 2) return 'Bullish';
    if (change < -2) return 'Bearish';
    return 'Neutral';
  }

  int _calculateTrendStrength() {
    if (exchangeData.length < 2) return 30;

    double firstRate = exchangeData.first.rate;
    double lastRate = exchangeData.last.rate;
    double change = ((lastRate - firstRate) / firstRate) * 100;

    return (change.abs() * 10).round().clamp(0, 100);
  }

  Color _getTrendColor() {
    if (exchangeData.length < 2) return Colors.grey;

    double firstRate = exchangeData.first.rate;
    double lastRate = exchangeData.last.rate;
    double change = ((lastRate - firstRate) / firstRate) * 100;

    if (change > 2) return Colors.green;
    if (change < -2) return Colors.red;
    return Colors.blue;
  }

  List<ForecastData> _generateForecastData() {
    if (exchangeData.length < 2) {
      return [
        ForecastData('1D', _currentRate),
        ForecastData('1W', _currentRate),
        ForecastData('1M', _currentRate),
        ForecastData('3M', _currentRate),
      ];
    }

    // Calculate trend based on historical data
    double firstRate = exchangeData.first.rate;
    double lastRate = exchangeData.last.rate;
    double totalChange = ((lastRate - firstRate) / firstRate);
    int days = exchangeData.length;
    double dailyChange = totalChange / days;

    return [
      ForecastData('1D', _currentRate * (1 + dailyChange)),
      ForecastData('1W', _currentRate * (1 + dailyChange * 7)),
      ForecastData('1M', _currentRate * (1 + dailyChange * 30)),
      ForecastData('3M', _currentRate * (1 + dailyChange * 90)),
    ];
  }

  Widget _buildAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Technical Analysis',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[300]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Key Indicators',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildIndicatorRow(
                    'RSI (14)',
                    _calculateRSI().toStringAsFixed(1),
                    _getRSIStatus(_calculateRSI()),
                    _calculateRSI().round(),
                    _getRSIColor(_calculateRSI()),
                  ),
                  _buildIndicatorRow(
                    'Volatility',
                    '${_calculateVolatility().toStringAsFixed(1)}%',
                    _getVolatilityStatus(_calculateVolatility()),
                    _calculateVolatility().round(),
                    _getVolatilityColor(_calculateVolatility()),
                  ),
                  _buildIndicatorRow(
                    'Trend Strength',
                    _getTrendStrength(),
                    _getTrendStatus(),
                    _calculateTrendStrength(),
                    _getTrendColor(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Support & Resistance Levels',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.5),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            children: [
              _buildTableRow(
                'Resistance 3',
                _currentRate * 1.05,
                'Strong',
                Colors.red,
              ),
              _buildTableRow(
                'Resistance 2',
                _currentRate * 1.03,
                'Medium',
                Colors.orange,
              ),
              _buildTableRow(
                'Resistance 1',
                _currentRate * 1.01,
                'Weak',
                Colors.amber,
              ),
              _buildTableRow(
                'Current Rate',
                _currentRate,
                'Current',
                Theme.of(context).primaryColor,
              ),
              _buildTableRow(
                'Support 1',
                _currentRate * 0.99,
                'Weak',
                Colors.lightGreen,
              ),
              _buildTableRow(
                'Support 2',
                _currentRate * 0.97,
                'Medium',
                Colors.green,
              ),
              _buildTableRow(
                'Support 3',
                _currentRate * 0.95,
                'Strong',
                Colors.green[800]!,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Market Forecast',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                labelStyle: const TextStyle(fontSize: 12),
              ),
              primaryYAxis: NumericAxis(
                numberFormat: NumberFormat.compactCurrency(symbol: ''),
              ),
              series: <CartesianSeries>[
                LineSeries<ForecastData, String>(
                  dataSource: _generateForecastData(),
                  xValueMapper: (data, _) => data.period,
                  yValueMapper: (data, _) => data.rate,
                  name: 'Forecast',
                  color: Colors.blue,
                  width: 3,
                  markerSettings: const MarkerSettings(isVisible: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(
    String level,
    double rate,
    String strength,
    Color color,
  ) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(level),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(rate.toStringAsFixed(4)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            strength,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildIndicatorRow(
    String name,
    String value,
    String status,
    int level,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Chip(
                label: Text(value),
                backgroundColor: color.withOpacity(0.1),
                labelStyle: TextStyle(color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: level / 100,
            backgroundColor: Colors.grey[200],
            color: color,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 4),
          Text(status, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class ExchangeRate {
  final DateTime date;
  final double rate;
  ExchangeRate(this.date, this.rate);
}

class CandleData {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  CandleData(this.date, this.open, this.high, this.low, this.close);
}

class HeikinAshiData {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  HeikinAshiData(this.date, this.open, this.high, this.low, this.close);
}

class ForecastData {
  final String period;
  final double rate;
  ForecastData(this.period, this.rate);
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
