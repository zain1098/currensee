// currency_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'chat_service.dart';
import 'voice_service.dart';

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
  bool _showPrompts = false;

  // Ready-made prompts for common user needs
  final List<Map<String, String>> _readyPrompts = [
    {
      'title': 'Currency Conversion',
      'prompt': 'Convert 100 USD to PKR',
      'icon': '💱',
    },
    {
      'title': 'Bitcoin Price',
      'prompt': 'What is the current Bitcoin price?',
      'icon': '🪙',
    },
    {
      'title': 'Gold Rates',
      'prompt': 'Tell me about current gold rates',
      'icon': '🥇',
    },
    {
      'title': 'Market News',
      'prompt': 'What are the latest financial news?',
      'icon': '📰',
    },
    {
      'title': 'Investment Tips',
      'prompt': 'Give me some investment advice',
      'icon': '💡',
    },
    {
      'title': 'App Features',
      'prompt': 'What features does this app have?',
      'icon': '📱',
    },
    {
      'title': 'Calculator Help',
      'prompt': 'How do I use the calculator feature?',
      'icon': '🧮',
    },
    {
      'title': 'Rate Comparison',
      'prompt': 'Compare USD, EUR, and GBP rates',
      'icon': '📊',
    },
  ];

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
        'text': """🎉 **Welcome to CurrenSee AI Assistant!**

I'm your helpful companion for the CurrenSee app. Here's what I can help you with:

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

🎤 **Voice Features:**
• Speak to me in your language
• I'll respond in clear English
• Voice input and output support
• Multi-language recognition

Try asking me anything like:
• "How do I convert currencies?"
• "What's the current Bitcoin price?"
• "Tell me about the app features"
• "Help me with investment tips"

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
                  PopupMenuItem(
                    value: 'history',
                    child: Row(
                      children: [
                        Icon(Icons.history, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Clear History'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
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
        ],
      ),
      body: Column(
        children: [
          if (_showInsights)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Quick Insights',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
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
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
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
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(message, theme),
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

  void _showMessageOptions(Map<String, dynamic> message, ThemeData theme) {
    final isUser = message['isUser'] ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.copy, color: theme.colorScheme.primary),
                  title: Text(
                    'Copy Message',
                    style: TextStyle(color: theme.textTheme.titleMedium?.color),
                  ),
                  onTap: () {
                    _copyMessage(message['text']);
                    Navigator.pop(context);
                  },
                ),
                if (isUser)
                  ListTile(
                    leading: Icon(Icons.edit, color: theme.colorScheme.primary),
                    title: Text(
                      'Edit Message',
                      style: TextStyle(
                        color: theme.textTheme.titleMedium?.color,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _editMessage(message);
                    },
                  ),
                ListTile(
                  leading: Icon(Icons.share, color: theme.colorScheme.primary),
                  title: Text(
                    'Share Message',
                    style: TextStyle(color: theme.textTheme.titleMedium?.color),
                  ),
                  onTap: () {
                    _shareMessage(message['text']);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
    );
  }

  void _copyMessage(String text) {
    // Copy to clipboard using Flutter's built-in clipboard
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Message copied to clipboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _editMessage(Map<String, dynamic> message) {
    final isUser = message['isUser'] ?? false;
    if (!isUser) return;

    _textController.text = message['text'];
    setState(() {
      _messages.remove(message);
    });

    // Focus on text field for editing
    FocusScope.of(context).requestFocus(FocusNode());
    Future.delayed(const Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  void _shareMessage(String text) {
    // Share message using share_plus package
    Share.share(text, subject: 'CurrenSee AI Chat');
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
            'CurrenSee AI is thinking...',
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
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            title: Text(
              'Conversation Statistics',
              style: TextStyle(color: theme.textTheme.titleLarge?.color),
            ),
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
                child: Text(
                  'Close',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
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
    return Column(
      children: [
        // Ready-made prompts section
        if (_showPrompts) _buildPromptsSection(theme, chatService),

        // Voice preview
        if (_voicePreview.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.mic, color: theme.colorScheme.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _voicePreview,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Main input area
        Container(
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
              // Prompts button
              IconButton(
                onPressed: () => setState(() => _showPrompts = !_showPrompts),
                icon: Icon(
                  _showPrompts
                      ? Icons.keyboard_arrow_down
                      : Icons.lightbulb_outline,
                  color: theme.colorScheme.primary,
                ),
                tooltip: 'Quick Prompts',
              ),

              // Voice button
              IconButton(
                onPressed: () => _toggleListening(voiceService, chatService),
                icon: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  color:
                      _isListening
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                ),
                tooltip: 'Voice Input',
              ),

              // Text input
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Ask me anything...',
                    hintStyle: TextStyle(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.6,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (text) => _sendMessage(text, chatService),
                ),
              ),

              const SizedBox(width: 8),

              // Send button
              IconButton(
                onPressed:
                    () => _sendMessage(_textController.text, chatService),
                icon: Icon(Icons.send),
                color: theme.colorScheme.primary,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromptsSection(ThemeData theme, ChatService chatService) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 Quick Prompts',
            style: TextStyle(
              color: theme.textTheme.titleSmall?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _readyPrompts.length,
              itemBuilder: (context, index) {
                final prompt = _readyPrompts[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      _textController.text = prompt['prompt']!;
                      setState(() => _showPrompts = false);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            prompt['icon']!,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            prompt['title']!,
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
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

      // Voice response removed - bot will not speak
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
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            title: Text(
              'Clear Chat History',
              style: TextStyle(color: theme.textTheme.titleLarge?.color),
            ),
            content: Text(
              'Are you sure you want to clear all chat history?',
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
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
                child: Text(
                  'Clear',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
    );
  }

  void _showAISettings() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            title: Text(
              'AI Assistant Settings',
              style: TextStyle(color: theme.textTheme.titleLarge?.color),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Advanced settings coming soon!',
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 16),
                Text(
                  'Features in development:\n• Response style customization\n• Language preferences\n• Detail level control\n• Specialized knowledge areas',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
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
        _voicePreview = "Listening... Speak now";
      });

      await voiceService.startListening(
        (finalResult) async {
          setState(() {
            _isListening = false;
            _voicePreview = "";
            _lastVoiceInput = finalResult;
          });

          if (finalResult.isNotEmpty) {
            // Show detected language
            final detectedLang = voiceService.detectedLanguage;
            final langName = voiceService.languageDisplayName;

            setState(() {
              _voicePreview = "Detected: $langName - $finalResult";
            });

            // Clear preview after 2 seconds
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  _voicePreview = "";
                });
              }
            });

            await _sendMessage(finalResult, chatService);
          }
        },
        (partialResult) {
          setState(() {
            _voicePreview = "Listening: $partialResult";
          });
        },
      );
    }
  }
}
