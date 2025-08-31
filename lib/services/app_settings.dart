import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  bool _darkMode = false;
  int _decimalPlaces = 2;
  String _baseCurrency = 'USD';
  bool _autoUpdateRates = true;
  bool _biometricAuth = false;
  bool _hapticFeedback = true;
  bool _showCalculator = true;
  bool _historicalData = false;
  bool _offlineMode = false;
  String _selectedLanguage = 'English';
  String _selectedAppearance = 'System';
  List<String> _favoriteCurrencies = [];

  // Getters
  bool get darkMode => _darkMode;
  int get decimalPlaces => _decimalPlaces;
  String get baseCurrency => _baseCurrency;
  bool get autoUpdateRates => _autoUpdateRates;
  bool get biometricAuth => _biometricAuth;
  bool get hapticFeedback => _hapticFeedback;
  bool get showCalculator => _showCalculator;
  bool get historicalData => _historicalData;
  bool get offlineMode => _offlineMode;
  String get selectedLanguage => _selectedLanguage;
  String get selectedAppearance => _selectedAppearance;
  List<String> get favoriteCurrencies => _favoriteCurrencies;

  // Load settings from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('darkMode') ?? false;
    _decimalPlaces = prefs.getInt('decimalPlaces') ?? 2;
    _baseCurrency = prefs.getString('baseCurrency') ?? 'USD';
    _autoUpdateRates = prefs.getBool('autoUpdateRates') ?? true;
    _biometricAuth = prefs.getBool('biometricAuth') ?? false;
    _hapticFeedback = prefs.getBool('hapticFeedback') ?? true;
    _showCalculator = prefs.getBool('showCalculator') ?? true;
    _historicalData = prefs.getBool('historicalData') ?? false;
    _offlineMode = prefs.getBool('offlineMode') ?? false;
    _selectedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    _selectedAppearance = prefs.getString('selectedAppearance') ?? 'System';
    _favoriteCurrencies = prefs.getStringList('favoriteCurrencies') ?? [];
    notifyListeners();
  }

  // Save settings to SharedPreferences
  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    }
    notifyListeners();
  }

  // Setters with save functionality
  void setDarkMode(bool value) {
    _darkMode = value;
    _saveSetting('darkMode', value);
  }

  void setDecimalPlaces(int value) {
    _decimalPlaces = value;
    _saveSetting('decimalPlaces', value);
  }

  void setBaseCurrency(String value) {
    _baseCurrency = value;
    _saveSetting('baseCurrency', value);
  }

  void setAutoUpdateRates(bool value) {
    _autoUpdateRates = value;
    _saveSetting('autoUpdateRates', value);
  }

  void setBiometricAuth(bool value) {
    _biometricAuth = value;
    _saveSetting('biometricAuth', value);
  }

  void setHapticFeedback(bool value) {
    _hapticFeedback = value;
    _saveSetting('hapticFeedback', value);
  }

  void setShowCalculator(bool value) {
    _showCalculator = value;
    _saveSetting('showCalculator', value);
  }

  void setHistoricalData(bool value) {
    _historicalData = value;
    _saveSetting('historicalData', value);
  }

  void setOfflineMode(bool value) {
    _offlineMode = value;
    _saveSetting('offlineMode', value);
  }

  void setSelectedLanguage(String value) {
    _selectedLanguage = value;
    _saveSetting('selectedLanguage', value);
  }

  void setSelectedAppearance(String value) {
    _selectedAppearance = value;
    _saveSetting('selectedAppearance', value);

    // Update darkMode for backward compatibility
    if (value == 'Dark') {
      _darkMode = true;
      _saveSetting('darkMode', true);
    } else if (value == 'Light') {
      _darkMode = false;
      _saveSetting('darkMode', false);
    }
  }

  // Get current theme mode based on appearance setting and system brightness
  ThemeMode getCurrentThemeMode(BuildContext context) {
    switch (_selectedAppearance) {
      case 'System':
        return ThemeMode.system;
      case 'Dark':
        return ThemeMode.dark;
      case 'Light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  // Get current brightness for UI updates (used in settings page)
  bool getCurrentBrightness(BuildContext context) {
    switch (_selectedAppearance) {
      case 'System':
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
      case 'Dark':
        return true;
      case 'Light':
        return false;
      default:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }

  void setFavoriteCurrencies(List<String> currencies) {
    _favoriteCurrencies = currencies;
    _saveSetting('favoriteCurrencies', currencies);
  }

  void addFavoriteCurrency(String currencyCode) {
    if (!_favoriteCurrencies.contains(currencyCode) &&
        _favoriteCurrencies.length < 3) {
      _favoriteCurrencies.add(currencyCode);
      _saveSetting('favoriteCurrencies', _favoriteCurrencies);
      notifyListeners();
    }
  }

  void removeFavoriteCurrency(String currencyCode) {
    _favoriteCurrencies.remove(currencyCode);
    _saveSetting('favoriteCurrencies', _favoriteCurrencies);
  }

  bool isFavoriteCurrency(String currencyCode) {
    return _favoriteCurrencies.contains(currencyCode);
  }

  // Reset all settings to defaults
  Future<void> resetToDefaults() async {
    _darkMode = false;
    _decimalPlaces = 2;
    _baseCurrency = 'USD';
    _autoUpdateRates = true;
    _biometricAuth = false;
    _hapticFeedback = true;
    _showCalculator = true;
    _historicalData = false;
    _offlineMode = false;
    _selectedLanguage = 'English';
    _selectedAppearance = 'System';
    _favoriteCurrencies = [];

    // Clear all settings from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('darkMode');
    await prefs.remove('decimalPlaces');
    await prefs.remove('baseCurrency');
    await prefs.remove('autoUpdateRates');
    await prefs.remove('biometricAuth');
    await prefs.remove('hapticFeedback');
    await prefs.remove('showCalculator');
    await prefs.remove('historicalData');
    await prefs.remove('offlineMode');
    await prefs.remove('selectedLanguage');
    await prefs.remove('selectedAppearance');
    await prefs.remove('favoriteCurrencies');

    notifyListeners();
  }
}
