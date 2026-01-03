import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:math_expressions/math_expressions.dart' as math_expressions;
import 'dart:async';
import 'package:lottie/lottie.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'currency_widget.dart';
import 'models/currency.dart';
import 'services/connectivity_service.dart';
import 'services/app_version_service.dart';
import 'api_service.dart';
import 'news_page.dart';
import 'trend_chart.dart';
import 'world_clock.dart';
import 'multi_currency_page.dart' as multi_currency;
import 'rate_list_page.dart';
import 'calculator_page.dart';
import 'task_screen.dart';
import 'support_help_screen.dart';
import 'setting_page.dart';

class CurrencyConverterScreen extends StatefulWidget {
  final bool showSuccess;
  const CurrencyConverterScreen({super.key, this.showSuccess = false});

  @override
  _CurrencyConverterScreenState createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Currency> currencies = [];
  Currency? fromCurrency;
  Currency? toCurrency;
  double amount = 1.0;
  double convertedAmount = 0.0;
  TextEditingController amountController = TextEditingController();
  Map<String, double> rates = {};
  bool isLoading = true;
  String lastUpdated = '';
  String? errorMessage;
  final ScrollController _fromScrollController = ScrollController();
  final ScrollController _toScrollController = ScrollController();
  final bool _hasAnimatedScroll = false;
  Timer? _fromAutoScrollTimer;
  Timer? _toAutoScrollTimer;
  bool _userScrollingFrom = false;
  bool _userScrollingTo = false;
  bool _showSuccess = false;
  Timer? _autoUpdateTimer;
  bool _lastAutoUpdateSetting = true;

  // Tutorial keys
  final GlobalKey _swapKey = GlobalKey();
  final GlobalKey _fromCurrencyKey = GlobalKey();
  final GlobalKey _toCurrencyKey = GlobalKey();
  final GlobalKey _amountKey = GlobalKey();
  final GlobalKey _calculatorKey = GlobalKey();
  final GlobalKey _hamburgerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _showSuccess = widget.showSuccess;
    print(
      'CurrencyConverterScreen initState: showSuccess = $_showSuccess, widget.showSuccess = ${widget.showSuccess}',
    );
    if (_showSuccess) {
      print('Showing success animation for 5 seconds');
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _showSuccess = false);
          print('Success animation hidden');
        }
      });
    }
    initializeCurrencies();
    amountController.text = amount.toStringAsFixed(2);

    // Add scroll listeners to detect manual scrolling
    _fromScrollController.addListener(_onFromScrollChanged);
    _toScrollController.addListener(_onToScrollChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAutoUpdate();

      // Check connectivity after UI is built
      _checkConnectivityOnStart();

      // Start auto-scroll with a delay to ensure UI is ready
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _startAutoScroll(_fromScrollController, isFrom: true);
          _startAutoScroll(_toScrollController, isFrom: false);
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appSettings = Provider.of<AppSettings>(context);
    if (appSettings.autoUpdateRates != _lastAutoUpdateSetting) {
      _lastAutoUpdateSetting = appSettings.autoUpdateRates;
      _setupAutoUpdate();
    }

    // Check offline mode
    if (appSettings.offlineMode) {
      _handleOfflineMode();
    }

    if (widget.showSuccess) {
      // Check if user is new (first time) and show tutorial
      _checkAndShowTutorial();
    }
  }

  // Handle offline mode
  void _handleOfflineMode() {
    setState(() {
      isLoading = false;
      // Use cached rates or default rates for offline mode
      if (rates.isEmpty) {
        // Set some default rates for offline mode
        rates = {
          'USD': 1.0,
          'EUR': 0.85,
          'GBP': 0.73,
          'JPY': 110.0,
          'INR': 75.0,
          'PKR': 160.0,
          'CAD': 1.25,
          'AUD': 1.35,
          'CHF': 0.92,
          'CNY': 6.45,
        };
      }
      lastUpdated = 'Offline Mode - Last cached rates';
    });
    convertCurrency();
  }

  Future<void> _checkAndShowTutorial() async {
    // Add a small delay to ensure the success animation completes
    await Future.delayed(const Duration(seconds: 6));

    if (!mounted) return;

    // Check if this is the first time user (you can use SharedPreferences or Firebase)
    // For now, we'll show tutorial for new users
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;

    if (isFirstTime) {
      // Mark as not first time
      await prefs.setBool('isFirstTime', false);

      // Show tutorial - only include calculator feature if it's enabled
      final appSettings = Provider.of<AppSettings>(context, listen: false);
      final features = <String>[
        'hamburger_feature',
        'amount_feature',
        'from_currency_feature',
        'swap_feature',
        'to_currency_feature',
      ];

      // Only add calculator feature if it's enabled
      if (appSettings.showCalculator) {
        features.add('calculator_feature');
      }

      FeatureDiscovery.discoverFeatures(context, features);
    }
  }

  void _startAutoScroll(ScrollController controller, {required bool isFrom}) {
    // Cancel any existing timer first
    if (isFrom) {
      _fromAutoScrollTimer?.cancel();
    } else {
      _toAutoScrollTimer?.cancel();
    }

    // Balanced speed for smooth movement
    const double scrollStep = 1.2; // Slightly faster step
    const int targetFps = 15; // Moderate FPS for smooth animation
    const Duration scrollDuration = Duration(milliseconds: 1000 ~/ targetFps);

    Timer? timer;
    timer = Timer.periodic(scrollDuration, (_) {
      // Check if user is scrolling
      if ((isFrom && _userScrollingFrom) || (!isFrom && _userScrollingTo)) {
        return;
      }

      // Check if controller is still valid
      if (!controller.hasClients || !mounted) {
        timer?.cancel();
        return;
      }

      try {
        final maxScroll = controller.position.maxScrollExtent;
        if (maxScroll <= 0) return; // No content to scroll

        final current = controller.offset;
        double next = current + scrollStep;

        // Smooth loop back to start
        if (next >= maxScroll) {
          next = 0;
        }

        // Use jumpTo for more reliable movement with faster speed
        controller.jumpTo(next);
      } catch (e) {
        print('Auto-scroll error: $e');
        timer?.cancel();
      }
    });

    if (isFrom) {
      _fromAutoScrollTimer = timer;
    } else {
      _toAutoScrollTimer = timer;
    }
  }

  void _pauseAutoScroll(bool isFrom) {
    if (isFrom) {
      _userScrollingFrom = true;
      _fromAutoScrollTimer?.cancel();
    } else {
      _userScrollingTo = true;
      _toAutoScrollTimer?.cancel();
    }
  }

  void _resumeAutoScroll(bool isFrom) {
    // Shorter delay for more responsive resumption
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        if (isFrom) {
          _userScrollingFrom = false;
          _startAutoScroll(_fromScrollController, isFrom: true);
        } else {
          _userScrollingTo = false;
          _startAutoScroll(_toScrollController, isFrom: false);
        }
      }
    });
  }

  // Scroll listener methods for better detection
  void _onFromScrollChanged() {
    if (!mounted) return;

    if (_fromScrollController.position.isScrollingNotifier.value) {
      if (!_userScrollingFrom) {
        _pauseAutoScroll(true);
      }
    } else {
      if (_userScrollingFrom) {
        _resumeAutoScroll(true);
      }
    }
  }

  void _onToScrollChanged() {
    if (!mounted) return;

    if (_toScrollController.position.isScrollingNotifier.value) {
      if (!_userScrollingTo) {
        _pauseAutoScroll(false);
      }
    } else {
      if (_userScrollingTo) {
        _resumeAutoScroll(false);
      }
    }
  }

  List<Currency> _sortCurrenciesWithFavorites(List<Currency> currencies) {
    final settings = Provider.of<AppSettings>(context, listen: false);
    final favoriteCurrencies = settings.favoriteCurrencies;

    // Separate currencies by status and favorites
    final favoriteActive =
        currencies
            .where(
              (currency) =>
                  favoriteCurrencies.contains(currency.code) &&
                  currency.status == 'active',
            )
            .toList();

    final favoriteInactive =
        currencies
            .where(
              (currency) =>
                  favoriteCurrencies.contains(currency.code) &&
                  currency.status == 'inactive',
            )
            .toList();

    final nonFavoriteActive =
        currencies
            .where(
              (currency) =>
                  !favoriteCurrencies.contains(currency.code) &&
                  currency.status == 'active',
            )
            .toList();

    final nonFavoriteInactive =
        currencies
            .where(
              (currency) =>
                  !favoriteCurrencies.contains(currency.code) &&
                  currency.status == 'inactive',
            )
            .toList();

    // Return: favorite active, non-favorite active, favorite inactive, non-favorite inactive
    return [
      ...favoriteActive,
      ...nonFavoriteActive,
      ...favoriteInactive,
      ...nonFavoriteInactive,
    ];
  }

  bool _isFavoriteCurrency(String currencyCode) {
    final settings = Provider.of<AppSettings>(context, listen: false);
    return settings.isFavoriteCurrency(currencyCode);
  }

  Future<void> initializeCurrencies() async {
    try {
      // Load all currencies from Firebase (both active and inactive)
      final loadedCurrencies = _getDefaultCurrencies();
      print('Loaded ${loadedCurrencies.length} currencies from default list');

      // Sort currencies with favorites first, then active, then inactive
      final sortedCurrencies = _sortCurrenciesWithFavorites(loadedCurrencies);

      setState(() {
        currencies = sortedCurrencies;
      });

      // Set default currencies with robust fallback logic
      if (currencies.isNotEmpty) {
        // Get preferred from currency (USD) with fallback - prefer active currencies
        Currency? preferredFrom = currencies.firstWhere(
          (c) => c.code == 'USD' && c.status == 'active',
          orElse:
              () => currencies.firstWhere(
                (c) => c.code == 'USD',
                orElse:
                    () => currencies.firstWhere(
                      (c) => c.status == 'active',
                      orElse: () => currencies.first,
                    ),
              ),
        );

        // Get preferred to currency (PKR) with fallback - prefer active currencies
        Currency? preferredTo = currencies.firstWhere(
          (c) => c.code == 'PKR' && c.status == 'active',
          orElse:
              () => currencies.firstWhere(
                (c) => c.code == 'PKR',
                orElse:
                    () =>
                        currencies.where((c) => c.status == 'active').isNotEmpty
                            ? currencies
                                .where((c) => c.status == 'active')
                                .first
                            : currencies.first,
              ),
        );

        // Ensure from and to currencies are different
        if (preferredFrom.code == preferredTo.code && currencies.length > 1) {
          final currentIndex = currencies.indexWhere(
            (c) => c.code == preferredFrom.code,
          );
          final nextIndex = (currentIndex + 1) % currencies.length;
          preferredTo = currencies[nextIndex];
        }

        setState(() {
          fromCurrency = preferredFrom;
          toCurrency = preferredTo;
        });

        print(
          'Selected currencies: ${fromCurrency?.code} -> ${toCurrency?.code}',
        );
      }

      // Fetch exchange rates after loading currencies
      fetchExchangeRates();
    } catch (e) {
      print('Error loading currencies: $e');
      // Fallback to default behavior
      fetchExchangeRates();
    }
  }

  Future<void> fetchExchangeRates() async {
    // Check if we're in offline mode
    final appSettings = Provider.of<AppSettings>(context, listen: false);
    if (appSettings.offlineMode) {
      _handleOfflineMode();
      return;
    }

    // Check connectivity first
    if (!ConnectivityService().isConnected) {
      _showNetworkErrorScreen();
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Use our simplified API service
      final ratesData = await ApiService.getExchangeRates('USD');
      
      if (ratesData['success']) {
        setState(() {
          rates = (ratesData['rates'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          );
          lastUpdated = ratesData['lastUpdated'] ?? '';
          isLoading = false;
        });
        convertCurrency();
      } else {
        setState(() {
          errorMessage = 'Failed to load exchange rates';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Network error in fetchExchangeRates: $e');
      setState(() {
        errorMessage = 'Network error: $e';
        isLoading = false;
      });

      // Check if it's a connectivity issue
      if (!ConnectivityService().isConnected) {
        _showNetworkErrorScreen();
      } else {
        // If network fails, show option to go offline
        _showOfflineOption();
      }
    }
  }

  // Show network error screen
  void _showNetworkErrorScreen() {
    ConnectivityService().showNetworkErrorScreen(
      context,
      onRetry: () {
        // Retry fetching exchange rates
        fetchExchangeRates();
      },
      onContinueOffline: () {
        // Continue in offline mode
        final appSettings = Provider.of<AppSettings>(context, listen: false);
        appSettings.setOfflineMode(true);
        _handleOfflineMode();
      },
    );
  }

  // Check connectivity on app start
  void _checkConnectivityOnStart() {
    // Add a small delay to ensure UI is fully loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !ConnectivityService().isConnected) {
        _showNetworkErrorScreen();
      }
    });
  }

  // Show offline option when network fails
  void _showOfflineOption() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Network Error'),
          content: const Text(
            'Unable to fetch latest rates. Would you like to continue in offline mode with cached rates?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _retryConnection();
              },
              child: const Text('Retry'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _continueOffline();
              },
              child: const Text('Continue Offline'),
            ),
          ],
        );
      },
    );
  }

  // Retry connection
  void _retryConnection() {
    fetchExchangeRates();
  }

  // Continue in offline mode
  void _continueOffline() {
    final appSettings = Provider.of<AppSettings>(context, listen: false);
    appSettings.setOfflineMode(true);
    _handleOfflineMode();
  }

  void convertCurrency() {
    if (fromCurrency == null || toCurrency == null || amount <= 0) return;

    double fromRate = rates[fromCurrency!.code] ?? 1.0;
    double toRate = rates[toCurrency!.code] ?? 1.0;

    setState(() {
      convertedAmount = (amount / fromRate) * toRate;
    });

    // Update widget with current conversion
    _updateWidget();
  }

  void _updateWidget() async {
    try {
      if (fromCurrency != null && toCurrency != null) {
        await updateCurrencyWidget(
          amount: amount,
          fromCode: fromCurrency!.code,
          toCode: toCurrency!.code,
        );
        print(
          'Widget updated successfully: $amount ${fromCurrency!.code} = ${convertedAmount.toStringAsFixed(2)} ${toCurrency!.code}',
        );

        // Force update the widget
        await Future.delayed(const Duration(milliseconds: 500), () async {
          try {
            await forceUpdateWidget();
            print('Widget force updated after conversion');
          } catch (e) {
            print('Error force updating widget: $e');
          }
        });
      }
    } catch (e) {
      print('Error updating widget: $e');
    }
  }

  void swapCurrencies() {
    setState(() {
      final temp = fromCurrency;
      fromCurrency = toCurrency;
      toCurrency = temp;
    });
    convertCurrency();

    // Update widget with swapped currencies
    _updateWidget();
  }

  String _numberToWords(int number) {
    if (number == 0) return 'Zero';

    final units = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
    ];
    final teens = [
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];
    final tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    String convertLessThanOneThousand(int n) {
      if (n == 0) return '';

      if (n < 10) return units[n];

      if (n < 20) return teens[n - 10];

      if (n < 100) {
        return tens[n ~/ 10] + (n % 10 != 0 ? ' ${units[n % 10]}' : '');
      }

      return '${units[n ~/ 100]} Hundred${n % 100 != 0 ? ' ${convertLessThanOneThousand(n % 100)}' : ''}';
    }

    if (number < 1000) {
      return convertLessThanOneThousand(number);
    }

    if (number < 1000000) {
      return '${convertLessThanOneThousand(number ~/ 1000)} Thousand${number % 1000 != 0 ? ' ${convertLessThanOneThousand(number % 1000)}' : ''}';
    }

    if (number < 1000000000) {
      return '${convertLessThanOneThousand(number ~/ 1000000)} Million${number % 1000000 != 0 ? ' ${_numberToWords(number % 1000000)}' : ''}';
    }

    return '${convertLessThanOneThousand(number ~/ 1000000000)} Billion${number % 1000000000 != 0 ? ' ${_numberToWords(number % 1000000000)}' : ''}';
  }

  void _navigateAndClose(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  List<Currency> _getDefaultCurrencies() {
    return [
      Currency(code: 'USD', name: 'US Dollar', flag: '🇺🇸', symbol: '\$'),
      Currency(code: 'EUR', name: 'Euro', flag: '🇪🇺', symbol: '€'),
      Currency(code: 'GBP', name: 'British Pound', flag: '🇬🇧', symbol: '£'),
      Currency(code: 'JPY', name: 'Japanese Yen', flag: '🇯🇵', symbol: '¥'),
      Currency(code: 'PKR', name: 'Pakistani Rupee', flag: '🇵🇰', symbol: '₨'),
      Currency(code: 'INR', name: 'Indian Rupee', flag: '🇮🇳', symbol: '₹'),
      Currency(code: 'CAD', name: 'Canadian Dollar', flag: '🇨🇦', symbol: 'C\$'),
      Currency(code: 'AUD', name: 'Australian Dollar', flag: '🇦🇺', symbol: 'A\$'),
    ];
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
        title: 'CurrenSee Pro',
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
                          child: FutureBuilder<String>(
                            future: AppVersionService.getAppVersion(),
                            builder: (context, snapshot) {
                              return Text(
                                'Version ${snapshot.data ?? '1.0.6'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              );
                            },
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
                onTap:
                    () => _navigateAndClose(
                      context,
                      const CurrencyConverterScreen(),
                    ),
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
              _buildDrawerItem(
                context,
                icon: Icons.task_alt,
                title: 'Currency Tasks',
                onTap: () => _navigateAndClose(context, const TaskScreen()),
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
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/signin', (route) => false);
                },
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? Center(
                child: Text(
                  'Error: $errorMessage',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              )
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // New Amount Input Section
                      DescribedFeatureOverlay(
                        featureId: 'amount_feature',
                        tapTarget: Icon(Icons.touch_app),
                        title: const Text('Enter Amount'),
                        description: const Text(
                          'Type the amount you want to convert here. You can also use the calculator for complex calculations.',
                        ),
                        backgroundColor: Colors.purple,
                        contentLocation: ContentLocation.above,
                        overflowMode: OverflowMode.wrapBackground,
                        enablePulsingAnimation: true,
                        child: Container(
                          key: _amountKey,
                          padding: const EdgeInsets.all(16), // Reduced padding
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'AMOUNT TO CONVERT',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Consumer<AppSettings>(
                                    builder: (context, appSettings, child) {
                                      // Only show calculator button if showCalculator is true
                                      if (!appSettings.showCalculator) {
                                        return const SizedBox.shrink(); // Hide the button
                                      }

                                      return DescribedFeatureOverlay(
                                        featureId: 'calculator_feature',
                                        tapTarget: Icon(Icons.calculate),
                                        title: const Text('Calculator'),
                                        description: const Text(
                                          'Use built-in calculator for complex calculations and apply the result to your amount.',
                                        ),
                                        backgroundColor: Colors.red,
                                        contentLocation:
                                            ContentLocation.trivial,
                                        overflowMode:
                                            OverflowMode.wrapBackground,
                                        enablePulsingAnimation: true,
                                        child: IconButton(
                                          key: _calculatorKey,
                                          icon: const Icon(
                                            Icons.calculate,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return CalculatorDialog(
                                                  onApply: (value) {
                                                    setState(() {
                                                      amount = value;
                                                      amountController
                                                          .text = value
                                                          .toStringAsFixed(2);
                                                    });
                                                    convertCurrency();
                                                  },
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8), // Reduced spacing
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: 80, // Limit height
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      fromCurrency?.symbol ?? '\$',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 28, // Reduced font size
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: amountController,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 28, // Reduced font size
                                          fontWeight: FontWeight.bold,
                                          height: 1.2,
                                        ),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          hintText: '0.00',
                                          hintStyle: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 28, // Reduced font size
                                          ),
                                        ),
                                        onTap: () {
                                          // Clear the text when user taps on the field
                                          if (amountController.text == '1.00') {
                                            amountController.clear();
                                            amount = 0.0;
                                            convertCurrency();
                                          }
                                        },
                                        onChanged: (value) {
                                          amount =
                                              double.tryParse(value) ?? 0.0;
                                          convertCurrency();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8), // Reduced spacing
                              Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              const SizedBox(height: 8), // Reduced spacing
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'CONVERTED AMOUNT',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Flexible(
                                    // Added Flexible to prevent overflow
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${convertedAmount.toStringAsFixed(2)} ${toCurrency?.code ?? ''}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18, // Reduced font size
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(
                                          height: 2,
                                        ), // Reduced spacing
                                        Text(
                                          '${_numberToWords(convertedAmount.toInt())} ${toCurrency?.symbol ?? ''}',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                            fontSize: 10, // Reduced font size
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20), // Reduced spacing
                      // Currency Selectors Column Layout
                      Column(
                        children: [
                          // From Currency Selector
                          DescribedFeatureOverlay(
                            featureId: 'from_currency_feature',
                            tapTarget: Icon(Icons.currency_exchange),
                            title: const Text('Source Currency'),
                            description: const Text(
                              'Select the currency you want to convert FROM. Swipe horizontally to see more options.',
                            ),
                            backgroundColor: Colors.green,
                            contentLocation: ContentLocation.below,
                            overflowMode: OverflowMode.wrapBackground,
                            enablePulsingAnimation: true,
                            child: SizedBox(
                              key: _fromCurrencyKey,
                              child: _buildCurrencySelector(
                                title: 'From Currency',
                                currency: fromCurrency,
                                onCurrencySelected: (currency) {
                                  setState(() {
                                    fromCurrency = currency;
                                  });
                                  convertCurrency();
                                },
                              ),
                            ),
                          ),

                          // Swap Button
                          DescribedFeatureOverlay(
                            featureId: 'swap_feature',
                            tapTarget: Icon(Icons.swap_vert),
                            title: const Text('Swap Currencies'),
                            description: const Text(
                              'Tap here to instantly swap between source and target currencies.',
                            ),
                            backgroundColor: Colors.blue,
                            contentLocation: ContentLocation.above,
                            overflowMode: OverflowMode.wrapBackground,
                            enablePulsingAnimation: true,
                            child: Container(
                              key: _swapKey,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4A6CD1),
                                    Color(0xFF8A4ED2),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.swap_vert,
                                  size: 32,
                                  color: Colors.white,
                                ),
                                onPressed: swapCurrencies,
                              ),
                            ),
                          ),

                          // To Currency Selector
                          DescribedFeatureOverlay(
                            featureId: 'to_currency_feature',
                            tapTarget: Icon(Icons.currency_exchange),
                            title: const Text('Target Currency'),
                            description: const Text(
                              'Select the currency you want to convert TO. Swipe horizontally to see more options.',
                            ),
                            backgroundColor: Colors.orange,
                            contentLocation: ContentLocation.below,
                            overflowMode: OverflowMode.wrapBackground,
                            enablePulsingAnimation: true,
                            child: SizedBox(
                              key: _toCurrencyKey,
                              child: _buildCurrencySelector(
                                title: 'To Currency',
                                currency: toCurrency,
                                onCurrencySelected: (currency) {
                                  setState(() {
                                    toCurrency = currency;
                                  });
                                  convertCurrency();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16), // Reduced spacing
                      // Rate Information
                      _buildRateInfo(),

                      // Currency Information
                      const SizedBox(height: 16), // Reduced spacing
                      _buildInfoSection(),
                    ],
                  ),
                ),
              ),
          if (_showSuccess)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Lottie.asset(
                    'assets/Login Success.json',
                    width: 200,
                    height: 200,
                    repeat: false,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 100,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          // Tutorial Help Button - Moved away from calculator
          Positioned(
            top: 15,
            left: 20,
            child: FeatureDiscovery(
              child: IconButton(
                icon: const Icon(
                  Icons.help_outline,
                  color: Colors.blue,
                  size: 28,
                ),
                onPressed: () async {
                  final appSettings = Provider.of<AppSettings>(
                    context,
                    listen: false,
                  );
                  final features = <String>[
                    'hamburger_feature',
                    'amount_feature',
                    'from_currency_feature',
                    'swap_feature',
                    'to_currency_feature',
                  ];

                  // Only add calculator feature if it's enabled
                  if (appSettings.showCalculator) {
                    features.add('calculator_feature');
                  }

                  await FeatureDiscovery.clearPreferences(context, features);
                  FeatureDiscovery.discoverFeatures(context, features);
                },
              ),
            ),
          ),

          // Connectivity Status Indicator
          Positioned(
            top: 15,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    ConnectivityService().isConnected
                        ? Colors.green.withOpacity(0.9)
                        : Colors.orange.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    ConnectivityService().isConnected
                        ? Icons.wifi
                        : Icons.wifi_off,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ConnectivityService().getConnectivityStatus(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector({
    required String title,
    required Currency? currency,
    required Function(Currency) onCurrencySelected,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
        ),
        SizedBox(
          height: 140, // Height for horizontal scrolling
          child: NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              final isFrom = title == 'From Currency';

              // Pause auto-scroll when user starts scrolling
              if (notification.direction.name != 'idle') {
                _pauseAutoScroll(isFrom);
              } else {
                // Only resume if user has stopped scrolling for a while
                // This prevents immediate resumption
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    _resumeAutoScroll(isFrom);
                  }
                });
              }
              return false;
            },
            child: ListView.builder(
              controller:
                  title == 'From Currency'
                      ? _fromScrollController
                      : _toScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: currencies.length,
              itemBuilder: (context, index) {
                final curr = currencies[index];
                final rate = getExchangeRateForCurrency(curr);
                final isSelected = currency?.code == curr.code;
                return GestureDetector(
                  onTap: () => onCurrencySelected(curr),
                  child: Container(
                    width: 120, // Fixed width for horizontal scrolling
                    margin: const EdgeInsets.only(
                      right: 8,
                    ), // Right margin for horizontal spacing
                    decoration: BoxDecoration(
                      gradient:
                          isSelected
                              ? const LinearGradient(
                                colors: [Color(0xFF4A6CD1), Color(0xFF8A4ED2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                              : null,
                      color: isSelected ? null : theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          curr.status == 'inactive'
                              ? Border.all(
                                color: Colors.red.withOpacity(0.5),
                                width: 1,
                              )
                              : null,
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Inactive overlay
                        if (curr.status == 'inactive')
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Display flag emoji
                              Text(
                                curr.flag,
                                style: TextStyle(
                                  fontSize: 24,
                                  color:
                                      curr.status == 'inactive'
                                          ? Colors.grey
                                          : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Star icon for favorite currencies
                              if (_isFavoriteCurrency(curr.code))
                                Icon(
                                  Icons.star,
                                  size: 12,
                                  color:
                                      isSelected ? Colors.white : Colors.amber,
                                ),
                              const SizedBox(height: 4),
                              Text(
                                curr.code,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : curr.status == 'inactive'
                                          ? Colors.grey
                                          : theme.textTheme.bodyLarge?.color,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              // Status indicator for inactive currencies
                              if (curr.status == 'inactive')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'BLOCKED',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else
                                Flexible(
                                  child: Text(
                                    '1 ${fromCurrency?.code} = ${rate.toStringAsFixed(4)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          isSelected
                                              ? Colors.white70
                                              : theme
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRateInfo() {
    if (fromCurrency == null || toCurrency == null) return const SizedBox();

    double exchangeRate =
        (convertedAmount / amount).isNaN ? 0.0 : convertedAmount / amount;

    double inverseRate =
        (amount / convertedAmount).isNaN ? 0.0 : amount / convertedAmount;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Exchange Rate:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Flexible(
                  // Added Flexible to prevent overflow
                  child: Text(
                    '1 ${fromCurrency!.code} = ${exchangeRate.toStringAsFixed(6)} ${toCurrency!.code}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // Reduced spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Inverse Rate:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Flexible(
                  // Added Flexible to prevent overflow
                  child: Text(
                    '1 ${toCurrency!.code} = ${inverseRate.toStringAsFixed(6)} ${fromCurrency!.code}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (lastUpdated.isNotEmpty) ...[
              const SizedBox(height: 12), // Reduced spacing
              Text(
                'Rates updated: $lastUpdated',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    final theme = Theme.of(context);
    if (fromCurrency == null || toCurrency == null) return const SizedBox();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Currency Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16), // Reduced spacing
            Row(
              children: [
                Text(
                  fromCurrency!.flag,
                  style: const TextStyle(fontSize: 36),
                ), // Reduced size
                const SizedBox(width: 12), // Reduced spacing
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fromCurrency!.name,
                        style: const TextStyle(
                          fontSize: 16, // Reduced font size
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4), // Reduced spacing
                      Text(
                        'Code: ${fromCurrency!.code} | Symbol: ${fromCurrency!.symbol}',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // Reduced spacing
            Row(
              children: [
                Text(
                  toCurrency!.flag,
                  style: const TextStyle(fontSize: 36),
                ), // Reduced size
                const SizedBox(width: 12), // Reduced spacing
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        toCurrency!.name,
                        style: const TextStyle(
                          fontSize: 16, // Reduced font size
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4), // Reduced spacing
                      Text(
                        'Code: ${toCurrency!.code} | Symbol: ${toCurrency!.symbol}',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // Reduced spacing
            const Text(
              'Popular Conversions:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8), // Reduced spacing
            _buildConversionChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionChips() {
    final popularPairs = [
      {'from': 'USD', 'to': 'EUR'},
      {'from': 'EUR', 'to': 'GBP'},
      {'from': 'USD', 'to': 'JPY'},
      {'from': 'GBP', 'to': 'INR'},
      {'from': 'USD', 'to': 'CAD'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          popularPairs.map((pair) {
            final fromRate = rates[pair['from']] ?? 1.0;
            final toRate = rates[pair['to']] ?? 1.0;
            final rate = (1 / fromRate) * toRate;

            return Chip(
              backgroundColor: Colors.blue[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              label: Text(
                '1 ${pair['from']} = ${rate.toStringAsFixed(2)} ${pair['to']}',
                style: TextStyle(color: Colors.blue[800]),
              ),
            );
          }).toList(),
    );
  }

  double getExchangeRateForCurrency(Currency currency) {
    if (fromCurrency == null) return 0.0;
    if (fromCurrency!.code == currency.code) return 1.0;

    double fromRate = rates[fromCurrency!.code] ?? 1.0;
    double toRate = rates[currency.code] ?? 1.0;

    return (1 / fromRate) * toRate;
  }

  void _setupAutoUpdate() {
    final appSettings = Provider.of<AppSettings>(context, listen: false);
    _autoUpdateTimer?.cancel();
    if (appSettings.autoUpdateRates) {
      // Immediately fetch once
      fetchExchangeRates();
      // Then schedule periodic updates
      _autoUpdateTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
        fetchExchangeRates();
      });
    } else {
      _autoUpdateTimer = null;
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    _fromAutoScrollTimer?.cancel();
    _toAutoScrollTimer?.cancel();

    // Remove scroll listeners before disposing controllers
    _fromScrollController.removeListener(_onFromScrollChanged);
    _toScrollController.removeListener(_onToScrollChanged);

    _fromScrollController.dispose();
    _toScrollController.dispose();
    _autoUpdateTimer?.cancel();
    super.dispose();
  }
}

class CalculatorDialog extends StatefulWidget {
  final Function(double) onApply;

  const CalculatorDialog({super.key, required this.onApply});

  @override
  _CalculatorDialogState createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  String _expression = '';
  String _result = '';
  final TextEditingController _controller = TextEditingController();

  void _handleButtonPress(String value) {
    setState(() {
      if (value == 'C') {
        _expression = '';
        _result = '';
      } else if (value == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (value == '=') {
        _calculateResult();
      } else {
        _expression += value;
      }
      _controller.text = _expression;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  void _calculateResult() {
    try {
      final parser = math_expressions.Parser();
      final exp = parser.parse(_expression);
      final contextModel = math_expressions.ContextModel();
      final eval = exp.evaluate(
        math_expressions.EvaluationType.REAL,
        contextModel,
      );
      setState(() {
        _result = eval.toString();
      });
    } catch (e) {
      setState(() {
        _result = 'Error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      'C',
      '⌫',
      '%',
      '/',
      '7',
      '8',
      '9',
      '*',
      '4',
      '5',
      '6',
      '-',
      '1',
      '2',
      '3',
      '+',
      '00',
      '0',
      '.',
      '=',
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Calculator',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              readOnly: true,
              style: const TextStyle(fontSize: 24),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon:
                    _result.isNotEmpty && _result != 'Error'
                        ? IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () {
                            final value = double.tryParse(_result) ?? 0.0;
                            widget.onApply(value);
                            Navigator.pop(context);
                          },
                        )
                        : null,
              ),
            ),
            const SizedBox(height: 8),
            if (_result.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _result == 'Error' ? _result : '= $_result',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _result == 'Error' ? Colors.red : Colors.green,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              childAspectRatio: 1.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              children:
                  buttons.map((key) {
                    Color bgColor;
                    Color txtColor;
                    double fontSize = 24;

                    if (key == 'C' || key == '⌫') {
                      bgColor = Colors.red.shade100;
                      txtColor = Colors.red;
                    } else if (key == '=') {
                      bgColor = Colors.green.shade100;
                      txtColor = Colors.green.shade800;
                      fontSize = 28;
                    } else if (['+', '-', '*', '/', '%'].contains(key)) {
                      bgColor = Colors.blue.shade50;
                      txtColor = Colors.blue.shade800;
                    } else {
                      bgColor = Colors.grey.shade100;
                      txtColor = Colors.black;
                    }

                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bgColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () => _handleButtonPress(key),
                      child: Text(
                        key,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: txtColor,
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _result.isNotEmpty && _result != 'Error'
                        ? () {
                          final value = double.tryParse(_result) ?? 0.0;
                          widget.onApply(value);
                          Navigator.pop(context);
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6CD1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply to Amount',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
