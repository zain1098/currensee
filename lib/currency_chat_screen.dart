// currency_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_service.dart';
import 'voice_service.dart';
import 'app_theme.dart';

class CurrencyChatScreen extends StatefulWidget {
  const CurrencyChatScreen({super.key});

  @override
  _CurrencyChatScreenState createState() => _CurrencyChatScreenState();
}

class _CurrencyChatScreenState extends State<CurrencyChatScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  bool _isListening = false;
  String _lastVoiceInput = '';
  String _voicePreview = "";
  final ScrollController _scrollController = ScrollController();
  bool _showInsights = false;

  @override
  void initState() {
    super.initState();
    // Initialize voice permissions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VoiceService>(context, listen: false).initPermissions();
    });

    // Add welcome message
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add({
        'text': """🎉 **Welcome to CurrencyPro Ultra AI!**

I'm your advanced financial intelligence assistant. Here's what I can help you with:

💱 **Currency Operations:**
• Real-time exchange rates
• Multi-currency conversions
• Historical rate analysis
• Conversion fee calculations

📊 **Market Intelligence:**
• Live crypto prices (BTC, ETH)
• Gold and commodity rates
• Market trend analysis
• Economic indicators

💡 **Smart Features:**
• Voice input support
• Conversation memory
• Personalized insights
• Investment guidance

Try asking me anything like:
• "Convert 1000 USD to PKR"
• "Show me current Bitcoin price"
• "What's the EUR/USD trend?"
• "Give me market insights"

I remember our conversations and adapt to your preferences! 🚀""",
        'isUser': false,
        'isWelcome': true,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final voiceService = Provider.of<VoiceService>(context);
    final chatService = Provider.of<ChatService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CurrencyPro Ultra'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () => _toggleInsights(chatService),
            tooltip: 'Quick Insights',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showConversationStats(chatService),
            tooltip: 'Conversation Stats',
          ),
          PopupMenuButton<String>(
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'history',
                    child: Row(
                      children: [
                        Icon(Icons.history, color: Color(0xFF1E3A8A)),
                        SizedBox(width: 8),
                        Text('Clear History'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, color: Color(0xFF1E3A8A)),
                        SizedBox(width: 8),
                        Text('AI Settings'),
                      ],
                    ),
                  ),
                ],
            onSelected: (value) {
              switch (value) {
                case 'history':
                  _clearChat(chatService);
                  break;
                case 'settings':
                  _showAISettings();
                  break;
              }
            },
          ),
          IconButton(
            icon:
                _isListening
                    ? const Icon(Icons.mic, color: Colors.red, size: 30)
                    : const Icon(Icons.mic_none),
            onPressed: () => _toggleListening(voiceService, chatService),
            tooltip: 'Voice input',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showInsights)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 Quick Insights',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<String>(
                    future: chatService.getQuickInsights(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }
                      return Text(
                        snapshot.data ?? 'Loading insights...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessage(message);
              },
            ),
          ),
          if (_isLoading) _buildLoadingIndicator(),
          _buildInputArea(voiceService, chatService),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final theme = Theme.of(context);
    final isUser = message['isUser'] ?? false;
    final isWelcome = message['isWelcome'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy,
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
            ),
          if (!isUser) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isUser
                        ? theme.colorScheme.primary
                        : isWelcome
                        ? theme.colorScheme.secondary
                        : theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message['text'],
                style: TextStyle(
                  color:
                      isUser || isWelcome
                          ? theme.colorScheme.onPrimary
                          : theme.textTheme.bodyLarge?.color,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: theme.colorScheme.onSecondary,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'CurrencyPro is thinking...',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleInsights(ChatService chatService) {
    setState(() {
      _showInsights = !_showInsights;
    });
  }

  void _showConversationStats(ChatService chatService) {
    final stats = chatService.getConversationStats();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Conversation Statistics'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatItem(
                    'Total Interactions',
                    '${stats['totalInteractions']}',
                  ),
                  _buildStatItem(
                    'Conversation History',
                    '${stats['conversationHistory']} messages',
                  ),
                  _buildStatItem(
                    'Data Status',
                    stats['hasLiveData'] ? '🟢 Live' : '🟡 Cached',
                  ),
                  _buildStatItem(
                    'Last Updated',
                    stats['lastUpdated'] ?? 'Unknown',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(color: theme.colorScheme.primary)),
        ],
      ),
    );
  }

  Widget _buildInputArea(VoiceService voiceService, ChatService chatService) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Ask me about currencies, rates, or markets...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (text) => _sendMessage(text, chatService),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _sendMessage(_textController.text, chatService),
            icon: Icon(Icons.send),
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text, ChatService chatService) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'text': text, 'isUser': true});
      _isLoading = true;
    });

    _textController.clear();
    _scrollToBottom();

    try {
      final response = await chatService.getCurrencyResponse(text);
      setState(() {
        _messages.add({'text': response, 'isUser': false});
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'text': 'Sorry, I encountered an error. Please try again.',
          'isUser': false,
        });
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat(ChatService chatService) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Chat History'),
            content: const Text(
              'Are you sure you want to clear all chat history?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  chatService.clearHistory();
                  setState(() {
                    _messages.clear();
                  });
                  _addWelcomeMessage();
                  Navigator.pop(context);
                },
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }

  void _showAISettings() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('AI Assistant Settings'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Advanced settings coming soon!'),
                SizedBox(height: 16),
                Text(
                  'Features in development:\n• Response style customization\n• Language preferences\n• Detail level control\n• Specialized knowledge areas',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _toggleListening(
    VoiceService voiceService,
    ChatService chatService,
  ) async {
    if (_isListening) {
      await voiceService.stopListening();
      setState(() {
        _isListening = false;
        _voicePreview = "";
      });
    } else {
      setState(() {
        _isListening = true;
        _voicePreview = "Listening...";
      });

      await voiceService.startListening(
        (finalResult) {
          // Final result callback
          setState(() {
            _lastVoiceInput = finalResult;
            _voicePreview = "Heard: $finalResult";
            _isListening = false;
          });

          // Send the voice input as a message
          _sendMessage(finalResult, chatService);
        },
        (partialResult) {
          // Partial result callback
          setState(() {
            _voicePreview = partialResult;
          });
        },
      );
    }
  }
}
