import 'package:http/http.dart' as http;

class GoogleSearchCurrencyService {
  /// Get currency rate using Google Search (same as typing in Google)
  static Future<Map<String, dynamic>> getGoogleSearchRate(String from, String to) async {
    try {
      // Same query as you type in Google: "1 USD to PKR"
      final query = '1 $from to $to';
      final encodedQuery = Uri.encodeComponent(query);
      
      final response = await http.get(
        Uri.parse('https://www.google.com/search?q=$encodedQuery'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final html = response.body;
        
        // Extract the exact rate Google shows
        final patterns = [
          RegExp(r'data-value="([0-9,.]+)"'),
          RegExp(r'<span class="DFlfde SwHCTb" data-precision="[0-9]+" data-value="([0-9,.]+)"'),
          RegExp(r'([0-9,]+\.?[0-9]*)\s+' + to),
        ];
        
        for (final pattern in patterns) {
          final match = pattern.firstMatch(html);
          if (match != null) {
            final rateStr = match.group(1)!.replaceAll(',', '');
            final rate = double.parse(rateStr);
            
            return {
              'success': true,
              'rate': rate,
              'from': from,
              'to': to,
              'source': 'Google Search',
              'query': query,
              'lastUpdated': DateTime.now().toIso8601String(),
            };
          }
        }
      }
      throw Exception('Could not extract rate from Google');
    } catch (e) {
      throw Exception('Google Search error: $e');
    }
  }

  /// Convert amount using Google's exact rate
  static Future<Map<String, dynamic>> convertWithGoogle({
    required String from,
    required String to,
    required double amount,
  }) async {
    try {
      final rateData = await getGoogleSearchRate(from, to);
      if (rateData['success']) {
        final rate = rateData['rate'] as double;
        final convertedAmount = amount * rate;
        
        return {
          'success': true,
          'from': from,
          'to': to,
          'amount': amount,
          'rate': rate,
          'convertedAmount': convertedAmount,
          'source': 'Google Search',
          'lastUpdated': rateData['lastUpdated'],
        };
      }
      throw Exception('Failed to get Google rate');
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}