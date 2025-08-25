// currency_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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

Hi there! I'm your friendly financial assistant. Let's make finance fun and easy! 😊

💱 **What I can help you with:**
• Real-time currency rates and conversions
• Live crypto prices (Bitcoin, Ethereum)
• Gold and commodity rates
• Market trends and insights
• Investment advice and analysis

💡 **Smart Features:**
• Voice conversations (just tap the mic!)
• Remembers our chats
• Personalized insights
• Casual conversation too!

🎯 **Try asking me:**
• "Convert 1000 USD to PKR"
• "How's Bitcoin doing today?"
• "Tell me a financial joke"
• "What's the weather like?" (I'll redirect to financial weather! 😄)

I'm here to chat about anything, but I'm especially good with money stuff! 💰

What would you like to know? 🚀""",
        'isUser': false,
        'isWelcome': true,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final voiceService = Provider.of<VoiceService>(context);
    final chatService = Provider.of<ChatService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CurrencyPro Ultra'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                         Icon(Icons.history),
                         SizedBox(width: 8),
                         Text('Clear History'),
                       ],
                     ),
                   ),
                   const PopupMenuItem(
                     value: 'settings',
                     child: Row(
                       children: [
                         Icon(Icons.settings),
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
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Quick Insights',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<String>(
                    future: chatService.getQuickInsights(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        );
                      }
                      return Text(
                        snapshot.data ?? 'Loading insights...',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
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
    final isUser = message['isUser'] ?? false;
    final isWelcome = message['isWelcome'] ?? false;
    final voiceService = Provider.of<VoiceService>(context);

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
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20,
              ),
            ),
          if (!isUser) const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isUser
                            ? Theme.of(context).colorScheme.primary
                            : isWelcome
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message['text'],
                    style: TextStyle(
                      color:
                          isUser || isWelcome
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Action buttons for messages
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // User message actions (Edit & Copy)
                      if (isUser)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Edit button for user messages
                            InkWell(
                              onTap: () => _editUserMessage(message),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.tertiary,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.tertiary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Edit',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.tertiary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Copy button for user messages
                            InkWell(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: message['text']),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Message copied to clipboard'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.secondary,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.copy,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Copy',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.secondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      // AI response actions (Speak & Copy)
                      if (!isUser && !isWelcome)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Speak button
                            InkWell(
                              onTap: () {
                                if (voiceService.isSpeaking) {
                                  voiceService.stopSpeaking();
                                } else {
                                  voiceService.speakResponse(message['text']);
                                }
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      voiceService.isSpeaking
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.error.withOpacity(0.1)
                                          : Theme.of(
                                            context,
                                          ).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        voiceService.isSpeaking
                                            ? Theme.of(context).colorScheme.error
                                            : Theme.of(context).colorScheme.primary,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      voiceService.isSpeaking
                                          ? Icons.stop
                                          : Icons.volume_up,
                                      size: 16,
                                      color:
                                          voiceService.isSpeaking
                                              ? Theme.of(context).colorScheme.error
                                              : Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      voiceService.isSpeaking ? 'Stop' : 'Speak',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            voiceService.isSpeaking
                                                ? Theme.of(
                                                  context,
                                                ).colorScheme.error
                                                : Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Copy button for AI responses
                            InkWell(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: message['text']),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Response copied to clipboard'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.secondary,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.copy,
                                      size: 16,
                                      color:
                                          Theme.of(context).colorScheme.secondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Copy',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            Theme.of(context).colorScheme.secondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.onSecondary,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
                     Text(
             'CurrencyPro is thinking... 🤔',
             style: TextStyle(
               color:
                   Theme.of(context).brightness == Brightness.dark
                       ? Colors.white70
                       : Colors.grey[600],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(VoiceService voiceService, ChatService chatService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
                     // Voice preview indicator with language detection
           if (_isListening || _voicePreview.isNotEmpty)
             Container(
               width: double.infinity,
               padding: const EdgeInsets.all(12),
               margin: const EdgeInsets.only(bottom: 8),
               decoration: BoxDecoration(
                 color:
                     _isListening
                         ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                         : Colors.green.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(
                   color:
                       _isListening
                           ? Theme.of(context).colorScheme.primary
                           : Colors.green,
                   width: 1,
                 ),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     children: [
                       Icon(
                         _isListening ? Icons.mic : Icons.check_circle,
                         color:
                             _isListening
                                 ? Theme.of(context).colorScheme.primary
                                 : Colors.green,
                         size: 20,
                       ),
                       const SizedBox(width: 8),
                       Expanded(
                         child: Text(
                           _isListening ? 'Listening...' : _voicePreview,
                           style: TextStyle(
                             color:
                                 _isListening
                                     ? Theme.of(context).colorScheme.primary
                                     : Colors.green,
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                       ),
                       if (_isListening)
                         SizedBox(
                           width: 16,
                           height: 16,
                           child: CircularProgressIndicator(
                             strokeWidth: 2,
                             valueColor: AlwaysStoppedAnimation<Color>(
                               Theme.of(context).colorScheme.primary,
                             ),
                           ),
                         ),
                     ],
                   ),
                   // Language indicator
                   if (!_isListening && voiceService.languageDisplayName != 'English')
                     Container(
                       margin: const EdgeInsets.only(top: 8),
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                       decoration: BoxDecoration(
                         color: Colors.blue.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(8),
                         border: Border.all(color: Colors.blue.withOpacity(0.3)),
                       ),
                       child: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Icon(
                             Icons.language,
                             size: 14,
                             color: Colors.blue,
                           ),
                           const SizedBox(width: 4),
                           Text(
                             'Detected: ${voiceService.languageDisplayName}',
                             style: TextStyle(
                               fontSize: 12,
                               color: Colors.blue,
                               fontWeight: FontWeight.w500,
                             ),
                           ),
                         ],
                       ),
                     ),
                 ],
               ),
             ),

          // Input field with voice button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                                     decoration: InputDecoration(
                     hintText: 'Ask me anything! Currencies, markets, or just chat... 😊',
                     border: OutlineInputBorder(
                       borderRadius: BorderRadius.circular(25),
                     ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    // Add voice icon inside the text field
                    suffixIcon: IconButton(
                      onPressed:
                          () => _toggleVoiceInput(voiceService, chatService),
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color:
                            _isListening
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      tooltip: 'Voice Input',
                    ),
                  ),
                  onSubmitted: (text) => _sendMessage(text, chatService),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed:
                    () => _sendMessage(_textController.text, chatService),
                icon: Icon(
                  Icons.send,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
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

      // Auto-speak the response if voice input was used
      if (_lastVoiceInput.isNotEmpty && text == _lastVoiceInput) {
        final voiceService = Provider.of<VoiceService>(context, listen: false);
        await voiceService.speakResponse(response);
        _lastVoiceInput = ''; // Reset after speaking
      }
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

  void _editUserMessage(Map<String, dynamic> message) {
    final TextEditingController editController = TextEditingController(text: message['text']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Edit your message:'),
            const SizedBox(height: 16),
            TextField(
              controller: editController,
              decoration: const InputDecoration(
                hintText: 'Type your edited message...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final editedText = editController.text.trim();
              if (editedText.isNotEmpty) {
                // Update the message in the list
                final messageIndex = _messages.indexOf(message);
                if (messageIndex != -1) {
                  setState(() {
                    _messages[messageIndex]['text'] = editedText;
                  });
                  
                  // Remove the AI response that followed this message
                  if (messageIndex + 1 < _messages.length && !_messages[messageIndex + 1]['isUser']) {
                    setState(() {
                      _messages.removeAt(messageIndex + 1);
                    });
                  }
                  
                  // Send the edited message again
                  final chatService = Provider.of<ChatService>(context, listen: false);
                  _sendMessage(editedText, chatService);
                }
              }
              Navigator.pop(context);
            },
            child: const Text('Send'),
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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Advanced settings coming soon!'),
                const SizedBox(height: 16),
                Text(
                  'Features in development:\n• Response style customization\n• Language preferences\n• Detail level control\n• Specialized knowledge areas',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                  ),
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

  Future<void> _toggleVoiceInput(
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
