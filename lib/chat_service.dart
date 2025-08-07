// chat_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? 'DEFAULT_API_KEY';
  static const String _baseUrl =
      "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent";

  // Add real-time currency API
  static const String _currencyApiUrl = "https://open.er-api.com/v6/latest/USD";
  static const String _cryptoApiUrl =
      "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=usd,eur,pkr&include_24hr_change=true";
  static const String _goldApiUrl = "https://api.metals.live/v1/spot/gold";

  Map<String, dynamic> _exchangeRates = {};
  Map<String, dynamic> _cryptoRates = {};
  Map<String, dynamic> _goldRates = {};
  String _lastUpdated = "";

  // Conversation memory
  List<Map<String, String>> _conversationHistory = [];
  String _userContext = "";
  int _conversationCount = 0;

  ChatService() {
    _fetchAllRates();
    _loadConversationHistory();
  }

  Future<void> _fetchAllRates() async {
    await Future.wait([
      _fetchExchangeRates(),
      _fetchCryptoRates(),
      _fetchGoldRates(),
    ]);
  }

  Future<void> _fetchExchangeRates() async {
    try {
      final response = await http.get(Uri.parse(_currencyApiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == 'success') {
          _exchangeRates = data['rates'];
          _lastUpdated = data['time_last_update_utc'];
        }
      }
    } catch (e) {
      print("Failed to fetch exchange rates: $e");
    }
  }

  Future<void> _fetchCryptoRates() async {
    try {
      final response = await http.get(Uri.parse(_cryptoApiUrl));
      if (response.statusCode == 200) {
        _cryptoRates = jsonDecode(response.body);
      }
    } catch (e) {
      print("Failed to fetch crypto rates: $e");
    }
  }

  Future<void> _fetchGoldRates() async {
    try {
      final response = await http.get(Uri.parse(_goldApiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          _goldRates = data[0];
        }
      }
    } catch (e) {
      print("Failed to fetch gold rates: $e");
    }
  }

  String _formatRates() {
    if (_exchangeRates.isEmpty) return "";

    String rates =
        "📊 **REAL-TIME FINANCIAL DATA** (Updated: $_lastUpdated)\n\n";

    // Major currencies
    rates += "💱 **Major Currencies vs USD:**\n";
    const mainCurrencies = [
      'PKR',
      'EUR',
      'GBP',
      'JPY',
      'CAD',
      'AUD',
      'INR',
      'CNY',
    ];
    for (final currency in mainCurrencies) {
      if (_exchangeRates.containsKey(currency)) {
        rates += "• 1 USD = ${_exchangeRates[currency]} $currency\n";
      }
    }

    // Crypto rates
    if (_cryptoRates.isNotEmpty) {
      rates += "\n₿ **Cryptocurrency Prices:**\n";
      if (_cryptoRates['bitcoin'] != null) {
        final btc = _cryptoRates['bitcoin'];
        final btcChange = btc['usd_24h_change'] ?? 0.0;
        rates +=
            "• Bitcoin: \$${btc['usd']?.toStringAsFixed(2)} (24h: ${btcChange > 0 ? '+' : ''}${btcChange.toStringAsFixed(2)}%)\n";
      }
      if (_cryptoRates['ethereum'] != null) {
        final eth = _cryptoRates['ethereum'];
        final ethChange = eth['usd_24h_change'] ?? 0.0;
        rates +=
            "• Ethereum: \$${eth['usd']?.toStringAsFixed(2)} (24h: ${ethChange > 0 ? '+' : ''}${ethChange.toStringAsFixed(2)}%)\n";
      }
    }

    // Gold rates
    if (_goldRates.isNotEmpty) {
      rates += "\n🥇 **Gold Price:**\n";
      rates += "• Gold: \$${_goldRates['price']?.toStringAsFixed(2)} per oz\n";
    }

    return rates;
  }

  Future<void> _loadConversationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('chat_history') ?? [];
      _conversationHistory =
          history
              .map((item) => Map<String, String>.from(jsonDecode(item)))
              .toList();
      _conversationCount = prefs.getInt('conversation_count') ?? 0;
      _userContext = prefs.getString('user_context') ?? "";
    } catch (e) {
      print("Failed to load conversation history: $e");
    }
  }

  Future<void> _saveConversationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history =
          _conversationHistory.map((item) => jsonEncode(item)).toList();
      await prefs.setStringList('chat_history', history);
      await prefs.setInt('conversation_count', _conversationCount);
      await prefs.setString('user_context', _userContext);
    } catch (e) {
      print("Failed to save conversation history: $e");
    }
  }

  void _addToHistory(String role, String content) {
    _conversationHistory.add({'role': role, 'content': content});
    if (_conversationHistory.length > 20) {
      _conversationHistory.removeAt(0);
    }
    _saveConversationHistory();
  }

  Future<String> getCurrencyResponse(String userInput) async {
    // Get current date/time
    final now = DateTime.now();
    final formattedDate = DateFormat('MMMM dd, yyyy').format(now);
    final formattedTime = DateFormat('HH:mm').format(now);
    final utcTime = DateFormat('HH:mm').format(now.toUtc());

    // Update conversation count
    _conversationCount++;

    // Add user input to history
    _addToHistory('user', userInput);

    // Check for basic greetings and responses
    final lowerInput = userInput.toLowerCase().trim();
    if (lowerInput.contains('hello') ||
        lowerInput.contains('hi') ||
        lowerInput.contains('hey')) {
      final response =
          "Hello! 👋 I'm CurrencyPro Ultra AI, your financial intelligence assistant. How can I help you with currency conversions, market rates, or financial insights today?";
      _addToHistory('assistant', response);
      return response;
    }

    if (lowerInput.contains('how are you')) {
      final response =
          "I'm doing great! 🚀 Ready to help you with all your financial queries. What would you like to know about currencies, exchange rates, or market trends?";
      _addToHistory('assistant', response);
      return response;
    }

    if (lowerInput.contains('thank')) {
      final response =
          "You're welcome! 😊 Is there anything else I can help you with regarding currencies or financial markets?";
      _addToHistory('assistant', response);
      return response;
    }

    if (lowerInput.contains('bye') || lowerInput.contains('goodbye')) {
      final response =
          "Goodbye! 👋 Feel free to come back anytime for currency and financial assistance. Have a great day!";
      _addToHistory('assistant', response);
      return response;
    }

    // Enhanced system prompt with advanced features
    final systemPrompt = """
You are **CurrencyPro Ultra AI**, the world's most advanced financial intelligence assistant.

${_formatRates()}

🎯 **CORE CAPABILITIES:**

1. **REAL-TIME FINANCIAL INTELLIGENCE:**
   • Live currency, crypto, and commodity rates
   • Market sentiment analysis
   • Economic indicator tracking
   • Breaking financial news synthesis

2. **ADVANCED ANALYTICS:**
   • Predictive market insights
   • Risk assessment and recommendations
   • Portfolio optimization suggestions
   • Technical analysis summaries

3. **COMPREHENSIVE SUPPORT:**
   • Complex multi-currency calculations
   • Historical trend analysis
   • Investment strategy consultation
   • Tax and regulatory guidance

4. **PERSONALIZED EXPERIENCE:**
   • Conversation memory ($_conversationCount interactions)
   • User preference learning
   • Context-aware responses
   • Adaptive communication style

📋 **RESPONSE PROTOCOLS:**

**For Conversion Requests:**
• Show real-time rates with timestamps
• Provide step-by-step calculations
• Include conversion fees and spreads
• Suggest optimal conversion timing

**For Market Queries:**
• Current market status with trends
• 24h/7d/30d performance metrics
• Key influencing factors
• Risk level assessment

**For Investment Advice:**
• Diversification recommendations
• Risk-reward analysis
• Market timing insights
• Regulatory considerations

**For News Requests:**
• Top 3 breaking stories
• Market impact analysis
• Source credibility ratings
• Actionable insights

🎨 **RESPONSE FORMATTING:**
• Use tables for multi-currency comparisons
• Mark volatility: 📈📉📊
• Urgent updates: 🔔⚡
• Format numbers: 1,234.56
• Include confidence ratings: ⭐⭐⭐⭐⭐
• Add data freshness indicators

**Conversation Context:**
$_userContext

**Current Session:** Interaction #$_conversationCount
**Date:** $formattedDate | **Time:** $formattedTime UTC
**Data Freshness:** ${_lastUpdated.isNotEmpty ? 'Live' : 'Cached'}
""";

    try {
      // Build conversation context
      final conversationContext =
          _conversationHistory
              .take(10)
              .map(
                (msg) => {
                  "role": msg['role'],
                  "parts": [
                    {"text": msg['content']},
                  ],
                },
              )
              .toList();

      final response = await http.post(
        Uri.parse("$_baseUrl?key=$_apiKey"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "role": "user",
              "parts": [
                {"text": systemPrompt},
              ],
            },
            ...conversationContext,
            {
              "role": "user",
              "parts": [
                {"text": userInput},
              ],
            },
          ],
          "safetySettings": [
            {
              "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
              "threshold": "BLOCK_ONLY_HIGH",
            },
          ],
          "generationConfig": {
            "temperature": 0.4,
            "maxOutputTokens": 1500,
            "topP": 0.8,
            "topK": 40,
          },
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        final errorMsg =
            "⚠️ **Service Temporarily Unavailable**\n\nPlease try again in a moment.\n\n*Error: ${data['error']?['message'] ?? 'Unknown'}*";
        _addToHistory('assistant', errorMsg);
        return errorMsg;
      }

      final aiResponse =
          data['candidates'][0]['content']['parts'][0]['text'] ??
          "❌ **Processing Error**\n\nI couldn't process your request. Please try again.";

      _addToHistory('assistant', aiResponse);

      // Update user context based on conversation
      _updateUserContext(userInput, aiResponse);

      return aiResponse;
    } catch (e) {
      final errorMsg =
          "🚨 **Connection Error**\n\nPlease check your internet connection and try again.\n\n*Error: ${e.toString()}*";
      _addToHistory('assistant', errorMsg);
      return errorMsg;
    }
  }

  void _updateUserContext(String userInput, String aiResponse) {
    // Extract user preferences and context from conversation
    final lowerInput = userInput.toLowerCase();
    final lowerResponse = aiResponse.toLowerCase();

    if (lowerInput.contains('prefer') ||
        lowerInput.contains('favorite') ||
        lowerInput.contains('usually')) {
      _userContext += "\nUser Preferences: $userInput";
    }

    if (lowerInput.contains('invest') ||
        lowerInput.contains('portfolio') ||
        lowerInput.contains('trading')) {
      _userContext +=
          "\nInvestment Focus: User shows interest in investment strategies";
    }

    if (lowerInput.contains('crypto') ||
        lowerInput.contains('bitcoin') ||
        lowerInput.contains('ethereum')) {
      _userContext +=
          "\nCrypto Interest: User is interested in cryptocurrency markets";
    }

    // Keep context manageable
    if (_userContext.length > 500) {
      _userContext = _userContext.substring(_userContext.length - 500);
    }

    _saveConversationHistory();
  }

  // Get conversation statistics
  Map<String, dynamic> getConversationStats() {
    return {
      'totalInteractions': _conversationCount,
      'conversationHistory': _conversationHistory.length,
      'lastUpdated': _lastUpdated,
      'hasLiveData': _exchangeRates.isNotEmpty,
    };
  }

  // Clear conversation history
  Future<void> clearHistory() async {
    _conversationHistory.clear();
    _conversationCount = 0;
    _userContext = "";
    await _saveConversationHistory();
  }

  // Get quick insights
  Future<String> getQuickInsights() async {
    if (_exchangeRates.isEmpty) {
      await _fetchAllRates();
    }

    return """
🔍 **QUICK MARKET INSIGHTS**

📈 **Top Performers (24h):**
• ${_getTopPerformers()}

📉 **Market Movers:**
• ${_getMarketMovers()}

💡 **Today's Focus:**
• ${_getDailyFocus()}

⏰ **Data as of:** $_lastUpdated
""";
  }

  String _getTopPerformers() {
    // Simulate top performers based on current rates
    return "USD strengthening against emerging markets";
  }

  String _getMarketMovers() {
    return "Central bank announcements expected this week";
  }

  String _getDailyFocus() {
    return "Monitor EUR/USD for ECB policy signals";
  }
}
