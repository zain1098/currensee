import 'package:cloud_firestore/cloud_firestore.dart';

class Currency {
  final String code;
  final String name;
  final String flag;
  final String symbol;
  final String status;

  Currency({
    required this.code,
    required this.name,
    required this.flag,
    required this.symbol,
    this.status = 'active',
  });

  factory Currency.fromMap(Map<String, dynamic> map) {
    return Currency(
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      flag: map['flag'] ?? '',
      symbol: map['symbol'] ?? '',
      status: map['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'flag': flag,
      'symbol': symbol,
      'status': status,
    };
  }
}

class CurrencyService {
  static Future<List<Currency>> loadCurrencies() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('currencies').get();
      return snapshot.docs.map((doc) => Currency.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error loading currencies: $e');
      return _getDefaultCurrencies();
    }
  }

  static List<Currency> _getDefaultCurrencies() {
    return [
      Currency(code: 'USD', name: 'US Dollar', flag: '🇺🇸', symbol: '\$'),
      Currency(code: 'EUR', name: 'Euro', flag: '🇪🇺', symbol: '€'),
      Currency(code: 'GBP', name: 'British Pound', flag: '🇬🇧', symbol: '£'),
      Currency(code: 'JPY', name: 'Japanese Yen', flag: '🇯🇵', symbol: '¥'),
      Currency(code: 'PKR', name: 'Pakistani Rupee', flag: '🇵🇰', symbol: '₨'),
    ];
  }
}