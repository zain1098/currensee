import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart'; // For CustomAppBar
import 'news_page.dart';
import 'trend_chart.dart';
import 'rate_list_page.dart';
import 'task_page.dart';
import 'package:provider/provider.dart';
import 'calculator_page.dart';
import 'setting_page.dart';
import 'multi_currency_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'support_help_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/flag_service.dart';

class WorldClockPage extends StatefulWidget {
  const WorldClockPage({super.key});

  @override
  _WorldClockPageState createState() => _WorldClockPageState();
}

class _WorldClockPageState extends State<WorldClockPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Firebase data will be loaded here
  List<ClockLocation> allLocations = [];

  List<ClockLocation> locations = [];
  bool is24HourFormat = false;
  bool showAnalog = false;
  bool showDate = true;
  bool showDayProgress = true;
  bool showWeather = true;
  Timer? _timer;
  String _selectedTimezone = '';
  final ScrollController _scrollController = ScrollController();
  late AnimationController _listController;
  late Animation<Offset> _listAnimation;
  late Animation<double> _listScaleAnimation;
  final TextEditingController _searchController = TextEditingController();

  List<ClockLocation> _searchResults = [];
  bool _showAddLocation = false;
  bool _isLoading = true; // Add loading state
  String? _errorMessage; // Add error state
  late AnimationController _fabController;
  late AnimationController _clockChangeController;
  late Animation<double> _clockChangeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize animation controllers
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _listAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _listController, curve: Curves.easeOut));
    _listScaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _listController, curve: Curves.easeOut));
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _clockChangeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..value = 1.0;
    _clockChangeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _clockChangeController, curve: Curves.easeInOut),
    );

    // Start timer and animations
    _startTimer();
    _listController.forward();

    // Load data in correct order
    _initializeData();
  }

  // Initialize data in the correct order
  Future<void> _initializeData() async {
    try {
      // Load basic preferences first (UI settings)
      await _loadBasicPreferences();

      // Then load locations from Firebase (which will also load location preferences)
      await _loadLocationsFromFirebase();

      // Finally update times
      _updateAllTimes();

      // Mark loading as complete
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize: $e';
      });
      rethrow;
    }
  }

  // Load only basic UI preferences
  Future<void> _loadBasicPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      is24HourFormat = prefs.getBool('24hour') ?? false;
      showAnalog = prefs.getBool('analog') ?? false;
      showDate = prefs.getBool('showDate') ?? true;
      showDayProgress = prefs.getBool('showDayProgress') ?? true;
      showWeather = prefs.getBool('showWeather') ?? true;
    });
  }

  // Retry loading data
  Future<void> _retryLoading() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _initializeData();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data: $e';
      });
    }
  }

  // Load locations from Firebase
  Future<void> _loadLocationsFromFirebase() async {
    try {
      print('🔄 Loading locations from Firebase...');

      // Load all locations (both active and inactive) for status display
      final allSnapshot =
          await FirebaseFirestore.instance
              .collection('world_clock_cities')
              .orderBy('display_order')
              .get();

      if (allSnapshot.docs.isNotEmpty) {
        setState(() {
          allLocations =
              allSnapshot.docs.map((doc) {
                final data = doc.data();
                final location = ClockLocation(
                  timezone: data['timezone'] ?? '',
                  city: data['city'] ?? '',
                  utcOffset: data['gmt_offset']?.toString() ?? '+0',
                  flagUrl: data['flag_url'] ?? '',
                  country: data['country'] ?? '',
                  status: data['status'] ?? 'active', // Add status field
                );
                print(
                  '📍 Loaded location: ${location.city} (${location.status}) with flag URL: ${location.flagUrl}',
                );
                print('🏳️ Country code extracted: ${location.countryCode}');
                return location;
              }).toList();

          print(
            '✅ Loaded ${allLocations.length} locations from Firebase (${allLocations.where((loc) => loc.status == 'active').length} active)',
          );
        });

        // Now load preferences after locations are loaded
        await _loadPreferences();
      } else {
        print('⚠️ No locations found in Firebase, using fallback data');
        _loadFallbackLocations();
      }
    } catch (e) {
      print('❌ Error loading from Firebase: $e');
      print('🔄 Using fallback data...');
      _loadFallbackLocations();
    }
  }

  // Fallback to hardcoded data if Firebase fails
  void _loadFallbackLocations() {
    setState(() {
      allLocations = [
        ClockLocation(
          timezone: 'America/New_York',
          city: 'New York',
          utcOffset: '-5',
          flagUrl: 'https://flagcdn.com/w40/us.png',
          country: 'United States',
          status: 'active',
        ),
        ClockLocation(
          timezone: 'Europe/London',
          city: 'London',
          utcOffset: '+0',
          flagUrl: 'https://flagcdn.com/w40/gb.png',
          country: 'United Kingdom',
          status: 'active',
        ),
        ClockLocation(
          timezone: 'Asia/Tokyo',
          city: 'Tokyo',
          utcOffset: '+9',
          flagUrl: 'https://flagcdn.com/w40/jp.png',
          country: 'Japan',
          status: 'active',
        ),
        ClockLocation(
          timezone: 'Asia/Dubai',
          city: 'Dubai',
          utcOffset: '+4',
          flagUrl: 'https://flagcdn.com/w40/ae.png',
          country: 'UAE',
          status: 'active',
        ),
        ClockLocation(
          timezone: 'Asia/Karachi',
          city: 'Karachi',
          utcOffset: '+5',
          flagUrl: 'https://flagcdn.com/w40/pk.png',
          country: 'Pakistan',
          status: 'active',
        ),
      ];

      // Debug fallback locations
      for (final location in allLocations) {
        print(
          '📍 Fallback location: ${location.city} with flag URL: ${location.flagUrl}',
        );
        print('🏳️ Country code extracted: ${location.countryCode}');
      }
    });

    // Load preferences after fallback locations are set
    _loadPreferences();
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _scrollController.dispose();
    _listController.dispose();
    _fabController.dispose();
    _clockChangeController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      is24HourFormat = prefs.getBool('24hour') ?? false;
      showAnalog = prefs.getBool('analog') ?? false;
      showDate = prefs.getBool('showDate') ?? true;
      showDayProgress = prefs.getBool('showDayProgress') ?? true;
      showWeather = prefs.getBool('showWeather') ?? true;

      // Only try to load saved locations if allLocations is not empty
      if (allLocations.isNotEmpty) {
        final savedLocations = prefs.getStringList('savedLocations') ?? [];
        locations =
            allLocations
                .where((loc) => savedLocations.contains(loc.timezone))
                .toList();

        if (locations.isEmpty && allLocations.isNotEmpty) {
          // Use first active location as default
          final activeLocations =
              allLocations.where((loc) => loc.status == 'active').toList();
          if (activeLocations.isNotEmpty) {
            locations = [activeLocations[0]];
            _selectedTimezone = activeLocations[0].timezone;
          } else if (allLocations.isNotEmpty) {
            locations = [allLocations[0]];
            _selectedTimezone = allLocations[0].timezone;
          }
        } else if (locations.isNotEmpty) {
          _selectedTimezone = locations[0].timezone;
        }
      }
    });
  }

  Future<void> _saveLocations() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
      'savedLocations',
      locations.map((loc) => loc.timezone).toList(),
    );
  }

  void _startTimer() {
    _timer?.cancel(); // Cancel existing timer if any
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && locations.isNotEmpty) {
        _updateAllTimes();
      }
    });
  }

  void _updateAllTimes() {
    setState(() {
      for (var location in locations) {
        location.calculateLocalTime(is24HourFormat);
      }
    });
  }

  bool _isNightTime(DateTime time) {
    final hour = time.hour;
    return hour < 6 || hour >= 18;
  }

  void _selectLocation(ClockLocation location) {
    _clockChangeController.reset();
    setState(() {
      _selectedTimezone = location.timezone;
    });
    _clockChangeController.forward();
    final index = locations.indexWhere(
      (loc) => loc.timezone == location.timezone,
    );
    if (index != -1) {
      final screenWidth = MediaQuery.of(context).size.width;
      final itemWidth = 100.0;
      final offset = (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _searchLocations(String query) {
    setState(() {
      if (query.isEmpty) {
        _searchResults.clear();
      } else {
        // Show all matching locations (both active and inactive)
        _searchResults =
            allLocations
                .where(
                  (loc) => loc.city.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  void _toggleAddLocation() {
    setState(() {
      _showAddLocation = !_showAddLocation;
      if (_showAddLocation) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    });
  }

  void _addLocation(ClockLocation location) {
    // Check if location is active
    if (location.status != 'active') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${location.city} is temporarily unavailable'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!locations.any((loc) => loc.timezone == location.timezone)) {
      setState(() {
        locations.add(location);
        _selectedTimezone = location.timezone;
        _saveLocations();
      });
      _toggleAddLocation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${location.city} is already added')),
      );
    }
  }

  void _removeLocation(ClockLocation location) {
    if (locations.length > 1) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Remove ${location.city}?'),
              content: const Text(
                'This location will be removed from your list',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      locations.remove(location);
                      if (_selectedTimezone == location.timezone) {
                        _selectedTimezone = locations.first.timezone;
                      }
                      _saveLocations();
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one location must remain')),
      );
    }
  }

  void _navigateAndClose(BuildContext context, Widget page) {
    Navigator.pop(context); // Close drawer
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Handle loading state
    if (_isLoading) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: CustomAppBar(
          title: 'World Clock',
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Loading world clock data...'),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _retryLoading,
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Handle case when locations is empty
    if (locations.isEmpty) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: CustomAppBar(
          title: 'World Clock',
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'No locations available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Please check your internet connection'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _retryLoading,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Safe way to get selected location
    ClockLocation selectedLocation;
    try {
      selectedLocation = locations.firstWhere(
        (loc) => loc.timezone == _selectedTimezone,
        orElse: () => locations.first,
      );
    } catch (e) {
      // Fallback to first location if selected timezone not found
      selectedLocation = locations.first;
      _selectedTimezone = selectedLocation.timezone;
    }

    final isNight = _isNightTime(selectedLocation.localTime ?? DateTime.now());
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom;
    final isKeyboardVisible = bottomPadding > 0;

    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        title: 'World Clock',
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Theme.of(context).brightness == Brightness.dark
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
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                        : [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
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
      body: SafeArea(
        child: Column(
          children: [
            // Main clock area - takes available space
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ScaleTransition(
                    scale: _clockChangeAnimation,
                    child: FadeTransition(
                      opacity: _clockChangeAnimation,
                      child: _ClockCard(
                        location: selectedLocation,
                        isNight: isNight,
                        showAnalog: showAnalog,
                        showDate: showDate,
                        showDayProgress: showDayProgress,
                        showWeather: showWeather,
                        isMainClock: true,
                        onSettingsPressed: _showSettingsDialog,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // My Locations section - always at bottom
            if (!isKeyboardVisible)
              Container(
                height: 200,
                padding: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Locations',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          GestureDetector(
                            onTap: _toggleAddLocation,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.18),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: locations.length,
                        separatorBuilder:
                            (context, i) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final location = locations[index];
                          final isSelected =
                              _selectedTimezone == location.timezone;
                          return GestureDetector(
                            onTap: () => _selectLocation(location),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: isSelected ? 85 : 75,
                              height: isSelected ? 85 : 75,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient:
                                    isSelected
                                        ? LinearGradient(
                                          colors: [
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                        : LinearGradient(
                                          colors: [
                                            Theme.of(context).cardColor,
                                            Theme.of(context).cardColor,
                                          ],
                                        ),
                                boxShadow:
                                    isSelected
                                        ? [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.25),
                                            blurRadius: 12,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                        : null,
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.primary.withOpacity(0.8)
                                          : Theme.of(
                                            context,
                                          ).dividerColor.withOpacity(0.2),
                                  width: isSelected ? 2.5 : 1.0,
                                ),
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Use FlagService for flags with error handling
                                        if (location.countryCode != null)
                                          Container(
                                            width: 26,
                                            height: 16,
                                            constraints: const BoxConstraints(
                                              maxWidth: 26,
                                              maxHeight: 16,
                                            ),
                                            margin: const EdgeInsets.only(
                                              bottom: 2,
                                            ),
                                            child: ClipRect(
                                              child: Builder(
                                                builder: (context) {
                                                  try {
                                                    return FlagService.getFlagWidget(
                                                      location.countryCode!,
                                                      size: FlagSize.small,
                                                      errorWidget: Text(
                                                        location.flag,
                                                        style: TextStyle(
                                                          fontSize: isSelected ? 24 : 20,
                                                        ),
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    // Fallback to emoji flag if FlagService fails
                                                    return Text(
                                                      location.flag,
                                                      style: TextStyle(
                                                        fontSize: isSelected ? 24 : 20,
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                          )
                                        else
                                          Text(
                                            location.flag,
                                            style: TextStyle(
                                              fontSize: isSelected ? 26 : 22,
                                              shadows: isSelected
                                                  ? [
                                                    Shadow(
                                                      color: Colors.black.withOpacity(0.2),
                                                      blurRadius: 2,
                                                      offset: const Offset(0, 1),
                                                    ),
                                                  ]
                                                  : null,
                                            ),
                                          ),
                                        const SizedBox(height: 6),
                                        Text(
                                          location.city,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: isSelected ? 12 : 10,
                                            color:
                                                isSelected
                                                    ? Colors.white
                                                    : Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge
                                                        ?.color,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'UTC${location.utcOffset}',
                                          style: TextStyle(
                                            fontSize: isSelected ? 10 : 8,
                                            color:
                                                isSelected
                                                    ? Colors.white.withOpacity(
                                                      0.9,
                                                    )
                                                    : Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      top: -6,
                                      right: -6,
                                      child: GestureDetector(
                                        onTap: () => _removeLocation(location),
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.redAccent
                                                    .withOpacity(0.25),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            if (_showAddLocation)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleAddLocation,
                  child: Container(
                    color: Theme.of(context).shadowColor.withOpacity(0.5),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.7,
                            ),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.1),
                                  Theme.of(context).cardColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Add Location',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Search cities...',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    filled: true,
                                    fillColor:
                                        Theme.of(
                                          context,
                                        ).scaffoldBackgroundColor,
                                  ),
                                  onChanged: _searchLocations,
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child:
                                      _searchResults.isNotEmpty
                                          ? ListView.builder(
                                            itemCount: _searchResults.length,
                                            itemBuilder: (context, index) {
                                              final location =
                                                  _searchResults[index];
                                              return _SearchResultItem(
                                                location: location,
                                                isAdded: locations.contains(
                                                  location,
                                                ),
                                                onTap:
                                                    () =>
                                                        _addLocation(location),
                                              );
                                            },
                                          )
                                          : ListView.builder(
                                            itemCount: allLocations.length,
                                            itemBuilder: (context, index) {
                                              final location =
                                                  allLocations[index];
                                              return _SearchResultItem(
                                                location: location,
                                                isAdded: locations.contains(
                                                  location,
                                                ),
                                                onTap:
                                                    location.status == 'active'
                                                        ? () => _addLocation(
                                                          location,
                                                        )
                                                        : () {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                '${location.city} is temporarily unavailable',
                                                              ),
                                                              backgroundColor: Theme.of(context).colorScheme.secondary,
                                                              duration: const Duration(seconds: 3),
                                                            ),
                                                          );
                                                        },
                                              );
                                            },
                                          ),
                                ),
                                TextButton(
                                  onPressed: _toggleAddLocation,
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabController,
        child: FloatingActionButton(
          onPressed: _toggleAddLocation,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Future<void> _showSettingsDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clock Settings'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                SwitchListTile(
                  title: const Text('24-hour format'),
                  value: is24HourFormat,
                  onChanged: (value) async {
                    setState(() => is24HourFormat = value);
                    (await SharedPreferences.getInstance()).setBool(
                      '24hour',
                      value,
                    );
                    _updateAllTimes();
                    Navigator.of(context).pop();
                  },
                ),
                SwitchListTile(
                  title: const Text('Analog clocks'),
                  value: showAnalog,
                  onChanged: (value) async {
                    setState(() => showAnalog = value);
                    (await SharedPreferences.getInstance()).setBool(
                      'analog',
                      value,
                    );
                    Navigator.of(context).pop();
                  },
                ),
                SwitchListTile(
                  title: const Text('Show date'),
                  value: showDate,
                  onChanged: (value) async {
                    setState(() => showDate = value);
                    (await SharedPreferences.getInstance()).setBool(
                      'showDate',
                      value,
                    );
                    Navigator.of(context).pop();
                  },
                ),
                SwitchListTile(
                  title: const Text('Day progress'),
                  value: showDayProgress,
                  onChanged: (value) async {
                    setState(() => showDayProgress = value);
                    (await SharedPreferences.getInstance()).setBool(
                      'showDayProgress',
                      value,
                    );
                    Navigator.of(context).pop();
                  },
                ),
                SwitchListTile(
                  title: const Text('Weather info'),
                  value: showWeather,
                  onChanged: (value) async {
                    setState(() => showWeather = value);
                    (await SharedPreferences.getInstance()).setBool(
                      'showWeather',
                      value,
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class ClockLocation {
  final String timezone;
  final String city;
  final String utcOffset;
  final String? flagUrl; // Firebase flag URL
  final String? country; // Country name
  final String status; // Status: 'active' or 'inactive'
  String? time;
  String? date;
  DateTime? localTime;

  // Use FlagService for flags, fallback to emoji
  String get flag {
    if (flagUrl != null && flagUrl!.isNotEmpty) {
      return '🏳️'; // Placeholder - will be replaced with FlagService widget
    }
    return _getFlagForTimezone(timezone);
  }

  // Extract country code from flag URL
  String? get countryCode {
    if (flagUrl != null && flagUrl!.isNotEmpty) {
      try {
        // Extract country code from URL like "https://flagcdn.com/w40/us.png"
        final uri = Uri.parse(flagUrl!);
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          final filename = pathSegments.last;
          final dotIndex = filename.lastIndexOf('.');
          if (dotIndex > 0) {
            final countryCode = filename.substring(0, dotIndex);
            // Validate that it's a 2-letter country code
            if (countryCode.length == 2 &&
                countryCode.contains(RegExp(r'^[a-z]{2}$'))) {
              print(
                '✅ Extracted country code: $countryCode from URL: $flagUrl',
              );
              return countryCode;
            } else {
              print(
                '⚠️ Invalid country code format: $countryCode from URL: $flagUrl',
              );
            }
          }
        }
      } catch (e) {
        print('❌ Error extracting country code from flag URL: $e');
      }
    }
    return null;
  }

  ClockLocation({
    required this.timezone,
    required this.city,
    required this.utcOffset,
    this.flagUrl,
    this.country,
    this.status = 'active', // Default to active
    this.time,
    this.date,
    this.localTime,
  });

  void calculateLocalTime(bool is24HourFormat) {
    try {
      localTime = DateTime.now().toUtc().add(_getTimeZoneOffset());
      time = (is24HourFormat ? DateFormat.Hms() : DateFormat.jms()).format(
        localTime!,
      );
      date = DateFormat('EEE, MMM d').format(localTime!);
    } catch (e) {
      time = '--:--';
      date = 'Error';
      localTime = null;
    }
  }

  Duration _getTimeZoneOffset() {
    final hours = double.parse(utcOffset);
    final minutes = (hours - hours.truncate()) * 60;
    return Duration(hours: hours.toInt(), minutes: minutes.toInt());
  }

  String _getFlagForTimezone(String timezone) {
    final flagMap = {
      'Europe/London': '🇬🇧',
      'Europe/Paris': '🇫🇷',
      'America/New_York': '🇺🇸',
      'America/Los_Angeles': '🇺🇸',
      'Asia/Tokyo': '🇯🇵',
      'Asia/Dubai': '🇦🇪',
      'Australia/Sydney': '🇦🇺',
      'Asia/Shanghai': '🇨🇳',
      'Europe/Moscow': '🇷🇺',
      'America/Sao_Paulo': '🇧🇷',
      'Africa/Cairo': '🇪🇬',
      'Asia/Kolkata': '🇮🇳',
      'Asia/Karachi': '🇵🇰',
      // ... (add more as needed)
    };
    return flagMap[timezone] ?? '🌐';
  }
}

class _ClockCard extends StatelessWidget {
  final ClockLocation location;
  final bool isNight;
  final bool showAnalog;
  final bool showDate;
  final bool showDayProgress;
  final bool showWeather;
  final bool isMainClock;
  final VoidCallback onSettingsPressed;

  const _ClockCard({
    required this.location,
    required this.isNight,
    required this.showAnalog,
    required this.showDate,
    required this.showDayProgress,
    required this.showWeather,
    this.isMainClock = false,
    required this.onSettingsPressed,
  });

  double _calculateDayProgress() {
    if (location.localTime == null) return 0.0;
    return (location.localTime!.hour * 60 + location.localTime!.minute) /
        (24 * 60);
  }

  String _getWeatherIcon() {
    final hour = location.localTime?.hour ?? 12;
    if (hour >= 6 && hour < 18) {
      return '☀️';
    } else {
      return '🌙';
    }
  }

  String _getTemperature() {
    double baseTemp = isNight ? 18.0 : 25.0;
    if (location.timezone.contains('Asia')) {
      baseTemp += 5;
    } else if (location.timezone.contains('Europe')) {
      baseTemp -= 3;
    } else if (location.timezone.contains('Australia')) {
      baseTemp += 7;
    }
    final variation = math.Random().nextInt(5);
    return '${(baseTemp + variation).toStringAsFixed(1)}°C';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _calculateDayProgress();
    final cardColor = isNight ? Colors.grey[800]! : Theme.of(context).cardColor;
    final textColor =
        isNight ? Colors.white : Theme.of(context).textTheme.bodyLarge!.color!;
    final secondaryTextColor = isNight ? Colors.grey[300]! : Colors.grey[600]!;

    return Card(
      elevation: isMainClock ? 8 : 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMainClock ? 24 : 16),
      ),
      margin: EdgeInsets.all(isMainClock ? 16 : 8),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMainClock ? 16 : 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.city,
                      style: TextStyle(
                        fontSize: isMainClock ? 20 : 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'UTC${location.utcOffset}',
                      style: TextStyle(
                        fontSize: isMainClock ? 14 : 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (location.countryCode != null)
                      Container(
                        width: isMainClock ? 40 : 32,
                        height: isMainClock ? 30 : 24,
                        constraints: BoxConstraints(
                          maxWidth: isMainClock ? 40 : 32,
                          maxHeight: isMainClock ? 30 : 24,
                        ),
                        child: ClipRect(
                          child: Builder(
                            builder: (context) {
                              try {
                                return FlagService.getFlagWidget(
                                  location.countryCode!,
                                  size: isMainClock ? FlagSize.medium : FlagSize.small,
                                  errorWidget: Text(
                                    location.flag,
                                    style: TextStyle(fontSize: isMainClock ? 32 : 28),
                                  ),
                                );
                              } catch (e) {
                                // Fallback to emoji flag if FlagService fails
                                return Text(
                                  location.flag,
                                  style: TextStyle(fontSize: isMainClock ? 32 : 28),
                                );
                              }
                            },
                          ),
                        ),
                      )
                    else
                      Text(
                        location.flag,
                        style: TextStyle(fontSize: isMainClock ? 32 : 28),
                      ),
                    if (isMainClock)
                      IconButton(
                        icon: Icon(Icons.settings, size: 20, color: textColor),
                        onPressed: onSettingsPressed,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (showAnalog)
              SizedBox(
                height: isMainClock ? 120 : 80,
                child: Center(
                  child: AnalogClockWidget(
                    time: location.localTime ?? DateTime.now(),
                    size: isMainClock ? 120 : 80,
                  ),
                ),
              ),
            if (!showAnalog)
              Center(
                child: Text(
                  location.time ?? '--:--',
                  style: TextStyle(
                    fontSize: isMainClock ? 40 : 32,
                    fontWeight: FontWeight.w300,
                    color: textColor,
                  ),
                ),
              ),
            if (showDate && location.date != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Center(
                  child: Text(
                    location.date!,
                    style: TextStyle(
                      fontSize: isMainClock ? 14 : 12,
                      color: secondaryTextColor,
                    ),
                  ),
                ),
              ),
            if (showWeather)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getWeatherIcon(),
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getTemperature(),
                        style: TextStyle(
                          fontSize: isMainClock ? 16 : 14,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (showDayProgress) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor:
                      isNight ? Colors.grey[700]! : Colors.grey[200]!,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getDayProgressColor(progress),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sunrise 6:30',
                    style: TextStyle(
                      fontSize: isMainClock ? 12 : 10,
                      color: secondaryTextColor,
                    ),
                  ),
                  Text(
                    'Sunset 18:45',
                    style: TextStyle(
                      fontSize: isMainClock ? 12 : 10,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getDayProgressColor(double progress) {
    if (isNight) {
      if (progress < 0.25) return Colors.blueGrey[400]!;
      if (progress < 0.5) return Colors.blueGrey[300]!;
      if (progress < 0.75) return Colors.blueGrey[200]!;
      return Colors.blueGrey[100]!;
    } else {
      if (progress < 0.25) return Colors.blue[400]!;
      if (progress < 0.5) return Colors.lightBlue[300]!;
      if (progress < 0.75) return Colors.orange[300]!;
      return Colors.deepPurple[300]!;
    }
  }
}

class AnalogClockWidget extends StatelessWidget {
  final DateTime time;
  final double size;

  const AnalogClockWidget({super.key, required this.time, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AnalogClockPainter(time: time)),
    );
  }
}

class _AnalogClockPainter extends CustomPainter {
  final DateTime time;

  _AnalogClockPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.grey
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6 - math.pi / 2;
      final markerLength = i % 3 == 0 ? 10.0 : 5.0;
      final markerStart = Offset(
        center.dx + (radius - 10) * math.cos(angle),
        center.dy + (radius - 10) * math.sin(angle),
      );
      final markerEnd = Offset(
        center.dx + (radius - markerLength) * math.cos(angle),
        center.dy + (radius - markerLength) * math.sin(angle),
      );
      canvas.drawLine(
        markerStart,
        markerEnd,
        Paint()
          ..color = Colors.black
          ..strokeWidth = 2,
      );
    }
    final hourAngle =
        (time.hour % 12 + time.minute / 60) * math.pi / 6 - math.pi / 2;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.4 * math.cos(hourAngle),
        center.dy + radius * 0.4 * math.sin(hourAngle),
      ),
      Paint()
        ..color = Colors.black
        ..strokeWidth = 4,
    );
    final minuteAngle = time.minute * math.pi / 30 - math.pi / 2;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.6 * math.cos(minuteAngle),
        center.dy + radius * 0.6 * math.sin(minuteAngle),
      ),
      Paint()
        ..color = Colors.black
        ..strokeWidth = 3,
    );
    final secondAngle = time.second * math.pi / 30 - math.pi / 2;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.7 * math.cos(secondAngle),
        center.dy + radius * 0.7 * math.sin(secondAngle),
      ),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(center, 5, Paint()..color = Colors.red);
    canvas.drawCircle(center, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SearchResultItem extends StatelessWidget {
  final ClockLocation location;
  final bool isAdded;
  final VoidCallback onTap;

  const _SearchResultItem({
    required this.location,
    required this.isAdded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isInactive = location.status != 'active';

    return ListTile(
      leading: location.countryCode != null
          ? Container(
              width: 24,
              height: 18,
              constraints: const BoxConstraints(maxWidth: 24, maxHeight: 18),
              child: ClipRect(
                child: Builder(
                  builder: (context) {
                    try {
                      return FlagService.getFlagWidget(
                        location.countryCode!,
                        size: FlagSize.small,
                        errorWidget: Text(
                          location.flag,
                          style: const TextStyle(fontSize: 18),
                        ),
                      );
                    } catch (e) {
                      // Fallback to emoji flag if FlagService fails
                      return Text(
                        location.flag,
                        style: const TextStyle(fontSize: 18),
                      );
                    }
                  },
                ),
              ),
            )
          : Text(location.flag, style: const TextStyle(fontSize: 20)),
      title: Row(
        children: [
          Expanded(
            child: Text(
              location.city,
              style: TextStyle(
                color: isInactive ? Theme.of(context).disabledColor : null,
                decoration: isInactive ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (isInactive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
              ),
              child: Text(
                'BLOCKED',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        'UTC${location.utcOffset}',
        style: TextStyle(color: isInactive ? Theme.of(context).disabledColor : null),
      ),
      trailing: isInactive
          ? Icon(Icons.block, color: Theme.of(context).colorScheme.secondary)
          : isAdded
              ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
              : Icon(Icons.add, color: Theme.of(context).iconTheme.color),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: isInactive ? Theme.of(context).disabledColor.withOpacity(0.1) : null,
    );
  }
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
        splashColor: isDark 
            ? Colors.white.withOpacity(0.1) 
            : Colors.black.withOpacity(0.1),
        highlightColor: isDark 
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
