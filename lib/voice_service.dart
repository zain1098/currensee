// voice_service.dart
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class VoiceService extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastResult = '';

  bool get isListening => _isListening;
  String get lastResult => _lastResult;

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
}