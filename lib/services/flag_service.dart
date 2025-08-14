import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 🌍 Flag Service for CurrenSee App
/// Handles flag loading from API with fallback and error handling
class FlagService {
  // Flag API Configuration
  static const String _primaryFlagApi = 'https://flagcdn.com/w40/';
  static const String _fallbackFlagApi = 'https://flagcdn.com/w40/';
  static const String _highResFlagApi = 'https://flagcdn.com/w80/';

  // Flag cache for better performance
  static final Map<String, String> _flagCache = {};

  /// Get flag URL for a country code
  static String getFlagUrl(
    String countryCode, {
    FlagSize size = FlagSize.medium,
  }) {
    if (countryCode.isEmpty) return '';

    final normalizedCode = countryCode.toLowerCase();

    // Check cache first
    if (_flagCache.containsKey('${normalizedCode}_${size.name}')) {
      return _flagCache['${normalizedCode}_${size.name}']!;
    }

    String flagUrl;
    switch (size) {
      case FlagSize.small:
        flagUrl = '$_primaryFlagApi$normalizedCode.png';
        break;
      case FlagSize.medium:
        flagUrl = '$_primaryFlagApi$normalizedCode.png';
        break;
      case FlagSize.large:
        flagUrl = '$_highResFlagApi$normalizedCode.png';
        break;
    }

    // Cache the URL
    _flagCache['${normalizedCode}_${size.name}'] = flagUrl;

    return flagUrl;
  }

  /// Get flag widget with error handling and fallback
  static Widget getFlagWidget(
    String countryCode, {
    FlagSize size = FlagSize.medium,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    BoxBorder? border,
    Color? backgroundColor,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (countryCode.isEmpty) {
      return _getDefaultFlag(
        width: width,
        height: height,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        border: border,
      );
    }

    final flagUrl = getFlagUrl(countryCode, size: size);

    return CachedNetworkImage(
      imageUrl: flagUrl,
      width: width ?? _getDefaultWidth(size),
      height: height ?? _getDefaultHeight(size),
      fit: fit,
      placeholder:
          (context, url) =>
              placeholder ??
              _getLoadingPlaceholder(
                width: width,
                height: height,
                backgroundColor: backgroundColor,
                borderRadius: borderRadius,
                border: border,
              ),
      errorWidget:
          (context, url, error) =>
              errorWidget ??
              _getErrorFlag(
                countryCode: countryCode,
                width: width,
                height: height,
                backgroundColor: backgroundColor,
                borderRadius: borderRadius,
                border: border,
              ),
      imageBuilder:
          (context, imageProvider) => Container(
            width: width ?? _getDefaultWidth(size),
            height: height ?? _getDefaultHeight(size),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: border,
            ),
            child: ClipRRect(
              borderRadius: borderRadius ?? BorderRadius.zero,
              child: Image(
                image: imageProvider,
                fit: fit,
                errorBuilder:
                    (context, error, stackTrace) => _getErrorFlag(
                      countryCode: countryCode,
                      width: width,
                      height: height,
                      backgroundColor: backgroundColor,
                      borderRadius: borderRadius,
                      border: border,
                    ),
              ),
            ),
          ),
    );
  }

  /// Get flag widget for currency code
  static Widget getCurrencyFlag(
    String currencyCode, {
    FlagSize size = FlagSize.medium,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    BoxBorder? border,
    Color? backgroundColor,
  }) {
    // Map currency codes to country codes for flags
    final countryCode = _getCountryCodeFromCurrency(currencyCode);
    return getFlagWidget(
      countryCode,
      size: size,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      border: border,
      backgroundColor: backgroundColor,
    );
  }

  /// Get flag widget with custom styling
  static Widget getStyledFlag(
    String countryCode, {
    FlagSize size = FlagSize.medium,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    BoxBorder? border,
    Color? backgroundColor,
    List<BoxShadow>? boxShadow,
    Gradient? gradient,
  }) {
    return Container(
      width: width ?? _getDefaultWidth(size),
      height: height ?? _getDefaultHeight(size),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: border,
        boxShadow: boxShadow,
        gradient: gradient,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: getFlagWidget(
          countryCode,
          size: size,
          width: width,
          height: height,
          fit: fit,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }

  /// Preload flags for better performance
  static Future<void> preloadFlags(
    List<String> countryCodes, {
    FlagSize size = FlagSize.medium,
  }) async {
    for (final countryCode in countryCodes) {
      if (countryCode.isNotEmpty) {
        final flagUrl = getFlagUrl(countryCode, size: size);
        try {
          // Preload image - Note: precacheImage requires BuildContext
          // This will be handled in the UI layer where context is available
        } catch (e) {
          // Ignore preload errors
        }
      }
    }
  }

  /// Clear flag cache
  static void clearCache() {
    _flagCache.clear();
  }

  /// Get default flag dimensions
  static double _getDefaultWidth(FlagSize size) {
    switch (size) {
      case FlagSize.small:
        return 20;
      case FlagSize.medium:
        return 32;
      case FlagSize.large:
        return 48;
    }
  }

  static double _getDefaultHeight(FlagSize size) {
    switch (size) {
      case FlagSize.small:
        return 15;
      case FlagSize.medium:
        return 24;
      case FlagSize.large:
        return 36;
    }
  }

  /// Get country code from currency code
  static String _getCountryCodeFromCurrency(String currencyCode) {
    // Map of currency codes to country codes
    const currencyToCountry = {
      'USD': 'us', // United States
      'PKR': 'pk', // Pakistan
      'EUR': 'eu', // European Union
      'GBP': 'gb', // United Kingdom
      'INR': 'in', // India
      'JPY': 'jp', // Japan
      'CNY': 'cn', // China
      'CAD': 'ca', // Canada
      'AUD': 'au', // Australia
      'CHF': 'ch', // Switzerland
      'AED': 'ae', // UAE
      'SAR': 'sa', // Saudi Arabia
      'QAR': 'qa', // Qatar
      'KWD': 'kw', // Kuwait
      'BHD': 'bh', // Bahrain
      'OMR': 'om', // Oman
      'JOD': 'jo', // Jordan
      'LBP': 'lb', // Lebanon
      'EGP': 'eg', // Egypt
      'TRY': 'tr', // Turkey
      'RUB': 'ru', // Russia
      'KRW': 'kr', // South Korea
      'SGD': 'sg', // Singapore
      'HKD': 'hk', // Hong Kong
      'THB': 'th', // Thailand
      'MYR': 'my', // Malaysia
      'IDR': 'id', // Indonesia
      'PHP': 'ph', // Philippines
      'VND': 'vn', // Vietnam
      'BRL': 'br', // Brazil
      'MXN': 'mx', // Mexico
      'ARS': 'ar', // Argentina
      'CLP': 'cl', // Chile
      'COP': 'co', // Colombia
      'PEN': 'pe', // Peru
      'UYU': 'uy', // Uruguay
      'ZAR': 'za', // South Africa
      'NGN': 'ng', // Nigeria
      'KES': 'ke', // Kenya
      'GHS': 'gh', // Ghana
      'MAD': 'ma', // Morocco
      'TND': 'tn', // Tunisia
      'DZD': 'dz', // Algeria
      'LYD': 'ly', // Libya
      'SDG': 'sd', // Sudan
      'ETB': 'et', // Ethiopia
      'UGX': 'ug', // Uganda
      'TZS': 'tz', // Tanzania
      'ZMW': 'zm', // Zambia
      'MWK': 'mw', // Malawi
      'BWP': 'bw', // Botswana
      'NAD': 'na', // Namibia
      'SZL': 'sz', // Eswatini
      'LSL': 'ls', // Lesotho
      'MUR': 'mu', // Mauritius
      'SCR': 'sc', // Seychelles
      'KMF': 'km', // Comoros
      'DJF': 'dj', // Djibouti
      'SOS': 'so', // Somalia
      'ERN': 'er', // Eritrea
      'SSP': 'ss', // South Sudan
      'CDF': 'cd', // Democratic Republic of Congo
      'RWF': 'rw', // Rwanda
      'BIF': 'bi', // Burundi
      'CVE': 'cv', // Cape Verde
      'GMD': 'gm', // Gambia
      'GNF': 'gn', // Guinea
      'LRD': 'lr', // Liberia
      'SLL': 'sl', // Sierra Leone
      'STD': 'st', // Sao Tome and Principe
      'XOF': 'sn', // West African CFA (Senegal)
      'XAF': 'cm', // Central African CFA (Cameroon)
      'XPF': 'pf', // CFP Franc (French Polynesia)
      'BTC': 'btc', // Bitcoin (cryptocurrency)
      'ETH': 'eth', // Ethereum (cryptocurrency)
      'LTC': 'ltc', // Litecoin (cryptocurrency)
      'XRP': 'xrp', // Ripple (cryptocurrency)
      'ADA': 'ada', // Cardano (cryptocurrency)
      'DOT': 'dot', // Polkadot (cryptocurrency)
      'LINK': 'link', // Chainlink (cryptocurrency)
      'BCH': 'bch', // Bitcoin Cash (cryptocurrency)
      'XLM': 'xlm', // Stellar (cryptocurrency)
      'VET': 'vet', // VeChain (cryptocurrency)
    };

    return currencyToCountry[currencyCode.toUpperCase()] ??
        currencyCode.toLowerCase();
  }

  /// Get default flag widget
  static Widget _getDefaultFlag({
    double? width,
    double? height,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    BoxBorder? border,
  }) {
    return Container(
      width: width ?? 32,
      height: height ?? 24,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[300],
        borderRadius: borderRadius,
        border: border,
      ),
      child: Center(
        child: Icon(
          Icons.flag,
          size: (width ?? 32) * 0.4,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  /// Get loading placeholder
  static Widget _getLoadingPlaceholder({
    double? width,
    double? height,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    BoxBorder? border,
  }) {
    return Container(
      width: width ?? 32,
      height: height ?? 24,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[200],
        borderRadius: borderRadius,
        border: border,
      ),
      child: Center(
        child: SizedBox(
          width: (width ?? 32) * 0.3,
          height: (height ?? 24) * 0.3,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ),
    );
  }

  /// Get error flag widget
  static Widget _getErrorFlag({
    required String countryCode,
    double? width,
    double? height,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    BoxBorder? border,
  }) {
    return Container(
      width: width ?? 32,
      height: height ?? 24,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.red[100],
        borderRadius: borderRadius,
        border: border ?? Border.all(color: Colors.red[300]!, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: (width ?? 32) * 0.3,
              color: Colors.red[600],
            ),
            Text(
              countryCode.toUpperCase(),
              style: TextStyle(
                fontSize: (width ?? 32) * 0.2,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Flag size options
enum FlagSize {
  small, // 20x15
  medium, // 32x24
  large, // 48x36
}

/// Extension for easy flag widget creation
extension FlagWidgetExtension on String {
  /// Get flag widget for this country/currency code
  Widget toFlag({
    FlagSize size = FlagSize.medium,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    BoxBorder? border,
    Color? backgroundColor,
  }) {
    return FlagService.getFlagWidget(
      this,
      size: size,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      border: border,
      backgroundColor: backgroundColor,
    );
  }

  /// Get currency flag widget
  Widget toCurrencyFlag({
    FlagSize size = FlagSize.medium,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    BoxBorder? border,
    Color? backgroundColor,
  }) {
    return FlagService.getCurrencyFlag(
      this,
      size: size,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      border: border,
      backgroundColor: backgroundColor,
    );
  }
}
