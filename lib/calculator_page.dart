import 'package:flutter/material.dart';
import 'dart:math';
import 'main.dart'; // For CustomAppBar, AppSettings, and navigation
import 'news_page.dart';
import 'multi_currency_page.dart';
import 'trend_chart.dart';
import 'rate_list_page.dart';
import 'setting_page.dart';
import 'world_clock.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'support_help_screen.dart';
import 'app_theme.dart';

// Unified currency management
class CurrencyUtils {
  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'INR': '₹',
    'PKR': '₨',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'SGD': 'S\$',
    'CNY': '¥',
    'CHF': 'Fr',
    'NZD': 'NZ\$',
    'MXN': '\$',
    'BRL': 'R\$',
    'RUB': '₽',
    'KRW': '₩',
    'TRY': '₺',
    'ZAR': 'R',
    'SEK': 'kr',
    'NOK': 'kr',
    'DKK': 'kr',
    'HKD': 'HK\$',
    'THB': '฿',
    'MYR': 'RM',
    'PHP': '₱',
    'IDR': 'Rp',
    'SAR': '﷼',
    'AED': 'د.إ',
    'PLN': 'zł',
    'HUF': 'Ft',
    'CZK': 'Kč',
    'ILS': '₪',
    'CLP': '\$',
    'BDT': '৳',
    'EGP': '£',
    'VND': '₫',
    'NGN': '₦',
    'UAH': '₴',
    'RON': 'lei',
    'PEN': 'S/',
    'COP': '\$',
    'ARS': '\$',
    'KZT': '₸',
    'QAR': '﷼',
    'KWD': 'د.ك',
    'OMR': '﷼',
    'BHD': '.د.ب',
    'JOD': 'د.ا',
    'LKR': 'Rs',
    'DZD': 'د.ج',
    'MAD': 'د.م.',
    'TWD': 'NT\$',
    'CRC': '₡',
    'UYU': '\$',
    'PYG': '₲',
    'BOB': 'Bs.',
    'GTQ': 'Q',
    'DOP': 'RD\$',
    'HNL': 'L',
    'NIO': 'C\$',
    'ETB': 'Br',
    'GHS': '₵',
    'KES': 'KSh',
    'UGX': 'USh',
    'TZS': 'TSh',
    'XAF': 'FCFA',
    'XOF': 'CFA',
    'NAD': 'N\$',
    'MZN': 'MT',
    'BWP': 'P',
    'MWK': 'MK',
    'ZMW': 'ZK',
    'ANG': 'ƒ',
    'TTD': 'TT\$',
    'BBD': 'Bds\$',
    'JMD': 'J\$',
    'BND': 'B\$',
    'FJD': 'FJ\$',
    'PGK': 'K',
    'SBD': 'SI\$',
    'VUV': 'VT',
    'WST': 'WS\$',
    'TOP': 'T\$',
    'KHR': '៛',
    'MMK': 'K',
    'LAK': '₭',
    'MVR': 'Rf',
    'NPR': '₨',
    'BTN': 'Nu.',
    'MNT': '₮',
    'AFN': '؋',
    'ALL': 'L',
    'AMD': '֏',
    'AZN': '₼',
    'BAM': 'KM',
    'BGN': 'лв',
    'GEL': '₾',
    'ISK': 'kr',
    'MDL': 'L',
    'MKD': 'ден',
    'RSD': 'дин',
    'TJS': 'ЅМ',
    'TMT': 'm',
    'UZS': 'so\'m',
  };

  static const Map<String, String> currencyNames = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'INR': 'Indian Rupee',
    'PKR': 'Pakistani Rupee',
    'CAD': 'Canadian Dollar',
    'AUD': 'Australian Dollar',
    'SGD': 'Singapore Dollar',
    'CNY': 'Chinese Yuan',
    'CHF': 'Swiss Franc',
    'NZD': 'New Zealand Dollar',
    'MXN': 'Mexican Peso',
    'BRL': 'Brazilian Real',
    'RUB': 'Russian Ruble',
    'KRW': 'South Korean Won',
    'TRY': 'Turkish Lira',
    'ZAR': 'South African Rand',
    'SEK': 'Swedish Krona',
    'NOK': 'Norwegian Krone',
    'DKK': 'Danish Krone',
    'HKD': 'Hong Kong Dollar',
    'THB': 'Thai Baht',
    'MYR': 'Malaysian Ringgit',
    'PHP': 'Philippine Peso',
    'IDR': 'Indonesian Rupiah',
    'SAR': 'Saudi Riyal',
    'AED': 'UAE Dirham',
    'PLN': 'Polish Złoty',
    'HUF': 'Hungarian Forint',
    'CZK': 'Czech Koruna',
    'ILS': 'Israeli Shekel',
    'CLP': 'Chilean Peso',
    'BDT': 'Bangladeshi Taka',
    'EGP': 'Egyptian Pound',
    'VND': 'Vietnamese Dong',
    'NGN': 'Nigerian Naira',
    'UAH': 'Ukrainian Hryvnia',
    'RON': 'Romanian Leu',
    'PEN': 'Peruvian Sol',
    'COP': 'Colombian Peso',
    'ARS': 'Argentine Peso',
    'KZT': 'Kazakhstani Tenge',
    'QAR': 'Qatari Riyal',
    'KWD': 'Kuwaiti Dinar',
    'OMR': 'Omani Rial',
    'BHD': 'Bahraini Dinar',
    'JOD': 'Jordanian Dinar',
    'LKR': 'Sri Lankan Rupee',
    'DZD': 'Algerian Dinar',
    'MAD': 'Moroccan Dirham',
    'TWD': 'New Taiwan Dollar',
    'CRC': 'Costa Rican Colón',
    'UYU': 'Uruguayan Peso',
    'PYG': 'Paraguayan Guarani',
    'BOB': 'Bolivian Boliviano',
    'GTQ': 'Guatemalan Quetzal',
    'DOP': 'Dominican Peso',
    'HNL': 'Honduran Lempira',
    'NIO': 'Nicaraguan Córdoba',
    'ETB': 'Ethiopian Birr',
    'GHS': 'Ghanaian Cedi',
    'KES': 'Kenyan Shilling',
    'UGX': 'Ugandan Shilling',
    'TZS': 'Tanzanian Shilling',
    'XAF': 'CFA Franc BEAC',
    'XOF': 'CFA Franc BCEAO',
    'NAD': 'Namibian Dollar',
    'MZN': 'Mozambican Metical',
    'BWP': 'Botswana Pula',
    'MWK': 'Malawian Kwacha',
    'ZMW': 'Zambian Kwacha',
    'ANG': 'Netherlands Antillean Guilder',
    'TTD': 'Trinidad & Tobago Dollar',
    'BBD': 'Barbadian Dollar',
    'JMD': 'Jamaican Dollar',
    'BND': 'Brunei Dollar',
    'FJD': 'Fijian Dollar',
    'PGK': 'Papua New Guinean Kina',
    'SBD': 'Solomon Islands Dollar',
    'VUV': 'Vanuatu Vatu',
    'WST': 'Samoan Tala',
    'TOP': 'Tongan Paʻanga',
    'KHR': 'Cambodian Riel',
    'MMK': 'Myanmar Kyat',
    'LAK': 'Laotian Kip',
    'MVR': 'Maldivian Rufiyaa',
    'NPR': 'Nepalese Rupee',
    'BTN': 'Bhutanese Ngultrum',
    'MNT': 'Mongolian Tögrög',
    'AFN': 'Afghan Afghani',
    'ALL': 'Albanian Lek',
    'AMD': 'Armenian Dram',
    'AZN': 'Azerbaijani Manat',
    'BAM': 'Bosnia-Herzegovina Convertible Mark',
    'BGN': 'Bulgarian Lev',
    'GEL': 'Georgian Lari',
    'ISK': 'Icelandic Króna',
    'MDL': 'Moldovan Leu',
    'MKD': 'Macedonian Denar',
    'RSD': 'Serbian Dinar',
    'TJS': 'Tajikistani Somoni',
    'TMT': 'Turkmenistani Manat',
    'UZS': 'Uzbekistani Som',
  };

  static const List<String> allCurrencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'INR',
    'PKR',
    'CAD',
    'AUD',
    'SGD',
    'CNY',
    'CHF',
    'NZD',
    'MXN',
    'BRL',
    'RUB',
    'KRW',
    'TRY',
    'ZAR',
    'SEK',
    'NOK',
    'DKK',
    'HKD',
    'THB',
    'MYR',
    'PHP',
    'IDR',
    'SAR',
    'AED',
    'PLN',
    'HUF',
    'CZK',
    'ILS',
    'CLP',
    'BDT',
    'EGP',
    'VND',
    'NGN',
    'UAH',
    'RON',
    'PEN',
    'COP',
    'ARS',
    'KZT',
    'QAR',
    'KWD',
    'OMR',
    'BHD',
    'JOD',
    'LKR',
    'DZD',
    'MAD',
    'TWD',
    'CRC',
    'UYU',
    'PYG',
    'BOB',
    'GTQ',
    'DOP',
    'HNL',
    'NIO',
    'ETB',
    'GHS',
    'KES',
    'UGX',
    'TZS',
    'XAF',
    'XOF',
    'NAD',
    'MZN',
    'BWP',
    'MWK',
    'ZMW',
    'ANG',
    'TTD',
    'BBD',
    'JMD',
    'BND',
    'FJD',
    'PGK',
    'SBD',
    'VUV',
    'WST',
    'TOP',
    'KHR',
    'MMK',
    'LAK',
    'MVR',
    'NPR',
    'BTN',
    'MNT',
    'AFN',
    'ALL',
    'AMD',
    'AZN',
    'BAM',
    'BGN',
    'GEL',
    'ISK',
    'MDL',
    'MKD',
    'RSD',
    'TJS',
    'TMT',
    'UZS',
  ];

  static double convertCurrency(double amount, String from, String to) {
    final rates = {
      'USD': 1.0,
      'EUR': 0.93,
      'GBP': 0.79,
      'JPY': 147.89,
      'INR': 82.91,
      'PKR': 281.21,
      'CAD': 1.36,
      'AUD': 1.52,
      'SGD': 1.35,
      'CNY': 7.25,
      'CHF': 0.88,
      'NZD': 1.67,
      'MXN': 17.23,
      'BRL': 4.95,
      'RUB': 92.45,
      'KRW': 1334.56,
      'TRY': 30.12,
      'ZAR': 18.67,
      'SEK': 10.45,
      'NOK': 10.78,
      'DKK': 6.89,
      'HKD': 7.82,
      'THB': 35.67,
      'MYR': 4.73,
      'PHP': 56.34,
      'IDR': 15678.90,
      'SAR': 3.75,
      'AED': 3.67,
      'PLN': 4.12,
      'HUF': 356.78,
      'CZK': 22.45,
      'ILS': 3.67,
      'CLP': 876.54,
      'BDT': 109.87,
      'EGP': 30.45,
      'VND': 24356.78,
      'NGN': 789.12,
      'UAH': 37.89,
      'RON': 4.56,
      'PEN': 3.78,
      'COP': 3956.78,
      'ARS': 876.54,
      'KZT': 456.78,
      'QAR': 3.64,
      'KWD': 0.31,
      'OMR': 0.38,
      'BHD': 0.38,
      'JOD': 0.71,
      'LKR': 323.45,
      'DZD': 134.56,
      'MAD': 10.23,
      'TWD': 31.45,
      'CRC': 534.67,
      'UYU': 38.90,
      'PYG': 7123.45,
      'BOB': 6.89,
      'GTQ': 7.82,
      'DOP': 58.90,
      'HNL': 24.67,
      'NIO': 36.78,
      'ETB': 56.34,
      'GHS': 12.34,
      'KES': 156.78,
      'UGX': 3789.12,
      'TZS': 2567.89,
      'XAF': 607.89,
      'XOF': 607.89,
      'NAD': 18.67,
      'MZN': 60.45,
      'BWP': 13.67,
      'MWK': 1689.12,
      'ZMW': 23.45,
      'ANG': 1.79,
      'TTD': 6.78,
      'BBD': 2.00,
      'JMD': 156.78,
      'BND': 1.35,
      'FJD': 2.23,
      'PGK': 3.67,
      'SBD': 8.45,
      'VUV': 123.45,
      'WST': 2.67,
      'TOP': 2.34,
      'KHR': 4056.78,
      'MMK': 2098.76,
      'LAK': 20789.12,
      'MVR': 15.45,
      'NPR': 132.45,
      'BTN': 82.91,
      'MNT': 3456.78,
      'AFN': 71.23,
      'ALL': 95.67,
      'AMD': 405.67,
      'AZN': 1.70,
      'BAM': 1.82,
      'BGN': 1.82,
      'GEL': 2.67,
      'ISK': 137.89,
      'MDL': 17.89,
      'MKD': 56.78,
      'RSD': 107.34,
      'TJS': 10.89,
      'TMT': 3.50,
      'UZS': 12345.67,
    };

    final fromRate = rates[from] ?? 1.0;
    final toRate = rates[to] ?? 1.0;
    return amount * (toRate / fromRate);
  }

  static String formatCurrency(double amount, String currency) {
    final symbol = currencySymbols[currency] ?? currency;
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}

class CalculatorsScreen extends StatefulWidget {
  const CalculatorsScreen({super.key});

  @override
  State<CalculatorsScreen> createState() => _CalculatorsScreenState();
}

class _CalculatorsScreenState extends State<CalculatorsScreen> {
  void _navigateAndClose(BuildContext context, Widget page) {
    Navigator.pop(context); // Close drawer
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
  }

  int _currentIndex = 0;
  final List<Widget> _calculators = [
    const TipCalculator(),
    const SplitBillCalculator(),
    const DiscountCalculator(),
    const TaxCalculator(),
    const SalaryConverter(),
    const LoanCalculator(),
    const UnitPriceCalculator(),
    const TravelBudgetEstimator(),
    const ExchangeProfitCalculator(),
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        title: 'Calculator',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _calculators[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Tip'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Split'),
          BottomNavigationBarItem(
            icon: Icon(Icons.discount),
            label: 'Discount',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Tax'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Salary'),
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: 'Loan'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Unit Price',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.flight), label: 'Travel'),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Exchange',
          ),
        ],
      ),
    );
  }
}

class CurrencySearchDropdown extends StatefulWidget {
  final String? selectedCurrency;
  final ValueChanged<String> onChanged;

  const CurrencySearchDropdown({
    super.key,
    required this.selectedCurrency,
    required this.onChanged,
  });

  @override
  State<CurrencySearchDropdown> createState() => _CurrencySearchDropdownState();
}

class _CurrencySearchDropdownState extends State<CurrencySearchDropdown> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredCurrencies = [];

  @override
  void initState() {
    super.initState();
    _filteredCurrencies = _getSortedCurrencies();
    _searchController.addListener(_filterCurrencies);
  }

  List<String> _getSortedCurrencies() {
    final settings = Provider.of<AppSettings>(context, listen: false);
    final favoriteCurrencies = settings.favoriteCurrencies;

    // Separate favorite and non-favorite currencies
    final favorites =
        CurrencyUtils.allCurrencies
            .where((currency) => favoriteCurrencies.contains(currency))
            .toList();
    final nonFavorites =
        CurrencyUtils.allCurrencies
            .where((currency) => !favoriteCurrencies.contains(currency))
            .toList();

    // Return favorites first, then non-favorites
    return [...favorites, ...nonFavorites];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCurrencies() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCurrencies = _getSortedCurrencies();
      } else {
        final allMatching =
            CurrencyUtils.allCurrencies
                .where(
                  (currency) =>
                      currency.toLowerCase().contains(query) ||
                      (CurrencyUtils.currencyNames[currency] ?? '')
                          .toLowerCase()
                          .contains(query),
                )
                .toList();

        // Maintain favorite order in search results
        final settings = Provider.of<AppSettings>(context, listen: false);
        final favoriteCurrencies = settings.favoriteCurrencies;

        final favorites =
            allMatching
                .where((currency) => favoriteCurrencies.contains(currency))
                .toList();
        final nonFavorites =
            allMatching
                .where((currency) => !favoriteCurrencies.contains(currency))
                .toList();

        _filteredCurrencies = [...favorites, ...nonFavorites];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Ensure selected currency is in filtered list
    final validSelectedCurrency =
        _filteredCurrencies.contains(widget.selectedCurrency)
            ? widget.selectedCurrency
            : _filteredCurrencies.isNotEmpty
            ? _filteredCurrencies.first
            : null;

    return Column(
      children: [
        // Search TextField
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search currency...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(height: 8),
        // Dropdown
        DropdownButtonFormField<String>(
          value: validSelectedCurrency,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items:
              _filteredCurrencies.map((String value) {
                final settings = Provider.of<AppSettings>(
                  context,
                  listen: false,
                );
                final isFavorite = settings.isFavoriteCurrency(value);

                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      if (isFavorite) ...[
                        Icon(
                          Icons.star,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(value),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          CurrencyUtils.currencyNames[value] ?? '',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          onChanged: (value) {
            if (value != null) {
              widget.onChanged(value);
            }
          },
          menuMaxHeight: 300,
        ),
      ],
    );
  }
}

class TipCalculator extends StatefulWidget {
  const TipCalculator({super.key});

  @override
  State<TipCalculator> createState() => _TipCalculatorState();
}

class _TipCalculatorState extends State<TipCalculator> {
  double _billAmount = 0;
  double _tipPercentage = 15;
  int _splitCount = 1;
  String _selectedCurrency = 'PKR';

  @override
  Widget build(BuildContext context) {
    final tipAmount = _billAmount * (_tipPercentage / 100);
    final totalAmount = _billAmount + tipAmount;
    final perPersonAmount = totalAmount / _splitCount;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CalculatorUtils.buildInputCard(
            title: 'Bill Amount',
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText:
                    '${CurrencyUtils.currencySymbols[_selectedCurrency]} ',
                border: const OutlineInputBorder(),
              ),
              onChanged:
                  (value) =>
                      setState(() => _billAmount = double.tryParse(value) ?? 0),
            ),
          ),
          CalculatorUtils.buildInputCard(
            title: 'Tip Percentage: ${_tipPercentage.round()}%',
            child: Slider(
              min: 5,
              max: 30,
              divisions: 25,
              value: _tipPercentage,
              onChanged: (value) => setState(() => _tipPercentage = value),
            ),
          ),
          CalculatorUtils.buildInputCard(
            title: 'Split Between',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed:
                      () => setState(
                        () =>
                            _splitCount = _splitCount > 1 ? _splitCount - 1 : 1,
                      ),
                ),
                Text('$_splitCount Person${_splitCount > 1 ? 's' : ''}'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => _splitCount++),
                ),
              ],
            ),
          ),
          CalculatorUtils.buildInputCard(
            title: 'Currency',
            child: CurrencySearchDropdown(
              selectedCurrency: _selectedCurrency,
              onChanged: (value) => setState(() => _selectedCurrency = value),
            ),
          ),
          const SizedBox(height: 20),
          CalculatorUtils.buildResultCard(
            title: 'Results',
            children: [
              CalculatorUtils.buildResultRow(
                'Tip Amount:',
                CurrencyUtils.formatCurrency(tipAmount, _selectedCurrency),
              ),
              CalculatorUtils.buildResultRow(
                'Total Amount:',
                CurrencyUtils.formatCurrency(totalAmount, _selectedCurrency),
              ),
              CalculatorUtils.buildResultRow(
                'Per Person:',
                CurrencyUtils.formatCurrency(
                  perPersonAmount,
                  _selectedCurrency,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SplitBillCalculator extends StatefulWidget {
  const SplitBillCalculator({super.key});

  @override
  State<SplitBillCalculator> createState() => _SplitBillCalculatorState();
}

class _SplitBillCalculatorState extends State<SplitBillCalculator> {
  double _totalAmount = 0;
  int _splitCount = 2;
  String _selectedCurrency = 'PKR';

  @override
  Widget build(BuildContext context) {
    final perPersonAmount = _totalAmount / _splitCount;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CalculatorUtils.buildInputCard(
            title: 'Total Bill Amount',
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText:
                    '${CurrencyUtils.currencySymbols[_selectedCurrency]} ',
                border: const OutlineInputBorder(),
              ),
              onChanged:
                  (value) => setState(
                    () => _totalAmount = double.tryParse(value) ?? 0,
                  ),
            ),
          ),
          CalculatorUtils.buildInputCard(
            title: 'Split Between',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed:
                      () => setState(
                        () =>
                            _splitCount = _splitCount > 1 ? _splitCount - 1 : 1,
                      ),
                ),
                Text('$_splitCount Person${_splitCount > 1 ? 's' : ''}'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => _splitCount++),
                ),
              ],
            ),
          ),
          CalculatorUtils.buildInputCard(
            title: 'Currency',
            child: CurrencySearchDropdown(
              selectedCurrency: _selectedCurrency,
              onChanged: (value) => setState(() => _selectedCurrency = value),
            ),
          ),
          const SizedBox(height: 20),
          CalculatorUtils.buildResultCard(
            title: 'Split Results',
            children: [
              CalculatorUtils.buildResultRow(
                'Total Amount:',
                CurrencyUtils.formatCurrency(_totalAmount, _selectedCurrency),
              ),
              CalculatorUtils.buildResultRow(
                'Per Person:',
                CurrencyUtils.formatCurrency(
                  perPersonAmount,
                  _selectedCurrency,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DiscountCalculator extends StatefulWidget {
  const DiscountCalculator({super.key});

  @override
  State<DiscountCalculator> createState() => _DiscountCalculatorState();
}

class _DiscountCalculatorState extends State<DiscountCalculator> {
  double _originalPrice = 0;
  double _discountPercentage = 10;
  String _selectedCurrency = 'PKR';

  @override
  Widget build(BuildContext context) {
    final discountAmount = _originalPrice * (_discountPercentage / 100);
    final finalPrice = _originalPrice - discountAmount;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CalculatorUtils.buildInputCard(
            title: 'Original Price',
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText:
                    '${CurrencyUtils.currencySymbols[_selectedCurrency]} ',
                border: const OutlineInputBorder(),
              ),
              onChanged:
                  (value) => setState(
                    () => _originalPrice = double.tryParse(value) ?? 0,
                  ),
            ),
          ),
          CalculatorUtils.buildInputCard(
            title: 'Discount Percentage: ${_discountPercentage.round()}%',
            child: Slider(
              min: 0,
              max: 100,
              divisions: 100,
              value: _discountPercentage,
              onChanged: (value) => setState(() => _discountPercentage = value),
            ),
          ),
          CalculatorUtils.buildInputCard(
            title: 'Currency',
            child: CurrencySearchDropdown(
              selectedCurrency: _selectedCurrency,
              onChanged: (value) => setState(() => _selectedCurrency = value),
            ),
          ),
          const SizedBox(height: 20),
          CalculatorUtils.buildResultCard(
            title: 'Discount Results',
            children: [
              CalculatorUtils.buildResultRow(
                'Original Price:',
                CurrencyUtils.formatCurrency(_originalPrice, _selectedCurrency),
              ),
              CalculatorUtils.buildResultRow(
                'Discount Amount:',
                CurrencyUtils.formatCurrency(discountAmount, _selectedCurrency),
              ),
              CalculatorUtils.buildResultRow(
                'Final Price:',
                CurrencyUtils.formatCurrency(finalPrice, _selectedCurrency),
              ),
              CalculatorUtils.buildResultRow(
                'You Save:',
                CurrencyUtils.formatCurrency(discountAmount, _selectedCurrency),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TaxCalculator extends StatefulWidget {
  const TaxCalculator({super.key});

  @override
  State<TaxCalculator> createState() => _TaxCalculatorState();
}

class _TaxCalculatorState extends State<TaxCalculator> {
  double _subtotal = 0;
  double _taxRate = 8.5;
  String _selectedCurrency = 'PKR';

  @override
  Widget build(BuildContext context) {
    final taxAmount = _subtotal * (_taxRate / 100);
    final totalAmount = _subtotal + taxAmount;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CalculatorUtils.buildInputCard(
            title: 'Subtotal',
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText:
                    '${CurrencyUtils.currencySymbols[_selectedCurrency]} ',
                border: const OutlineInputBorder(),
              ),
              onChanged:
                  (value) =>
                      setState(() => _subtotal = double.tryParse(value) ?? 0),
            ),
          ),
          CalculatorUtils.buildInputCard(
            title: 'Tax Rate: ${_taxRate.toStringAsFixed(1)}%',
            child: Slider(
              min: 0,
              max: 25,
              divisions: 250,
              value: _taxRate,
              onChanged: (value) => setState(() => _taxRate = value),
            ),
          ),
          CalculatorUtils.buildInputCard(
            title: 'Currency',
            child: CurrencySearchDropdown(
              selectedCurrency: _selectedCurrency,
              onChanged: (value) => setState(() => _selectedCurrency = value),
            ),
          ),
          const SizedBox(height: 20),
          CalculatorUtils.buildResultCard(
            title: 'Tax Results',
            children: [
              CalculatorUtils.buildResultRow(
                'Subtotal:',
                CurrencyUtils.formatCurrency(_subtotal, _selectedCurrency),
              ),
              CalculatorUtils.buildResultRow(
                'Tax Amount:',
                CurrencyUtils.formatCurrency(taxAmount, _selectedCurrency),
              ),
              CalculatorUtils.buildResultRow(
                'Total Amount:',
                CurrencyUtils.formatCurrency(totalAmount, _selectedCurrency),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SalaryConverter extends StatefulWidget {
  const SalaryConverter({super.key});

  @override
  State<SalaryConverter> createState() => _SalaryConverterState();
}

class _SalaryConverterState extends State<SalaryConverter> {
  double _salary = 0;
  String _fromCurrency = 'PKR';
  String _toCurrency = 'USD';

  @override
  Widget build(BuildContext context) {
    final convertedSalary = CurrencyUtils.convertCurrency(
      _salary,
      _fromCurrency,
      _toCurrency,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CalculatorUtils.buildInputCard(
            title: 'Salary Amount',
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '${CurrencyUtils.currencySymbols[_fromCurrency]} ',
                border: const OutlineInputBorder(),
              ),
              onChanged:
                  (value) =>
                      setState(() => _salary = double.tryParse(value) ?? 0),
            ),
          ),
          CalculatorUtils.buildInputCard(
            title: 'From Currency',
            child: CurrencySearchDropdown(
              selectedCurrency: _fromCurrency,
              onChanged: (value) => setState(() => _fromCurrency = value),
            ),
          ),
          CalculatorUtils.buildInputCard(
            title: 'To Currency',
            child: CurrencySearchDropdown(
              selectedCurrency: _toCurrency,
              onChanged: (value) => setState(() => _toCurrency = value),
            ),
          ),
          const SizedBox(height: 20),
          CalculatorUtils.buildResultCard(
            title: 'Salary Conversion',
            children: [
              CalculatorUtils.buildResultRow(
                'Original Salary:',
                CurrencyUtils.formatCurrency(_salary, _fromCurrency),
              ),
              CalculatorUtils.buildResultRow(
                'Converted Salary:',
                CurrencyUtils.formatCurrency(convertedSalary, _toCurrency),
              ),
              CalculatorUtils.buildResultRow(
                'Monthly:',
                CurrencyUtils.formatCurrency(convertedSalary / 12, _toCurrency),
              ),
              CalculatorUtils.buildResultRow(
                'Weekly:',
                CurrencyUtils.formatCurrency(convertedSalary / 52, _toCurrency),
              ),
              CalculatorUtils.buildResultRow(
                'Hourly (40h/week):',
                CurrencyUtils.formatCurrency(
                  convertedSalary / 52 / 40,
                  _toCurrency,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LoanCalculator extends StatefulWidget {
  const LoanCalculator({super.key});

  @override
  State<LoanCalculator> createState() => _LoanCalculatorState();
}

class _LoanCalculatorState extends State<LoanCalculator> {
  double _loanAmount = 0;
  double _interestRate = 5.0;
  int _loanTerm = 30;
  String _selectedCurrency = 'PKR';

  @override
  Widget build(BuildContext context) {
    final monthlyRate = _interestRate / 100 / 12;
    final numberOfPayments = _loanTerm * 12;
    final monthlyPayment =
        _loanAmount *
        (monthlyRate * pow(1 + monthlyRate, numberOfPayments)) /
        (pow(1 + monthlyRate, numberOfPayments) - 1);
    final totalPayment = monthlyPayment * numberOfPayments;
    final totalInterest = totalPayment - _loanAmount;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CalculatorUtils.buildInputCard(
            title: 'Loan Amount',
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText:
                    '${CurrencyUtils.currencySymbols[_selectedCurrency]} ',
                border: const OutlineInputBorder(),
              ),
              onChanged:
                  (value) =>
                      setState(() => _loanAmount = double.tryParse(value) ?? 0),
            ),
          ),
          CalculatorUtils.buildInputCard(
            title: 'Interest Rate: ${_interestRate.toStringAsFixed(1)}%',
            child: Slider(
              min: 1,
              max: 20,
              divisions: 190,
              value: _interestRate,
              onChanged: (value) => setState(() => _interestRate = value),
            ),
          ),
          CalculatorUtils.buildInputCard(
            title: 'Loan Term: $_loanTerm years',
            child: Slider(
              min: 1,
              max: 50,
              divisions: 49,
              value: _loanTerm.toDouble(),
              onChanged: (value) => setState(() => _loanTerm = value.round()),
            ),
          ),
          CalculatorUtils.buildInputCard(
            title: 'Currency',
            child: CurrencySearchDropdown(
              selectedCurrency: _selectedCurrency,
              onChanged: (value) => setState(() => _selectedCurrency = value),
            ),
          ),
          const SizedBox(height: 20),
          CalculatorUtils.buildResultCard(
            title: 'Loan Results',
            children: [
              CalculatorUtils.buildResultRow(
                'Monthly Payment:',
                CurrencyUtils.formatCurrency(monthlyPayment, _selectedCurrency),
              ),
              CalculatorUtils.buildResultRow(
                'Total Interest:',
                CurrencyUtils.formatCurrency(totalInterest, _selectedCurrency),
              ),
              CalculatorUtils.buildResultRow(
                'Total Payment:',
                CurrencyUtils.formatCurrency(totalPayment, _selectedCurrency),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UnitPriceCalculator extends StatefulWidget {
  const UnitPriceCalculator({super.key});

  @override
  State<UnitPriceCalculator> createState() => _UnitPriceCalculatorState();
}

class _UnitPriceCalculatorState extends State<UnitPriceCalculator> {
  double _price = 0;
  double _quantity = 1;
  String _unit = 'piece';
  String _selectedCurrency = 'PKR';

  @override
  Widget build(BuildContext context) {
    final unitPrice = _price / _quantity;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CalculatorUtils.buildInputCard(
            title: 'Total Price',
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText:
                    '${CurrencyUtils.currencySymbols[_selectedCurrency]} ',
                border: const OutlineInputBorder(),
              ),
              onChanged:
                  (value) =>
                      setState(() => _price = double.tryParse(value) ?? 0),
            ),
          ),
          CalculatorUtils.buildInputCard(
            title: 'Quantity',
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged:
                  (value) =>
                      setState(() => _quantity = double.tryParse(value) ?? 1),
            ),
          ),
          CalculatorUtils.buildInputCard(
            title: 'Unit',
            child: DropdownButtonFormField<String>(
              value: _unit,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items:
                  ['piece', 'kg', 'liter', 'meter', 'hour', 'pack', 'box'].map((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
              onChanged: (value) => setState(() => _unit = value!),
            ),
          ),
          CalculatorUtils.buildInputCard(
            title: 'Currency',
            child: CurrencySearchDropdown(
              selectedCurrency: _selectedCurrency,
              onChanged: (value) => setState(() => _selectedCurrency = value),
            ),
          ),
          const SizedBox(height: 20),
          CalculatorUtils.buildResultCard(
            title: 'Unit Price Results',
            children: [
              CalculatorUtils.buildResultRow(
                'Total Price:',
                CurrencyUtils.formatCurrency(_price, _selectedCurrency),
              ),
              CalculatorUtils.buildResultRow('Quantity:', '$_quantity $_unit'),
              CalculatorUtils.buildResultRow(
                'Unit Price:',
                '${CurrencyUtils.formatCurrency(unitPrice, _selectedCurrency)} per $_unit',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TravelBudgetEstimator extends StatefulWidget {
  const TravelBudgetEstimator({super.key});

  @override
  State<TravelBudgetEstimator> createState() => _TravelBudgetEstimatorState();
}

class _TravelBudgetEstimatorState extends State<TravelBudgetEstimator> {
  double _dailyBudget = 100;
  int _tripDays = 7;
  String _selectedCurrency = 'PKR';

  @override
  Widget build(BuildContext context) {
    final totalBudget = _dailyBudget * _tripDays;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CalculatorUtils.buildInputCard(
            title:
                'Daily Budget: ${CurrencyUtils.formatCurrency(_dailyBudget, _selectedCurrency)}',
            child: Slider(
              min: 20,
              max: 500,
              divisions: 480,
              value: _dailyBudget,
              onChanged: (value) => setState(() => _dailyBudget = value),
            ),
          ),
          CalculatorUtils.buildInputCard(
            title: 'Trip Duration: $_tripDays days',
            child: Slider(
              min: 1,
              max: 90,
              divisions: 89,
              value: _tripDays.toDouble(),
              onChanged: (value) => setState(() => _tripDays = value.round()),
            ),
          ),
          CalculatorUtils.buildInputCard(
            title: 'Currency',
            child: CurrencySearchDropdown(
              selectedCurrency: _selectedCurrency,
              onChanged: (value) => setState(() => _selectedCurrency = value),
            ),
          ),
          const SizedBox(height: 20),
          CalculatorUtils.buildResultCard(
            title: 'Travel Budget',
            children: [
              CalculatorUtils.buildResultRow(
                'Daily Budget:',
                CurrencyUtils.formatCurrency(_dailyBudget, _selectedCurrency),
              ),
              CalculatorUtils.buildResultRow(
                'Trip Duration:',
                '$_tripDays days',
              ),
              CalculatorUtils.buildResultRow(
                'Total Budget:',
                CurrencyUtils.formatCurrency(totalBudget, _selectedCurrency),
              ),
              CalculatorUtils.buildResultRow(
                'Weekly Budget:',
                CurrencyUtils.formatCurrency(
                  _dailyBudget * 7,
                  _selectedCurrency,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ExchangeProfitCalculator extends StatefulWidget {
  const ExchangeProfitCalculator({super.key});

  @override
  State<ExchangeProfitCalculator> createState() =>
      _ExchangeProfitCalculatorState();
}

class _ExchangeProfitCalculatorState extends State<ExchangeProfitCalculator> {
  double _buyAmount = 0;
  double _buyRate = 1.0;
  double _sellRate = 1.1;
  String _selectedCurrency = 'PKR';

  @override
  Widget build(BuildContext context) {
    final buyValue = _buyAmount * _buyRate;
    final sellValue = _buyAmount * _sellRate;
    final profit = sellValue - buyValue;
    final profitPercentage = (profit / buyValue) * 100;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CalculatorUtils.buildInputCard(
            title: 'Amount to Exchange',
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText:
                    '${CurrencyUtils.currencySymbols[_selectedCurrency]} ',
                border: const OutlineInputBorder(),
              ),
              onChanged:
                  (value) =>
                      setState(() => _buyAmount = double.tryParse(value) ?? 0),
            ),
          ),
          CalculatorUtils.buildInputCard(
            title: 'Buy Rate: ${_buyRate.toStringAsFixed(4)}',
            child: Slider(
              min: 0.5,
              max: 2.0,
              divisions: 150,
              value: _buyRate,
              onChanged: (value) => setState(() => _buyRate = value),
            ),
          ),
          CalculatorUtils.buildInputCard(
            title: 'Sell Rate: ${_sellRate.toStringAsFixed(4)}',
            child: Slider(
              min: 0.5,
              max: 2.0,
              divisions: 150,
              value: _sellRate,
              onChanged: (value) => setState(() => _sellRate = value),
            ),
          ),
          CalculatorUtils.buildInputCard(
            title: 'Currency',
            child: CurrencySearchDropdown(
              selectedCurrency: _selectedCurrency,
              onChanged: (value) => setState(() => _selectedCurrency = value),
            ),
          ),
          const SizedBox(height: 20),
          CalculatorUtils.buildResultCard(
            title: 'Exchange Profit Results',
            children: [
              CalculatorUtils.buildResultRow(
                'Buy Value:',
                CurrencyUtils.formatCurrency(buyValue, _selectedCurrency),
              ),
              CalculatorUtils.buildResultRow(
                'Sell Value:',
                CurrencyUtils.formatCurrency(sellValue, _selectedCurrency),
              ),
              CalculatorUtils.buildResultRow(
                'Profit/Loss:',
                CurrencyUtils.formatCurrency(profit, _selectedCurrency),
              ),
              CalculatorUtils.buildResultRow(
                'Profit %:',
                '${profitPercentage.toStringAsFixed(2)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper Widgets
class CalculatorUtils {
  static Widget buildInputCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  static Widget buildResultCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Divider(thickness: 1.5, color: Colors.blue),
            ...children,
          ],
        ),
      ),
    );
  }

  static Widget buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
