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

  @override
  String toString() {
    return 'Currency(code: $code, name: $name, flag: $flag, symbol: $symbol, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Currency && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}