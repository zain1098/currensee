// chat_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/news_service.dart';

class ChatService {
  static String? _apiKey;
  static const String _baseUrl =
      "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent";

  // Add real-time currency API
  static const String _currencyApiUrl = "https://open.er-api.com/v6/latest/USD";
  static const String _backupCurrencyApiUrl =
      "https://api.exchangerate-api.com/v4/latest/USD";
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
  bool _isInitialized = false;

  ChatService() {
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      // Load environment variables
      await dotenv.load(fileName: ".env");
      _apiKey = dotenv.env['GEMINI_API_KEY'];

      print("🔑 API Key loaded: ${_apiKey != null ? 'Found' : 'Not found'}");
      print("🔑 API Key value: ${_apiKey ?? 'NULL'}");
      print("🔑 API Key length: ${_apiKey?.length ?? 0}");

      if (_apiKey == null ||
          _apiKey!.isEmpty ||
          _apiKey == 'your_gemini_api_key_here') {
        print(
          "⚠️ Warning: GEMINI_API_KEY not found or not configured properly",
        );
        print("📁 Checking .env file location...");
        // _apiKey = 'YOUR_ACTUAL_API_KEY_HERE'; // Uncomment and add your API key here
        _apiKey = 'DEFAULT_API_KEY'; // Fallback for testing
        print("🔑 Using fallback API key: $_apiKey");
      } else {
        print("✅ Valid API key found and configured");
      }

      _isInitialized = true;

      // Fetch rates immediately
      print("🚀 Initializing exchange rates...");
      await _fetchAllRates();

      // Load conversation history
      await _loadConversationHistory();

      print("✅ ChatService initialized successfully");
      print("💰 Exchange rates loaded: ${_exchangeRates.length} currencies");
      print("📊 Available currencies: ${_exchangeRates.keys.toList()}");
    } catch (e) {
      print("Error initializing ChatService: $e");
      print(
        "This might be because .env file is missing or not in the correct location",
      );
      _isInitialized = true; // Mark as initialized even if there's an error
    }
  }

  Future<void> _fetchAllRates() async {
    try {
      await Future.wait([
        _fetchExchangeRates(),
        _fetchCryptoRates(),
        _fetchGoldRates(),
      ]);
    } catch (e) {
      print("Error fetching rates: $e");
    }
  }

  Future<void> _fetchExchangeRates() async {
    try {
      print("🔄 Fetching exchange rates from: $_currencyApiUrl");
      final response = await http
          .get(Uri.parse(_currencyApiUrl))
          .timeout(const Duration(seconds: 15));

      print("📡 Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("📊 Parsed data keys: ${data.keys.toList()}");

        if (data['result'] == 'success' && data['rates'] != null) {
          _exchangeRates = Map<String, dynamic>.from(data['rates']);
          _lastUpdated =
              data['time_last_update_utc'] ?? DateTime.now().toIso8601String();
          print(
            "✅ Successfully loaded ${_exchangeRates.length} exchange rates",
          );
          print("💰 Sample rates: ${_exchangeRates.entries.take(3).toList()}");
          return; // Success, exit early
        } else {
          print(
            "❌ API returned error: ${data['error-type'] ?? 'Unknown error'}",
          );
        }
      } else {
        print(
          "❌ HTTP Error: ${response.statusCode} - ${response.reasonPhrase}",
        );
      }
    } catch (e) {
      print("❌ Failed to fetch exchange rates: $e");
    }

    // If primary API fails, try backup API
    try {
      print("🔄 Trying backup API: $_backupCurrencyApiUrl");
      final backupResponse = await http
          .get(Uri.parse(_backupCurrencyApiUrl))
          .timeout(const Duration(seconds: 10));

      if (backupResponse.statusCode == 200) {
        final backupData = jsonDecode(backupResponse.body);
        if (backupData['rates'] != null) {
          _exchangeRates = Map<String, dynamic>.from(backupData['rates']);
          _lastUpdated = backupData['date'] ?? DateTime.now().toIso8601String();
          print("✅ Successfully loaded rates from backup API");
          print("💰 Sample rates: ${_exchangeRates.entries.take(3).toList()}");
          return; // Success, exit early
        }
      }
    } catch (backupError) {
      print("❌ Backup API also failed: $backupError");
    }

    // If both APIs fail, use hardcoded fallback rates
    print("🔄 Using hardcoded fallback rates");
    _exchangeRates = {
      'PKR': 278.50,
      'EUR': 0.92,
      'GBP': 0.79,
      'JPY': 150.25,
      'CAD': 1.35,
      'AUD': 1.52,
      'INR': 83.15,
      'CNY': 7.23,
      'AED': 3.67,
      'SAR': 3.75,
    };
    _lastUpdated = DateTime.now().toIso8601String();
    print("✅ Using fallback rates: ${_exchangeRates.length} currencies");
    print("💰 Fallback rates: $_exchangeRates");
  }

  Future<void> _fetchCryptoRates() async {
    try {
      final response = await http
          .get(Uri.parse(_cryptoApiUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        _cryptoRates = jsonDecode(response.body);
      }
    } catch (e) {
      print("Failed to fetch crypto rates: $e");
    }
  }

  Future<void> _fetchGoldRates() async {
    try {
      final response = await http
          .get(Uri.parse(_goldApiUrl))
          .timeout(const Duration(seconds: 10));
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
        final rate = _exchangeRates[currency];
        rates += "• $currency: ${rate.toStringAsFixed(4)}\n";
      }
    }

    // Crypto rates
    if (_cryptoRates.isNotEmpty) {
      rates += "\n🪙 **Cryptocurrencies:**\n";
      if (_cryptoRates['bitcoin'] != null) {
        final btc = _cryptoRates['bitcoin'];
        rates += "• Bitcoin (BTC): \$${btc['usd'].toStringAsFixed(2)}\n";
      }
      if (_cryptoRates['ethereum'] != null) {
        final eth = _cryptoRates['ethereum'];
        rates += "• Ethereum (ETH): \$${eth['usd'].toStringAsFixed(2)}\n";
      }
    }

    // Gold rates
    if (_goldRates.isNotEmpty) {
      rates += "\n🥇 **Gold:**\n";
      rates += "• Price: \$${_goldRates['price'].toStringAsFixed(2)} per oz\n";
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
    if (!_isInitialized) {
      return "🔄 **Initializing...**\n\nPlease wait a moment while I set up my services.";
    }

    _conversationCount++;
    final now = DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy').format(now);
    final formattedTime = DateFormat('HH:mm').format(now);

    print("🔄 Processing user request: '$userInput'");

    // Check if API key is valid for advanced responses
    print("🔑 API Key Status: ${_apiKey != null ? 'Found' : 'Not found'}");
    print("🔑 API Key Value: ${_apiKey ?? 'NULL'}");

    if (_apiKey == null || _apiKey == 'DEFAULT_API_KEY' || _apiKey!.isEmpty) {
      print("⚠️ Using basic response system (no valid API key)");
      // Use basic response system
      final response = await _getBasicResponse(userInput);
      _addToHistory('assistant', response);
      return response;
    }

    print("🚀 Using Gemini AI API for advanced responses");

    // Enhanced system prompt with advanced features
    final systemPrompt = """
You are **CurrenSee AI Assistant**, a helpful and intelligent companion for the CurrenSee app.

🎯 **CORE CAPABILITIES:**

1. **GENERAL ASSISTANCE:**
   • Answer questions about any topic
   • Provide helpful information and guidance
   • Assist with app features and navigation
   • Offer friendly conversation and support

2. **FINANCIAL INTELLIGENCE:**
   • Currency conversion and exchange rates
   • Market insights and trends
   • Investment guidance and tips
   • Financial news and updates

3. **APP SUPPORT:**
   • Help users navigate the CurrenSee app
   • Explain features and functionality
   • Troubleshoot common issues
   • Provide usage tips and best practices

4. **PERSONALIZED EXPERIENCE:**
   • Remember conversation context
   • Adapt to user preferences
   • Provide relevant and helpful responses
   • Maintain friendly and professional tone

📋 **RESPONSE GUIDELINES:**

**IMPORTANT SAFETY RULES:**
• NEVER provide adult content, inappropriate material, or harmful information
• NEVER engage in discussions about illegal activities
• NEVER provide medical, legal, or financial advice that could be harmful
• ALWAYS prioritize user safety and well-being
• If asked about inappropriate topics, politely redirect to appropriate subjects

**For General Questions:**
• Provide accurate, helpful information
• Use clear and simple language
• Include relevant examples when helpful
• Be friendly and engaging

**For Financial Queries:**
• Use real-time data when available
• Provide educational information
• Include risk warnings when appropriate
• Suggest consulting professionals for complex decisions

**For App Support:**
• Guide users through features
• Explain how to use different functions
• Provide troubleshooting steps
• Suggest best practices

**For Casual Conversation:**
• Be friendly and personable
• Use appropriate emojis
• Show personality while staying professional
• Keep responses helpful and relevant

🎨 **RESPONSE FORMATTING:**
• Use clear, readable formatting
• Include relevant emojis for visual appeal
• Format numbers clearly: 1,234.56
• Use bullet points for lists
• Keep responses concise but informative

**Current Financial Data:**
${_formatRates()}

**Conversation Context:**
$_userContext

**Current Session:** Interaction #$_conversationCount
**Date:** $formattedDate | **Time:** $formattedTime UTC
**Data Freshness:** ${_lastUpdated.isNotEmpty ? 'Live' : 'Cached'}

Remember: You are a helpful assistant for the CurrenSee app. Focus on being useful, safe, and user-friendly.
""";

    try {
      // Check if API key is valid for advanced responses
      if (_apiKey == null || _apiKey == 'DEFAULT_API_KEY') {
        // Use basic response system
        final response = await _getBasicResponse(userInput);
        _addToHistory('assistant', response);
        return response;
      }

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

      print("🌐 Making Gemini API call...");
      print("🌐 API URL: $_baseUrl");
      print(
        "🌐 Request body length: ${jsonEncode({
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
            {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_ONLY_HIGH"},
          ],
          "generationConfig": {"temperature": 0.7, "maxOutputTokens": 1500, "topP": 0.9, "topK": 40},
        }).length} characters",
      );

      final response = await http
          .post(
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
                "temperature": 0.7,
                "maxOutputTokens": 1500,
                "topP": 0.9,
                "topK": 40,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      print("📡 Gemini API Response Status: ${response.statusCode}");
      print(
        "📡 Gemini API Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...",
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        final errorMsg =
            "⚠️ **Service Temporarily Unavailable**\n\nI'm having trouble connecting to my AI service right now. Please try again in a moment.\n\n*Error: ${data['error']?['message'] ?? 'Unknown'}*";
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
      print("ChatService error: $e");
      final errorMsg =
          "🚨 **Connection Error**\n\nI'm having trouble connecting right now. This might be due to:\n\n• Internet connection issues\n• Service temporarily unavailable\n• Configuration problems\n\n*Error: ${e.toString()}*\n\nPlease try again in a moment! 🔄";
      _addToHistory('assistant', errorMsg);
      return errorMsg;
    }
  }

  // Basic responses without API - Now with smart detection
  Future<String> _getBasicResponse(String userInput) async {
    print("🔄 Processing user input: '$userInput'");

    // Handle special test commands first
    if (userInput.toLowerCase().contains('test api key')) {
      return testApiKeyStatus();
    }

    if (userInput.toLowerCase().contains('test rates')) {
      return testRates();
    }

    if (userInput.toLowerCase().contains('test detection')) {
      final testInput = userInput.replaceAll(
        RegExp(r'test detection\s*', caseSensitive: false),
        '',
      );
      if (testInput.isNotEmpty) {
        return testCurrencyDetection(testInput);
      }
      return testCurrencyDetection("100 USD to PKR");
    }

    // First, try to detect if it's a currency conversion request
    final amount = _extractAmount(userInput);
    final fromCurrency = _extractCurrency(userInput, 'from');
    final toCurrency = _extractCurrency(userInput, 'to');

    print(
      "📊 Extracted data: Amount=$amount, From=$fromCurrency, To=$toCurrency",
    );

    // If we have valid conversion data, process it
    if (amount > 0 && fromCurrency.isNotEmpty && toCurrency.isNotEmpty) {
      print("✅ Valid conversion request detected");
      return _calculateConversion(amount, fromCurrency, toCurrency);
    }

    // If we have amount but missing currencies, provide helpful response
    if (amount > 0 && (fromCurrency.isEmpty || toCurrency.isEmpty)) {
      return """💱 **Currency Conversion Help**

I detected an amount ($amount) but need to know the currencies to convert.

**Examples:**
• "Convert $amount USD to PKR"
• "$amount dollars in rupees"
• "Exchange $amount EUR to USD"

${_formatRates()}

*For advanced AI responses, please configure your API key.*""";
    }

    // Handle specific financial queries
    final lowerInput = userInput.toLowerCase();

    // Bitcoin/Crypto queries
    if (lowerInput.contains('bitcoin') ||
        lowerInput.contains('btc') ||
        lowerInput.contains('crypto')) {
      return _getCryptoResponse();
    }

    // Gold queries
    if (lowerInput.contains('gold') ||
        lowerInput.contains('silver') ||
        lowerInput.contains('precious metal')) {
      return _getGoldResponse();
    }

    // News queries
    if (lowerInput.contains('news') ||
        lowerInput.contains('trending') ||
        lowerInput.contains('latest')) {
      return await _getNewsResponse();
    }

    // Market queries
    if (lowerInput.contains('market') ||
        lowerInput.contains('stock') ||
        lowerInput.contains('investment')) {
      return _getMarketResponse();
    }

    // General financial advice
    if (lowerInput.contains('advice') ||
        lowerInput.contains('help') ||
        lowerInput.contains('guide')) {
      return _getFinancialAdviceResponse();
    }

    // For all other queries, provide a comprehensive response
    return """🤖 **CurrenSee AI Assistant**

Hi! I'm your helpful assistant for the CurrenSee app. I can help you with:

💡 **General Assistance:**
• Answer questions about any topic
• Provide helpful information and guidance
• Assist with app features and navigation
• Offer friendly conversation and support

💱 **Financial Information:**
• Currency conversion and exchange rates
• Market insights and trends
• Investment guidance and tips
• Financial news and updates

📱 **App Support:**
• Help you navigate the CurrenSee app
• Explain features and functionality
• Troubleshoot common issues
• Provide usage tips and best practices

${_formatRates()}

**Examples of what I can help with:**
• "How do I convert currencies?"
• "What's the current Bitcoin price?"
• "Tell me about the app features"
• "Help me with investment tips"
• "What's the latest financial news?"
• "How do I use the calculator?"

**Test Commands:**
• "test api key" - Check API key status
• "test rates" - Check exchange rates
• "test detection 100 USD to PKR" - Test currency detection

*For advanced AI responses and real-time analysis, please configure your Gemini API key in the .env file.*""";
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

  // Test method to check rates
  String testRates() {
    return """
🧪 **RATES TEST RESULTS**

📊 **Total Currencies:** ${_exchangeRates.length}
💰 **Available Currencies:** ${_exchangeRates.keys.toList()}
⏰ **Last Updated:** $_lastUpdated

📈 **Sample Rates:**
${_exchangeRates.entries.take(5).map((e) => "• ${e.key}: ${e.value}").join('\n')}

🔍 **Status:** ${_exchangeRates.isNotEmpty ? '✅ Working' : '❌ Not Working'}
""";
  }

  // Test method for currency detection
  String testCurrencyDetection(String input) {
    final amount = _extractAmount(input);
    final fromCurrency = _extractCurrency(input, 'from');
    final toCurrency = _extractCurrency(input, 'to');

    return """
🧪 **CURRENCY DETECTION TEST**

📝 **Input:** "$input"
💰 **Amount:** $amount
🔄 **From Currency:** $fromCurrency
🎯 **To Currency:** $toCurrency

📊 **Detection Result:** ${amount > 0 && fromCurrency.isNotEmpty && toCurrency.isNotEmpty ? '✅ Valid' : '❌ Invalid'}
""";
  }

  // Test method for API key status
  String testApiKeyStatus() {
    return """
🔑 **API KEY STATUS TEST**

📊 **API Key Found:** ${_apiKey != null ? '✅ Yes' : '❌ No'}
🔑 **API Key Value:** ${_apiKey ?? 'NULL'}
🔑 **API Key Length:** ${_apiKey?.length ?? 0}
🔑 **Is Default Key:** ${_apiKey == 'DEFAULT_API_KEY' ? '✅ Yes' : '❌ No'}
🔑 **Is Empty:** ${_apiKey?.isEmpty ?? true ? '✅ Yes' : '❌ No'}

📋 **Status:** ${_apiKey != null && _apiKey != 'DEFAULT_API_KEY' && _apiKey!.isNotEmpty ? '✅ Valid API Key' : '❌ Invalid/No API Key'}

💡 **Note:** If API key is invalid, the app will use basic responses.

📁 **To fix API key issue:**
1. Create a `.env` file in your project root
2. Add: `GEMINI_API_KEY=your_actual_api_key_here`
3. Get API key from: https://makersuite.google.com/app/apikey
4. Restart the app

🔄 **Current Mode:** ${_apiKey != null && _apiKey != 'DEFAULT_API_KEY' && _apiKey!.isNotEmpty ? 'Advanced AI Mode' : 'Basic Mode'}
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

  // Crypto response method
  String _getCryptoResponse() {
    String response = """🪙 **Cryptocurrency Information**

${_cryptoRates.isNotEmpty ? _formatCryptoRates() : "📊 **Current Crypto Rates:**\n• Bitcoin (BTC): ~\$43,500\n• Ethereum (ETH): ~\$2,600"}

💡 **Quick Facts:**
• Bitcoin is the world's first cryptocurrency
• Ethereum enables smart contracts
• Crypto markets are highly volatile
• Always do your own research before investing

⚠️ **Risk Warning:**
• Cryptocurrency investments are risky
• Prices can change rapidly
• Only invest what you can afford to lose

${_formatRates()}""";

    return response;
  }

  // Gold response method
  String _getGoldResponse() {
    String response = """🥇 **Precious Metals Information**

${_goldRates.isNotEmpty ? _formatGoldRates() : "📊 **Current Gold Rate:**\n• Gold: ~\$2,050 per ounce"}

💡 **Investment Insights:**
• Gold is a traditional safe-haven asset
• Often performs well during economic uncertainty
• Considered a hedge against inflation
• Physical gold vs. paper gold options

📈 **Market Factors:**
• Central bank policies
• Inflation expectations
• Currency strength
• Geopolitical tensions

${_formatRates()}""";

    return response;
  }

  // News response method
  Future<String> _getNewsResponse() async {
    try {
      final news = await NewsService.getFinancialNews();
      return NewsService.formatNewsForChat(news);
    } catch (e) {
      return """📰 **Financial News & Updates**

🔔 **Latest Market Headlines:**
• Federal Reserve policy updates
• Global economic indicators
• Currency market movements
• Commodity price trends

📊 **Current Market Status:**
• USD showing mixed performance
• European markets stable
• Asian markets active
• Commodity prices fluctuating

💡 **Stay Informed:**
• Follow reliable financial news sources
• Monitor central bank announcements
• Track economic indicators
• Watch for market-moving events

${_formatRates()}

*For real-time news and detailed analysis, please configure your API key for advanced features.*""";
    }
  }

  // Market response method
  String _getMarketResponse() {
    return """📈 **Market Analysis & Insights**

📊 **Current Market Overview:**
• Global markets showing mixed trends
• Currency volatility in emerging markets
• Commodity prices stabilizing
• Interest rate expectations shifting

💡 **Investment Strategies:**
• Diversify across asset classes
• Consider long-term investment horizons
• Monitor risk tolerance levels
• Stay updated with market trends

📋 **Key Market Indicators:**
• Currency exchange rates
• Commodity prices
• Interest rate movements
• Economic growth data

${_formatRates()}

*For detailed market analysis and personalized investment advice, please configure your API key.*""";
  }

  // Financial advice response method
  String _getFinancialAdviceResponse() {
    return """💡 **Financial Guidance & Tips**

🎯 **Basic Investment Principles:**
• Start early and invest regularly
• Diversify your portfolio
• Understand your risk tolerance
• Focus on long-term goals

💰 **Currency & Exchange Tips:**
• Monitor exchange rates regularly
• Consider timing for large conversions
• Be aware of transaction fees
• Use reliable exchange services

📚 **Financial Education:**
• Learn about different asset classes
• Understand market fundamentals
• Stay informed about economic trends
• Consider professional advice when needed

⚠️ **Important Disclaimers:**
• This is general information only
• Not financial advice
• Always do your own research
• Consider consulting financial professionals

${_formatRates()}

*For personalized financial advice and detailed analysis, please configure your API key.*""";
  }

  // Format crypto rates
  String _formatCryptoRates() {
    if (_cryptoRates.isEmpty) return "";

    String rates = "📊 **Current Crypto Rates:**\n";

    if (_cryptoRates['bitcoin'] != null) {
      final btc = _cryptoRates['bitcoin'];
      rates += "• Bitcoin (BTC): \$${btc['usd'].toStringAsFixed(2)}\n";
    }

    if (_cryptoRates['ethereum'] != null) {
      final eth = _cryptoRates['ethereum'];
      rates += "• Ethereum (ETH): \$${eth['usd'].toStringAsFixed(2)}\n";
    }

    return rates;
  }

  // Format gold rates
  String _formatGoldRates() {
    if (_goldRates.isEmpty) return "";

    return "📊 **Current Gold Rate:**\n• Gold: \$${_goldRates['price'].toStringAsFixed(2)} per ounce";
  }

  // Extract amount from user input
  double _extractAmount(String input) {
    final regex = RegExp(r'(\d+(?:\.\d+)?)');
    final match = regex.firstMatch(input);
    if (match != null) {
      final amount = double.tryParse(match.group(1)!) ?? 0.0;
      print("✅ Extracted amount: $amount from '$input'");
      return amount;
    }
    print("❌ No amount found in input: '$input'");
    return 0.0;
  }

  // Extract currency codes from user input - Enhanced detection
  String _extractCurrency(String input, String type) {
    final upperInput = input.toUpperCase();
    print("🔍 Extracting currency from: '$upperInput' (type: $type)");

    // Enhanced currency patterns with multiple languages and variations
    final currencies = {
      'USD': [
        'USD',
        'DOLLAR',
        'DOLLARS',
        'US DOLLAR',
        'DOLLAR',
        'AMERICAN DOLLAR',
        'US DOLLARS',
        'AMERICAN DOLLARS',
        'DOLLAR',
        'DOLLARS',
      ],
      'PKR': [
        'PKR',
        'RUPEE',
        'RUPEE',
        'PAKISTANI RUPEE',
        'PAKISTANI',
        'PAKISTAN RUPEE',
        'PAKISTANI RUPEE',
        'PAK RUPEE',
        'PAK RUPEE',
        'RS',
        'RUPEE',
      ],
      'EUR': ['EUR', 'EURO', 'EUROS', 'EUROPEAN EURO', 'EUROPEAN EUROS'],
      'GBP': [
        'GBP',
        'POUND',
        'POUNDS',
        'BRITISH POUND',
        'BRITISH',
        'BRITISH POUNDS',
        'STERLING',
        'STERLING POUND',
        'STERLING POUNDS',
      ],
      'INR': [
        'INR',
        'INDIAN RUPEE',
        'INDIAN',
        'INDIA RUPEE',
        'INDIAN RUPEE',
        'INDIA RUPEE',
        'INDIAN RS',
        'INDIA RS',
      ],
      'CNY': [
        'CNY',
        'YUAN',
        'CHINESE YUAN',
        'CHINESE',
        'CHINA YUAN',
        'RENMINBI',
        'RMB',
      ],
      'JPY': ['JPY', 'YEN', 'JAPANESE YEN', 'JAPANESE', 'JAPAN YEN'],
      'CAD': [
        'CAD',
        'CANADIAN DOLLAR',
        'CANADIAN',
        'CANADA DOLLAR',
        'CANADIAN DOLLARS',
        'CANADA DOLLARS',
      ],
      'AUD': [
        'AUD',
        'AUSTRALIAN DOLLAR',
        'AUSTRALIAN',
        'AUSTRALIA DOLLAR',
        'AUSTRALIAN DOLLARS',
        'AUSTRALIA DOLLARS',
      ],
      'AED': [
        'AED',
        'DIRHAM',
        'DIRHAMS',
        'UAE DIRHAM',
        'UAE DIRHAMS',
        'EMIRATI DIRHAM',
        'EMIRATI DIRHAMS',
      ],
      'SAR': [
        'SAR',
        'RIYAL',
        'RIYALS',
        'SAUDI RIYAL',
        'SAUDI RIYALS',
        'SAUDI ARABIA RIYAL',
        'SAUDI ARABIA RIYALS',
      ],
    };

    // For 'from' currency, look for first occurrence
    // For 'to' currency, look for second occurrence
    List<String> foundCurrencies = [];

    for (final entry in currencies.entries) {
      for (final pattern in entry.value) {
        if (upperInput.contains(pattern)) {
          foundCurrencies.add(entry.key);
          print("✅ Found currency: ${entry.key} (pattern: '$pattern')");
        }
      }
    }

    // If no exact match, try partial matches for common words
    if (upperInput.contains('DOLLAR') && !foundCurrencies.contains('USD')) {
      foundCurrencies.add('USD');
      print("✅ Found currency: USD (partial match)");
    }

    if ((upperInput.contains('RUPEE') || upperInput.contains('RS')) &&
        !foundCurrencies.contains('PKR')) {
      foundCurrencies.add('PKR');
      print("✅ Found currency: PKR (partial match)");
    }

    // Remove duplicates and return appropriate currency
    foundCurrencies = foundCurrencies.toSet().toList();
    print("🔍 All found currencies: $foundCurrencies");

    if (foundCurrencies.isEmpty) {
      print("❌ No currency found in input: '$upperInput'");
      return '';
    }

    // For 'from' currency, return first found
    // For 'to' currency, return second found (if available)
    if (type == 'from') {
      final result = foundCurrencies.first;
      print("✅ Returning 'from' currency: $result");
      return result;
    } else if (type == 'to') {
      final result =
          foundCurrencies.length > 1
              ? foundCurrencies[1]
              : foundCurrencies.first;
      print("✅ Returning 'to' currency: $result");
      return result;
    }

    print("❌ Invalid type: $type");
    return '';
  }

  // Calculate currency conversion
  String _calculateConversion(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) {
    print("🔄 Calculating conversion: $amount $fromCurrency to $toCurrency");
    print("💰 Available rates: ${_exchangeRates.keys.toList()}");
    print("💰 Exchange rates map: $_exchangeRates");

    if (_exchangeRates.isEmpty) {
      print("❌ No exchange rates available");
      // Force reload rates
      _fetchExchangeRates();
      return "🔄 **Loading rates...**\n\nPlease try again in a moment.";
    }

    print("✅ Exchange rates loaded: ${_exchangeRates.length} currencies");

    // If converting from USD
    if (fromCurrency == 'USD' && _exchangeRates.containsKey(toCurrency)) {
      final rate = _exchangeRates[toCurrency];
      final convertedAmount = amount * rate;

      print(
        "✅ Conversion successful: $amount USD = ${convertedAmount.toStringAsFixed(2)} $toCurrency",
      );

      return """💱 **Currency Conversion Result**

**$amount USD = ${convertedAmount.toStringAsFixed(2)} $toCurrency**

📊 **Current Rate:** 1 USD = ${rate.toStringAsFixed(4)} $toCurrency
⏰ **Updated:** $_lastUpdated

💡 **Quick Info:**
• This is the current market rate
• Rates may vary by bank/exchange
• Consider transaction fees""";
    }

    // If converting to USD
    if (toCurrency == 'USD' && _exchangeRates.containsKey(fromCurrency)) {
      final rate = _exchangeRates[fromCurrency];
      final convertedAmount = amount / rate;

      print(
        "✅ Conversion successful: $amount $fromCurrency = ${convertedAmount.toStringAsFixed(2)} USD",
      );

      return """💱 **Currency Conversion Result**

**$amount $fromCurrency = ${convertedAmount.toStringAsFixed(2)} USD**

📊 **Current Rate:** 1 $fromCurrency = ${(1 / rate).toStringAsFixed(4)} USD
⏰ **Updated:** $_lastUpdated

💡 **Quick Info:**
• This is the current market rate
• Rates may vary by bank/exchange
• Consider transaction fees""";
    }

    // For other currency pairs, show available rates
    print("❌ Currency pair not supported: $fromCurrency to $toCurrency");
    return """💱 **Currency Conversion**

I can help you convert between USD and other currencies.

**Available Conversions:**
${_formatRates()}

**Example:** "Convert 100 USD to PKR"

*For other currency pairs, please configure your API key for advanced features.*""";
  }
}
