// voice_service.dart
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  bool _isSpeaking = false;
  String _lastResult = '';
  String _currentLanguage = 'en-US';
  String _detectedLanguage = 'en-US';
  String _languageDisplayName = 'English';

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get lastResult => _lastResult;
  String get detectedLanguage => _detectedLanguage;
  String get languageDisplayName => _languageDisplayName;

  VoiceService() {
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Set up TTS callbacks
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      notifyListeners();
      print("TTS Error: $msg");
    });
  }

  Future<void> initPermissions() async {
    var status = await Permission.microphone.request();

    if (status.isGranted) {
      await _speech.initialize();
    } else {
      print("Microphone permission denied.");
    }
  }

  Future<void> startListening(
    Function(String) onFinalResult,
    Function(String) onPartialResult,
  ) async {
    // Always initialize first
    await _speech.initialize();

    if (!_speech.isAvailable) {
      print("Speech recognition not available.");
      return;
    }

    if (await _speech.hasPermission) {
      _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            // Send partial results to UI
            onPartialResult(result.recognizedWords);

            // Send final result when available
            if (result.finalResult) {
              _lastResult = result.recognizedWords;
              onFinalResult(_lastResult);
              _isListening = false;
              notifyListeners();
            }
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        onSoundLevelChange: (level) {
          // Optional: Add sound level visualization
        },
        localeId: _currentLanguage, // Use detected language
      );
      _isListening = true;
      notifyListeners();
    } else {
      print("Microphone permission not granted.");
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  // Enhanced voice response with language detection
  Future<void> speakResponse(String text, {String? language}) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
    }

    // Detect language from text
    _detectedLanguage = _detectLanguage(text);
    _languageDisplayName = _getLanguageDisplayName(_detectedLanguage);
    notifyListeners();

    try {
      await _flutterTts.setLanguage(_detectedLanguage);
      await _flutterTts.speak(text);
    } catch (e) {
      print("Error speaking text: $e");
      // Fallback to English
      _detectedLanguage = 'en-US';
      _languageDisplayName = 'English';
      notifyListeners();
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.speak(text);
    }
  }

  // Get human-readable language name
  String _getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'hi-IN':
        return 'हिंदी (Hindi)';
      case 'ur-PK':
        return 'اردو (Urdu)';
      case 'es-ES':
        return 'Español (Spanish)';
      case 'fr-FR':
        return 'Français (French)';
      case 'de-DE':
        return 'Deutsch (German)';
      case 'ar-SA':
        return 'العربية (Arabic)';
      case 'en-US':
      default:
        return 'English';
    }
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  // Enhanced language detection with confidence scoring
  String _detectLanguage(String text) {
    final lowerText = text.toLowerCase();
    final words = lowerText.split(' ');
    
    // Language detection patterns with confidence scores
    Map<String, int> languageScores = {
      'hi-IN': 0, // Hindi/Urdu
      'ur-PK': 0, // Urdu (Pakistan)
      'es-ES': 0, // Spanish
      'fr-FR': 0, // French
      'de-DE': 0, // German
      'ar-SA': 0, // Arabic
      'en-US': 0, // English
    };

    // Hindi/Urdu detection patterns
    final hindiPatterns = [
      'है', 'में', 'की', 'का', 'हैं', 'कर', 'से', 'पर', 'को', 'मे',
      'हूं', 'थे', 'था', 'थी', 'रहा', 'रही', 'किया', 'किए', 'करें',
      'करो', 'करेंगे', 'करूंगा', 'करूंगी', 'हो', 'होगा', 'होगी'
    ];
    
    final urduPatterns = [
      'ہے', 'میں', 'کی', 'کا', 'ہیں', 'کر', 'سے', 'پر', 'کو', 'مے',
      'ہوں', 'تھے', 'تھا', 'تھی', 'رہا', 'رہی', 'کیا', 'کئے', 'کریں',
      'کرو', 'کریں گے', 'کروں گا', 'کروں گی', 'ہو', 'ہوگا', 'ہوگی'
    ];

    // Spanish patterns
    final spanishPatterns = [
      'el', 'la', 'es', 'de', 'que', 'y', 'en', 'un', 'se', 'no',
      'te', 'lo', 'le', 'da', 'su', 'por', 'son', 'con', 'para', 'al',
      'del', 'las', 'una', 'como', 'más', 'pero', 'sus', 'me', 'hasta',
      'hay', 'donde', 'han', 'quien', 'están', 'estado', 'desde', 'todo'
    ];

    // French patterns
    final frenchPatterns = [
      'le', 'la', 'de', 'et', 'est', 'que', 'un', 'en', 'du', 'ce',
      'il', 'ne', 'se', 'les', 'des', 'une', 'dans', 'qui', 'par', 'au',
      'sur', 'avec', 'pour', 'pas', 'plus', 'comme', 'tout', 'faire',
      'dire', 'aller', 'voir', 'savoir', 'pouvoir', 'vouloir', 'devoir'
    ];

    // German patterns
    final germanPatterns = [
      'der', 'die', 'das', 'und', 'ist', 'für', 'von', 'mit', 'sich',
      'auf', 'auch', 'als', 'an', 'nach', 'bei', 'seit', 'über', 'unter',
      'zwischen', 'durch', 'gegen', 'ohne', 'um', 'bis', 'entlang',
      'während', 'trotz', 'wegen', 'dank', 'statt', 'außer'
    ];

    // Arabic patterns
    final arabicPatterns = [
      'في', 'من', 'إلى', 'على', 'أن', 'هذا', 'هذه', 'التي', 'الذي',
      'كان', 'ليس', 'ما', 'هو', 'هي', 'نحن', 'أنتم', 'هم', 'هن',
      'عند', 'مع', 'بعد', 'قبل', 'خلال', 'حول', 'داخل', 'خارج'
    ];

    // Score each language based on pattern matches
    for (String word in words) {
      // Hindi scoring
      for (String pattern in hindiPatterns) {
        if (word.contains(pattern)) {
          languageScores['hi-IN'] = (languageScores['hi-IN'] ?? 0) + 2;
        }
      }
      
      // Urdu scoring
      for (String pattern in urduPatterns) {
        if (word.contains(pattern)) {
          languageScores['ur-PK'] = (languageScores['ur-PK'] ?? 0) + 2;
        }
      }
      
      // Spanish scoring
      for (String pattern in spanishPatterns) {
        if (word == pattern) {
          languageScores['es-ES'] = (languageScores['es-ES'] ?? 0) + 1;
        }
      }
      
      // French scoring
      for (String pattern in frenchPatterns) {
        if (word == pattern) {
          languageScores['fr-FR'] = (languageScores['fr-FR'] ?? 0) + 1;
        }
      }
      
      // German scoring
      for (String pattern in germanPatterns) {
        if (word == pattern) {
          languageScores['de-DE'] = (languageScores['de-DE'] ?? 0) + 1;
        }
      }
      
      // Arabic scoring
      for (String pattern in arabicPatterns) {
        if (word.contains(pattern)) {
          languageScores['ar-SA'] = (languageScores['ar-SA'] ?? 0) + 2;
        }
      }
    }

    // Find the language with highest score
    String detectedLanguage = 'en-US'; // Default
    int maxScore = 0;
    
    languageScores.forEach((language, score) {
      if (score > maxScore) {
        maxScore = score;
        detectedLanguage = language;
      }
    });

    // If no clear pattern detected, use English
    if (maxScore < 2) {
      detectedLanguage = 'en-US';
    }

    print('Language Detection: $detectedLanguage (Score: $maxScore)');
    return detectedLanguage;
  }

  // Get available languages for TTS
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return languages.cast<String>();
    } catch (e) {
      print("Error getting languages: $e");
      return ["en-US", "hi-IN", "es-ES", "fr-FR", "de-DE"];
    }
  }

  // Set language for speech recognition
  void setLanguage(String language) {
    _currentLanguage = language;
  }
}
