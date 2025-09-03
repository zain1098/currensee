import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsCategory {
  final String id;
  final String name;
  final String apiCategory;
  final String status;
  final int maxArticles;

  NewsCategory({
    required this.id,
    required this.name,
    required this.apiCategory,
    required this.status,
    required this.maxArticles,
  });
}

class NewsService {
  static const String _newsApiUrl = "https://newsapi.org/v2/top-headlines";
  static const String _backupNewsUrl =
      "https://api.nytimes.com/svc/news/v3/content/all/business.json";

  // You'll need to add your API keys to .env file
  static String? _newsApiKey;
  static String? _nytimesApiKey;

  static Future<void> initialize() async {
    // Load API keys from environment variables
    // _newsApiKey = dotenv.env['NEWS_API_KEY'];
    // _nytimesApiKey = dotenv.env['NYTIMES_API_KEY'];
  }

  static Future<List<Map<String, dynamic>>> getFinancialNews() async {
    try {
      // Try NewsAPI first
      if (_newsApiKey != null) {
        final response = await http
            .get(
              Uri.parse(
                "$_newsApiUrl?country=us&category=business&apiKey=$_newsApiKey",
              ),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['articles'] != null) {
            return List<Map<String, dynamic>>.from(data['articles'].take(5));
          }
        }
      }

      // Fallback to hardcoded news
      return _getFallbackNews();
    } catch (e) {
      print("Error fetching news: $e");
      return _getFallbackNews();
    }
  }

  static List<Map<String, dynamic>> _getFallbackNews() {
    return [
      {
        'title': 'Global Markets Show Mixed Signals',
        'description':
            'Major indices fluctuate as investors weigh economic data and central bank policies.',
        'source': 'Financial Times',
        'publishedAt':
            DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'title': 'Cryptocurrency Markets Stabilize',
        'description':
            'Bitcoin and Ethereum show signs of recovery after recent volatility.',
        'source': 'CoinDesk',
        'publishedAt':
            DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      },
      {
        'title': 'Gold Prices Reach New Highs',
        'description':
            'Precious metal continues upward trend amid economic uncertainty.',
        'source': 'Reuters',
        'publishedAt':
            DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
      },
      {
        'title': 'Central Banks Signal Policy Changes',
        'description':
            'Federal Reserve and ECB hint at potential rate adjustments.',
        'source': 'Bloomberg',
        'publishedAt':
            DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      },
      {
        'title': 'Tech Stocks Lead Market Rally',
        'description':
            'Technology sector outperforms as earnings season begins.',
        'source': 'MarketWatch',
        'publishedAt':
            DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
      },
    ];
  }

  static String formatNewsForChat(List<Map<String, dynamic>> news) {
    if (news.isEmpty) return "No recent news available.";

    String formatted = "📰 **Latest Financial News**\n\n";

    for (int i = 0; i < news.length && i < 3; i++) {
      final article = news[i];
      final title = article['title'] ?? 'No title';
      final description = article['description'] ?? 'No description';
      final source =
          article['source']?['name'] ?? article['source'] ?? 'Unknown source';
      final time = article['publishedAt'] ?? '';

      formatted += "**${i + 1}. $title**\n";
      formatted += "$description\n";
      formatted += "*Source: $source*\n\n";
    }

    return formatted;
  }

  static Future<List<NewsCategory>> loadNewsCategories() async {
    return [
      NewsCategory(
        id: 'business',
        name: 'Business',
        apiCategory: 'business',
        status: 'active',
        maxArticles: 10,
      ),
      NewsCategory(
        id: 'technology',
        name: 'Technology',
        apiCategory: 'technology',
        status: 'active',
        maxArticles: 10,
      ),
      NewsCategory(
        id: 'general',
        name: 'General',
        apiCategory: 'general',
        status: 'active',
        maxArticles: 10,
      ),
    ];
  }

  static Future<Map<String, dynamic>> getNewsConfiguration() async {
    return {
      'apiKey': 'b2254f48318f9db55c21821b24d057bd',
      'baseUrl': 'https://gnews.io/api/v4/top-headlines',
      'defaultLanguage': 'en',
      'defaultCountry': 'us',
    };
  }
}
