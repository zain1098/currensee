import 'package:cloud_firestore/cloud_firestore.dart';

class Currency {
  final String code;
  final String name;
  final String symbol;
  final String flag;
  final String status; // 'active' or 'inactive'
  final DateTime createdAt;
  final DateTime? updatedAt;

  Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Currency.fromJson(Map<String, dynamic> json, String code) {
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) {
        return DateTime.now();
      }

      if (dateValue is Timestamp) {
        return dateValue.toDate();
      }

      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          print('Error parsing date string: $dateValue');
          return DateTime.now();
        }
      }

      return DateTime.now();
    }

    // Get proper flag emoji or symbol
    String getFlagEmoji(String code) {
      // Map currency codes to flag emojis
      final flagMap = {
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
        'KRW': '🇰🇷',
        'TRY': '🇹🇷',
        'NOK': '🇳🇴',
        'BRL': '🇧🇷',
        'ZAR': '🇿🇦',
        'IDR': '🇮🇩',
        'MXN': '🇲🇽',
        'THB': '🇹🇭',
        'HKD': '🇭🇰',
        'SAR': '🇸🇦',
        'AED': '🇦🇪',
        'CLP': '🇨🇱',
        'HUF': '🇭🇺',
        'CZK': '🇨🇿',
        'ILS': '🇮🇱',
        'PLN': '🇵🇱',
        'PHP': '🇵🇭',
        'MYR': '🇲🇾',
        'RON': '🇷🇴',
        'COP': '🇨🇴',
        'VND': '🇻🇳',
        'EGP': '🇪🇬',
        'BDT': '🇧🇩',
        'PKR': '🇵🇰',
        'DKK': '🇩🇰',
        'UAH': '🇺🇦',
        'NGN': '🇳🇬',
        'ARS': '🇦🇷',
        'PEN': '🇵🇪',
        'QAR': '🇶🇦',
        'KWD': '🇰🇼',
        'OMR': '🇴🇲',
        'BHD': '🇧🇭',
        'JOD': '🇯🇴',
        'LKR': '🇱🇰',
        'KZT': '🇰🇿',
        'TWD': '🇹🇼',
        'DZD': '🇩🇿',
        'BGN': '🇧🇬',
        'HRK': '🇭🇷',
        'RSD': '🇷🇸',
        'ISK': '🇮🇸',
        'FJD': '🇫🇯',
        'NAD': '🇳🇦',
        'ETB': '🇪🇹',
        'KES': '🇰🇪',
        'TZS': '🇹🇿',
        'UGX': '🇺🇬',
        'GHS': '🇬🇭', 'ZMW': '🇿🇲', 'XOF': '🇸🇳', 'XAF': '🇨🇲',
        // Cryptocurrencies
        'BTC': '₿', 'ETH': 'Ξ', 'ADA': '₳', 'LTC': 'Ł', 'XRP': 'XRP',
      };

      return flagMap[code] ?? '🏳️';
    }

    return Currency(
      code: code,
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
      flag: getFlagEmoji(code), // Use emoji flag instead of URL
      status: json['status'] ?? 'active',
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'symbol': symbol,
      'flag': flag,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}

class CurrencyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Load all currencies from Firebase (both active and inactive)
  static Future<List<Currency>> loadCurrencies() async {
    try {
      print('🔄 Loading currencies from Firebase...');

      // First, let's check if we can access the collection
      final collectionRef = _firestore.collection('currencies');
      print('📁 Collection reference created: ${collectionRef.path}');

      final querySnapshot = await collectionRef.get();
      print('📊 Found ${querySnapshot.docs.length} currencies in database');

      if (querySnapshot.docs.isEmpty) {
        print('⚠️ No documents found in currencies collection');
        print('⚠️ Using default currencies');
        return _getDefaultCurrencies();
      }

      List<Currency> currencies = [];
      for (var doc in querySnapshot.docs) {
        print('📄 Processing document: ${doc.id}');
        print('📄 Document data: ${doc.data()}');

        try {
          final currency = Currency.fromJson(doc.data(), doc.id);
          print(
            '💰 ${currency.code}: ${currency.name} (status: ${currency.status})',
          );

          // Load all currencies (both active and inactive)
          currencies.add(currency);
          print('✅ Added ${currency.code} (status: ${currency.status})');
        } catch (e) {
          print('❌ Error processing document ${doc.id}: $e');
        }
      }

      print('📈 Total currencies loaded: ${currencies.length}');

      // If no currencies found, return default currencies
      if (currencies.isEmpty) {
        print('⚠️ No currencies found, using defaults');
        return _getDefaultCurrencies();
      }

      return currencies;
    } catch (e) {
      print('❌ Error loading currencies: $e');
      print('⚠️ Using default currencies due to error');
      return _getDefaultCurrencies();
    }
  }

  // Load only active currencies from Firebase
  static Future<List<Currency>> loadActiveCurrencies() async {
    try {
      print('🔄 Loading active currencies from Firebase...');

      final collectionRef = _firestore.collection('currencies');
      print('📁 Collection reference created: ${collectionRef.path}');

      final querySnapshot = await collectionRef.get();
      print('📊 Found ${querySnapshot.docs.length} currencies in database');

      if (querySnapshot.docs.isEmpty) {
        print('⚠️ No documents found in currencies collection');
        print('⚠️ Using default currencies');
        return _getDefaultCurrencies();
      }

      List<Currency> currencies = [];
      for (var doc in querySnapshot.docs) {
        print('📄 Processing document: ${doc.id}');
        print('📄 Document data: ${doc.data()}');

        try {
          final currency = Currency.fromJson(doc.data(), doc.id);
          print(
            '💰 ${currency.code}: ${currency.name} (status: ${currency.status})',
          );

          // Only load active currencies
          if (currency.status == 'active') {
            currencies.add(currency);
            print('✅ Added ${currency.code} to active list');
          } else {
            print('❌ Skipped ${currency.code} (inactive)');
          }
        } catch (e) {
          print('❌ Error processing document ${doc.id}: $e');
        }
      }

      print('📈 Total active currencies: ${currencies.length}');

      // If no active currencies found, return default currencies
      if (currencies.isEmpty) {
        print('⚠️ No active currencies found, using defaults');
        return _getDefaultCurrencies();
      }

      return currencies;
    } catch (e) {
      print('❌ Error loading currencies: $e');
      print('⚠️ Using default currencies due to error');
      return _getDefaultCurrencies();
    }
  }

  // Get default currencies (fallback)
  static List<Currency> _getDefaultCurrencies() {
    return [
      Currency(
        code: 'USD',
        name: 'US Dollar',
        symbol: '\$',
        flag: '🇺🇸',
        status: 'active',
        createdAt: DateTime.now(),
      ),
      Currency(
        code: 'EUR',
        name: 'Euro',
        symbol: '€',
        flag: '🇪🇺',
        status: 'active',
        createdAt: DateTime.now(),
      ),
      Currency(
        code: 'GBP',
        name: 'British Pound',
        symbol: '£',
        flag: '🇬🇧',
        status: 'active',
        createdAt: DateTime.now(),
      ),
      Currency(
        code: 'JPY',
        name: 'Japanese Yen',
        symbol: '¥',
        flag: '🇯🇵',
        status: 'active',
        createdAt: DateTime.now(),
      ),
      Currency(
        code: 'INR',
        name: 'Indian Rupee',
        symbol: '₹',
        flag: '🇮🇳',
        status: 'active',
        createdAt: DateTime.now(),
      ),
      Currency(
        code: 'AUD',
        name: 'Australian Dollar',
        symbol: 'A\$',
        flag: '🇦🇺',
        status: 'active',
        createdAt: DateTime.now(),
      ),
      Currency(
        code: 'CAD',
        name: 'Canadian Dollar',
        symbol: 'C\$',
        flag: '🇨🇦',
        status: 'active',
        createdAt: DateTime.now(),
      ),
      Currency(
        code: 'CHF',
        name: 'Swiss Franc',
        symbol: 'Fr',
        flag: '🇨🇭',
        status: 'active',
        createdAt: DateTime.now(),
      ),
      Currency(
        code: 'SGD',
        name: 'Singapore Dollar',
        symbol: 'S\$',
        flag: '🇸🇬',
        status: 'active',
        createdAt: DateTime.now(),
      ),
    ];
  }

  // Initialize all currencies in database (one-time setup)
  static Future<void> initializeAllCurrencies() async {
    try {
      final allCurrencies = [
        {
          'code': 'USD',
          'name': 'US Dollar',
          'symbol': '\$',
          'flag': '🇺🇸',
          'status': 'active',
          'createdAt': Timestamp.now(),
        },
        {
          'code': 'EUR',
          'name': 'Euro',
          'symbol': '€',
          'flag': '🇪🇺',
          'status': 'active',
          'createdAt': Timestamp.now(),
        },
        {
          'code': 'GBP',
          'name': 'British Pound',
          'symbol': '£',
          'flag': '🇬🇧',
          'status': 'active',
          'createdAt': Timestamp.now(),
        },
        {
          'code': 'JPY',
          'name': 'Japanese Yen',
          'symbol': '¥',
          'flag': '🇯🇵',
          'status': 'active',
          'createdAt': Timestamp.now(),
        },
        {
          'code': 'INR',
          'name': 'Indian Rupee',
          'symbol': '₹',
          'flag': '🇮🇳',
          'status': 'active',
          'createdAt': Timestamp.now(),
        },
        {
          'code': 'PKR',
          'name': 'Pakistani Rupee',
          'symbol': 'Rs',
          'flag': '🇵🇰',
          'status': 'active',
          'createdAt': Timestamp.now(),
        },
        {
          'code': 'CNY',
          'name': 'Chinese Yuan',
          'symbol': '¥',
          'flag': '🇨🇳',
          'status': 'active',
          'createdAt': Timestamp.now(),
        },
        {
          'code': 'AUD',
          'name': 'Australian Dollar',
          'symbol': 'A',
          'flag': '🇦🇺',
          'status': 'active',
          'createdAt': Timestamp.now(),
        },
        {
          'code': 'CAD',
          'name': 'Canadian Dollar',
          'symbol': 'C',
          'flag': '🇨🇦',
          'status': 'active',
          'createdAt': Timestamp.now(),
        },
        {
          'code': 'CHF',
          'name': 'Swiss Franc',
          'symbol': 'Fr',
          'flag': '🇨🇭',
          'status': 'active',
          'createdAt': Timestamp.now(),
        },
        {
          'code': 'SGD',
          'name': 'Singapore Dollar',
          'symbol': 'S',
          'flag': '🇸🇬',
          'status': 'active',
          'createdAt': Timestamp.now(),
        },
        {
          'code': 'NZD',
          'name': 'New Zealand Dollar',
          'symbol': 'NZ',
          'flag': '🇳🇿',
          'status': 'active',
          'createdAt': Timestamp.now(),
        },
        {
          'code': 'MXN',
          'name': 'Mexican Peso',
          'symbol': '\$',
          'flag': '🇲🇽',
          'status': 'active',
          'createdAt': Timestamp.now(),
        },
        {
          'code': 'BRL',
          'name': 'Brazilian Real',
          'symbol': 'R',
          'flag': '🇧🇷',
          'status': 'active',
          'createdAt': Timestamp.now(),
        },
        {
          'code': 'RUB',
          'name': 'Russian Ruble',
          'symbol': '₽',
          'flag': '🇷🇺',
          'status': 'active',
          'createdAt': Timestamp.now(),
        },
        {
          'code': 'KRW',
          'name': 'South Korean Won',
          'symbol': '₩',
          'flag': '🇰🇷',
          'status': 'active',
          'createdAt': Timestamp.now(),
        },
        {
          'code': 'TRY',
          'name': 'Turkish Lira',
          'symbol': '₺',
          'flag': '🇹🇷',
          'status': 'active',
          'createdAt': Timestamp.now(),
        },
        {
          'code': 'ZAR',
          'name': 'South African Rand',
          'symbol': 'R',
          'flag': '🇿🇦',
          'status': 'active',
          'createdAt': Timestamp.now(),
        },
        {
          'code': 'SEK',
          'name': 'Swedish Krona',
          'symbol': 'kr',
          'flag': '🇸🇪',
          'status': 'active',
          'createdAt': Timestamp.now(),
        },
        {
          'code': 'NOK',
          'name': 'Norwegian Krone',
          'symbol': 'kr',
          'flag': '🇳🇴',
          'status': 'active',
          'createdAt': Timestamp.now(),
        },
      ];

      // Use batch write for better performance
      final batch = _firestore.batch();

      for (var currency in allCurrencies) {
        final docRef = _firestore
            .collection('currencies')
            .doc(currency['code'] as String);
        batch.set(docRef, currency);
      }

      await batch.commit();
      print('✅ All currencies initialized successfully!');
      print('📊 Total currencies added: ${allCurrencies.length}');
    } catch (e) {
      print('❌ Error initializing currencies: $e');
      rethrow;
    }
  }

  // Add new currency
  static Future<void> addCurrency(Currency currency) async {
    try {
      await _firestore
          .collection('currencies')
          .doc(currency.code)
          .set(currency.toJson());
    } catch (e) {
      print('Error adding currency: $e');
      rethrow;
    }
  }

  // Update currency
  static Future<void> updateCurrency(Currency currency) async {
    try {
      final updatedData = currency.toJson();
      updatedData['updatedAt'] = Timestamp.now();

      await _firestore
          .collection('currencies')
          .doc(currency.code)
          .update(updatedData);
    } catch (e) {
      print('Error updating currency: $e');
      rethrow;
    }
  }

  // Delete currency
  static Future<void> deleteCurrency(String currencyCode) async {
    try {
      await _firestore.collection('currencies').doc(currencyCode).delete();
    } catch (e) {
      print('Error deleting currency: $e');
      rethrow;
    }
  }

  // Block/Unblock currency
  static Future<void> toggleCurrencyStatus(
    String currencyCode,
    String status,
  ) async {
    try {
      await _firestore.collection('currencies').doc(currencyCode).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error toggling currency status: $e');
      rethrow;
    }
  }

  // Get currency by code
  static Future<Currency?> getCurrencyByCode(String currencyCode) async {
    try {
      final doc =
          await _firestore.collection('currencies').doc(currencyCode).get();

      if (doc.exists) {
        return Currency.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting currency by code: $e');
      return null;
    }
  }

  // Get first available active currency (fallback method)
  static Future<Currency?> getFirstActiveCurrency() async {
    try {
      final currencies = await loadCurrencies();
      return currencies.isNotEmpty ? currencies.first : null;
    } catch (e) {
      print('Error getting first active currency: $e');
      return null;
    }
  }

  // Get preferred currency with fallback
  static Future<Currency?> getPreferredCurrency(String preferredCode) async {
    try {
      // First try to get the preferred currency
      final preferred = await getCurrencyByCode(preferredCode);
      if (preferred != null && preferred.status == 'active') {
        return preferred;
      }

      // If preferred currency is not available or inactive, get first active currency
      return await getFirstActiveCurrency();
    } catch (e) {
      print('Error getting preferred currency: $e');
      return await getFirstActiveCurrency();
    }
  }
}
